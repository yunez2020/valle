/* se corrige DFECREA para registros ACO */


DROP TABLE IF EXISTS reserva_fecha;
CREATE TABLE reserva_fecha AS SELECT DNORSV,min(DFECREA) AS DFECREA,group_concat(DTARAS) AS c_dtaras,group_concat(DFECREA) AS c_dfecrea,group_concat(DFOLIO) AS c_dfolio FROM opdat WHERE DNORSV>'1800000' AND dfecrea IS NOT NULL GROUP BY DNORSV;

UPDATE opdat_ocupa_aux oa
SET DFECREA=(SELECT DFECREA FROM reserva_fecha rf WHERE rf.DNORSV=oa.DNORSV)
WHERE DNORSV>=1800000 AND DTARAS='ACO';



/* Se lleva dtarifa y descuento a neto */
/*se modifica y se quita el descuento, campo dtarifa ya viene descontado HW2.0*/

UPDATE opdat_ocupa_aux oa
SET 
dtarifa=dtarifa*(1-DAGECOM/100)
WHERE DNORSV>=1800000;





/* y aquí se crea opdat_ocupa y se corrige que no tenía codigo... */
DROP TABLE IF EXISTS opdat_ocupa;
CREATE TABLE opdat_ocupa SELECT * FROM opdat_ocupa_aux WHERE (NOT ISNULL(Esbase)) AND (dnombr NOT LIKE '%Tester%') AND (dnombr NOT LIKE '%PRUEBA%') AND (dnombr NOT LIKE '%Maria Paz Valenzuela%');
UPDATE opdat_ocupa SET dagenc='306' WHERE dagecod IS NOT NULL AND dagenc='IBE' AND demail LIKE '%ctsturismo.cl%';


/* alter table opdat_ocupa drop index id_oo; */
create index id_oo on opdat_ocupa(dnorsv,dfolio);

DELETE FROM opdat_ocupa WHERE dnorsv='1500568';

UPDATE opdat_ocupa SET dmdepo='$' WHERE dnorsv=1403051 or dnorsv=1403789;

update opdat_ocupa
set hotel=IF(locate('H3P',`dhotelibe`),'HTP',`dhotelibe`),
	TipohabRM=(select RM_codigo_habitacion from equivalencia_hotel_habitacion where`dhabibe`=IBE_codigo_habitacion),
	TipohabCRM=`dhabibe`
where DNORSVIBE<>'' AND DHOTELIBE <>'';

/* 50_crear_opcancelaciones */
/* filtra de ophfo las cancelaciones y las pone en opcancelaciones */

drop table if exists opcancelaciones;
create table opcancelaciones
SELECT LFOLIO,LFECHA,LHORA,LQUIEN,LCODIG,LDATOA,LDATOB,LUSER FROM opfho 
WHERE (substr(LCODIG,1,3)='Can') OR (substr(LCODIG,1,3)='Anu');
CREATE INDEX idx_opcancelaciones ON opcancelaciones(lfolio, lfecha);

/* 60_crear_cancelaciones */

DROP TABLE IF EXISTS cancelaciones;
CREATE TABLE cancelaciones (LFOLIO INT, LFECHA VARCHAR(8), LCODIG VARCHAR(300));
INSERT INTO cancelaciones
/* select LFOLIO, MIN(LFECHA), GROUP_CONCAT(LCODIG) FROM OPCANCELACIONES GROUP BY LFOLIO;
se cambia group concat por min 14-02-2014*/
SELECT LFOLIO, MIN(LFECHA), min(LCODIG) FROM opcancelaciones GROUP BY LFOLIO;
CREATE INDEX idx_cancelaciones ON cancelaciones(lfolio);

/* 65_crear_opdat_ocupa_cancela */

DROP TABLE IF EXISTS opdat_ocupa_cancela;
CREATE TABLE opdat_ocupa_cancela 
	SELECT opdat_ocupa.*,LFOLIO AS LFOLIOR, LFECHA AS LFECHAR, LCODIG AS LCODIGR 
	FROM opdat_ocupa LEFT OUTER JOIN cancelaciones 
	ON opdat_ocupa.dnorsv=cancelaciones.LFOLIO;
CREATE INDEX idx_o_o_c ON opdat_ocupa_cancela(dnorsv,dfolio,lfolior, lfechar, dfecrea);

DROP TABLE IF EXISTS opdat_ocupa_cancela_FR;
CREATE TABLE opdat_ocupa_cancela_FR 
	SELECT opdat_ocupa_cancela.*,LFOLIO AS LFOLIOF, LFECHA AS LFECHAF, LCODIG AS LCODIGF
	FROM opdat_ocupa_cancela LEFT OUTER JOIN cancelaciones 
	ON opdat_ocupa_cancela.dfolio=cancelaciones.LFOLIO ;
CREATE INDEX idx_o_o_c_fr ON opdat_ocupa_cancela_FR(dnorsv,dfolio,lfolior,lfoliof,lfechaf, dfecrea);
	
/* 69_create_opdat_fvista_new */


DROP TABLE IF EXISTS opdat_ocupa_fvista;
CREATE TABLE opdat_ocupa_fvista 
SELECT opdat_ocupa_cancela_FR.*,fechas_vista.fecha_vista FROM opdat_ocupa_cancela_FR,fechas_vista 
WHERE fechas_vista.fecha_vista>=opdat_ocupa_cancela_FR.dfecrea AND 
(lfechar IS NULL OR lfechar>fecha_vista OR dcance='N') AND
(lfechaf IS NULL OR lfechaf>fecha_vista OR dcance='N');	
CREATE INDEX idx_oo_fvista ON opdat_ocupa_fvista(dnorsv,dfolio,fecha_vista);

/* 70_limpiar_odat_ocupa_fvista */
/* limpia vistas 2013 de temporada 2012 y vistas posteriores a 20130420 */
	
/*
delete from opdat_ocupa_fvista 
where substr(dflleg,1,4)='2012' and substr(fecha_vista,1,4)='2013';
*/

/* Aqui esta la fecha que hay que cambiar */

DELETE FROM opdat_ocupa_fvista WHERE fecha_vista>'20230916';	

/* 72_create_reserva_vista_adicional */
/* agrego por reserva y fecha de vista los folios con esbase = 0 */

DROP TABLE IF EXISTS reserva_vista_adicional;
CREATE TABLE reserva_vista_adicional (dnorsv INT, fecha_vista VARCHAR(8), dadult INT, dninos INT,dinfantes INT,dteen INT, dtarifa FLOAT);
INSERT INTO reserva_vista_adicional
SELECT dnorsv,fecha_vista, sum(dadult),sum(dninos),sum(dinfantes), sum(dteen), (sum(dtarifa)) 
FROM opdat_ocupa_fvista WHERE esbase=0 GROUP BY dnorsv,fecha_vista;
CREATE INDEX idx_reserva_vista_adicional ON reserva_vista_adicional(dnorsv,fecha_vista);

/* 74_create_reserva_folio_vista */
/* agrego por reserva, folio y fecha de vista para esbase = 1 */
/* queda un registro para cada habitacion de una reserva en cada fecha de vista
    y despues a cada registro le vamos a sumar lucas y pasajeros adicionales */ 

DROP TABLE IF EXISTS reserva_folio_vista;
CREATE TABLE reserva_folio_vista 
	(dnorsv INT, 
	dfolio INT, 
	fecha_vista VARCHAR(8),
	Nivel VARCHAR(30), 
	hotel VARCHAR(30),
	TipoHabRM VARCHAR(30),
	TipoHabCRM VARCHAR(30),
	DFLLEG VARCHAR(8),
	DFSALI VARCHAR(8),
	DCANCE VARCHAR(1),
	descuento FLOAT,
	dagecom FLOAT,
	dnpais VARCHAR(20),
	dnacio VARCHAR(3),
	esbase INT, 
	dadult INT, 
	dninos INT,
	dinfantes INT,
	dteen INT, 
	dtarifa FLOAT,
	dagenc VARCHAR(400),
    DMOTIV VARCHAR(400),
    DTAPOR VARCHAR(20),
	sdocupa VARCHAR(400),
	early INT,
	directo INT,
	itau INT,
	mastercard INT,
	ibe INT,
	hab INT,
	complementary INT,
	nacionalidad_gestion VARCHAR(5),
	dtaras VARCHAR(100),
	dmdepo VARCHAR(100));
INSERT INTO reserva_folio_vista
	SELECT dnorsv,
			dfolio,
			fecha_vista, 
			min(Nivel),
			min(hotel),
			min(TipoHabRM),
			min(TipoHabCRM), 
			min(DFLLEG),min(DFSALI),min(DCANCE), 
			AVG(descuento), 
			AVG(dagecom),
			min(dnpais),
			min(dnacio),
			sum(esbase),
			sum(dadult),
			sum(dninos),
			sum(dinfantes), 
			sum(dteen), 
			(sum(dtarifa)),
			group_concat(dagenc), 
            group_concat(DMOTIV),
            group_concat(DTAPOR),
			group_concat(docupa),
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			'nada',
			group_concat(dtaras),
			group_concat(dmdepo)
FROM opdat_ocupa_fvista WHERE esbase=1 GROUP BY dnorsv,dfolio,fecha_vista;
create index idx_reserva_folio_vista on reserva_folio_vista(dnorsv,fecha_vista,DFLLEG,dfolio);


/* 75_create_reserva_fvista_hab */
/* calcula numero de habitaciones para una reserva y lo agrega a la tabla reserva_folio_vista */
/*cambiaron los codigos de earlybooking y mastercard */

drop table if exists reserva_fvista_hab;
create table reserva_fvista_hab (dnorsv int, fecha_vista varchar(8), hab int);
insert into reserva_fvista_hab
	select dnorsv,fecha_vista,sum(esbase) from reserva_folio_vista group by dnorsv,fecha_vista;
create index idx_reserva_fvista_hab on reserva_fvista_hab(dnorsv,fecha_vista); 

/* algunos codigos de early booking cambiaron en estos años

update reserva_folio_vista
	set hab= (select hab from reserva_fvista_hab 
				where reserva_folio_vista.dnorsv = reserva_fvista_hab.dnorsv and 
						reserva_folio_vista.fecha_vista = reserva_fvista_hab.fecha_vista),
		early= (locate('A63',dmotiv) OR locate('A39',dmotiv)),
		directo=(locate('DIR',dagenc) OR locate('COORD',dagenc) OR locate('888',dagenc)),
		itau= (locate('A15',dmotiv) OR locate('A16',dmotiv) OR locate('A40',dmotiv)OR locate('A41',dmotiv)),
		ibe= locate('888',dagenc),
		complementary = (locate('650',dagenc) OR locate('651',dagenc) OR locate('652',dagenc) OR locate('653',dagenc) OR locate('654',dagenc) OR locate('655',dagenc))
        where DFLLEG<'20130101';

update reserva_folio_vista
	set hab= (select hab from reserva_fvista_hab 
				where reserva_folio_vista.dnorsv = reserva_fvista_hab.dnorsv and 
						reserva_folio_vista.fecha_vista = reserva_fvista_hab.fecha_vista),
		early= (locate('A62',dmotiv) OR locate('A63',dmotiv)),
		directo=(locate('DIR',dagenc) OR locate('COORD',dagenc) OR locate('888',dagenc)),
		itau= (locate('A15',sdocupa) OR locate('A16',sdocupa) OR locate('A40',sdocupa)OR locate('A41',sdocupa)),
		mastercard = locate('M88',dmotiv) OR locate('A64', dmotiv),
		ibe= locate('888',dagenc),
		complementary = (locate('650',dagenc) OR locate('651',dagenc) OR locate('652',dagenc) OR locate('653',dagenc) OR locate('654',dagenc) OR locate('655',dagenc))
where DFLLEG>='20130101' and DFLLEG<'20170101';
*/

update reserva_folio_vista
	set hab= (select hab from reserva_fvista_hab 
				where reserva_folio_vista.dnorsv = reserva_fvista_hab.dnorsv and 
						reserva_folio_vista.fecha_vista = reserva_fvista_hab.fecha_vista),
		early= (locate('A62',sdocupa) OR locate('A63',sdocupa)),
		directo=(locate('DIR',dagenc) OR locate('COORD',dagenc) OR locate('888',dagenc)),
		mastercard = locate('M88',dmotiv) OR locate('A64', dmotiv),
		ibe= locate('888',dagenc),
		complementary = (locate('650',dagenc) OR locate('651',dagenc) OR locate('652',dagenc) OR locate('653',dagenc) OR locate('654',dagenc) OR locate('655',dagenc))
where DFLLEG>='20170101';

/*
UPDATE reserva_folio_vista
	SET nacionalidad_gestion = IF((locate('712',dagenc) OR locate('780',dagenc) OR locate('600',dagenc)),'SKT',
									IF((locate('BRA',dnacio) OR locate('BR',dnacio)),'BRA',IF((locate('USA',dnacio) OR locate('US',dnacio)),'USA',IF((locate('CHI',dnacio) OR locate('CL',dnacio)),'CHI',IF((locate('ARG',dnacio) OR locate('AR',dnacio)),'ARG','OTROS')))));
se cambia locate por strcmp porque en realidad no hay agrupacion*/

UPDATE reserva_folio_vista
	SET nacionalidad_gestion = IF((locate('712',dagenc) OR locate('780',dagenc) OR locate('600',dagenc)),'SKT',
									IF((locate('BRA',dnacio) OR strcmp('BR',dnacio)=0),'BRA',IF((locate('USA',dnacio) OR strcmp('US',dnacio)=0),'USA',IF((locate('CHI',dnacio) OR strcmp('CL',dnacio)=0 OR locate('CHL',dnacio)),'CHI',IF((locate('ARG',dnacio) OR strcmp('AR',dnacio)=0),'ARG','OTROS')))));



/*
SELECT nacionalidad_gestion,dagenc, dnacio, count(*) FROM reserva_folio_vista  WHERE locate('713',dagenc) OR locate ('780',`dagenc`) OR locate ('ARG',dnacio) OR LOCATE('AR',dnacio) OR LOCATE('BRA',dnacio) OR LOCATE('BR',dnacio) OR LOCATE('USA',dnacio) OR LOCATE('US',dnacio) OR LOCATE('CHI',dnacio) OR LOCATE('CL',dnacio)  GROUP BY nacionalidad_gestion,dagenc, dnacio;

*/


/* 76_create_reserva_folio_vista_adic */
/* aqui se junta lo base con lo adicional */

drop table if exists reserva_folio_vista_adic;
create table reserva_folio_vista_adic like reserva_folio_vista;
alter table reserva_folio_vista_adic
	add column dadult_adic float,
	add column dninos_adic float,
	add column dinfantes_adic float,
	add column dteen_adic float,
	add column dtarifa_adic float;
INSERT INTO reserva_folio_vista_adic
	SELECT reserva_folio_vista.*,
		if(reserva_vista_adicional.dadult,reserva_vista_adicional.dadult/reserva_folio_vista.hab,0),
		if(reserva_vista_adicional.dninos,reserva_vista_adicional.dninos/reserva_folio_vista.hab,0),
		if(reserva_vista_adicional.dinfantes,reserva_vista_adicional.dinfantes/reserva_folio_vista.hab,0),
		if(reserva_vista_adicional.dteen,reserva_vista_adicional.dteen/reserva_folio_vista.hab,0),
		if(reserva_vista_adicional.dtarifa,reserva_vista_adicional.dtarifa/reserva_folio_vista.hab,0) 
	FROM reserva_folio_vista LEFT OUTER JOIN reserva_vista_adicional
	ON (reserva_folio_vista.dnorsv=reserva_vista_adicional.dnorsv AND 
			reserva_folio_vista.fecha_vista=reserva_vista_adicional.fecha_vista);
create index idx_reserva_folio_vista_adic on reserva_folio_vista_adic(dnorsv,fecha_vista,dfolio);



/* 82_expandir_fechas.sql */

DROP TABLE if exists reserva_folio_vista_uso;
CREATE TABLE reserva_folio_vista_uso 
SELECT reserva_folio_vista_adic.*,agno2012.fecha as fecha_uso
from reserva_folio_vista_adic,agno2012 
where agno2012.fecha>=DFLLEG AND agno2012.fecha<DFSALI;
create index idx_folio_vista_uso on reserva_folio_vista_uso(dnorsv,dfolio,fecha_vista,fecha_uso);
create index idx_reserva_folio_vista_uso on reserva_folio_vista_uso(fecha_uso);
/* se agrega segundo indice en fecha uso 28-04-2014 */



/* 85_update_por_dia_y_dolar */


alter table reserva_folio_vista_uso
	add column dolar_updated int;

update reserva_folio_vista_uso
set dtarifa=dtarifa/(datediff(dfsali,dflleg)),
	dtarifa_adic=dtarifa_adic/(datediff(dfsali,dflleg));

/* esta era la version antigua 
update reserva_folio_vista_uso
set dtarifa=(dtarifa/475.0)/1.19,
	dtarifa_adic=(dtarifa_adic/475.0)/1.19,
	dolar_updated=1
where dmdepo='$' OR (dtarifa>14000 and dnacio='CHI') OR (dtarifa_adic>14000 and dnacio='CHI');
*/

/* esta es la nueva 2016-01-29 */
update reserva_folio_vista_uso
set dtarifa=(dtarifa/475.0)/1.19,
	dtarifa_adic=(dtarifa_adic/475.0)/1.19,
	dolar_updated=1
where dmdepo='$' OR (dtarifa>14000 and nacionalidad_gestion='CHI') OR (dtarifa_adic>14000 and nacionalidad_gestion='CHI') OR (dtarifa>100000) or (dtarifa_adic>100000);



/* para el 2014 uso dolar 550 */

update reserva_folio_vista_uso
set dtarifa=(dtarifa*475.0/550.0),
	dtarifa_adic=(dtarifa_adic*475.0/550.0)
where dolar_updated=1 and substring(dflleg,1,4)='2014';


/* para el 2015 uso dolar 600 */

update reserva_folio_vista_uso
set dtarifa=(dtarifa*475.0/600.0),
	dtarifa_adic=(dtarifa_adic*475.0/600.0)
where dolar_updated=1 and substring(dflleg,1,4)='2015';

/* para el 2016 uso dolar 710 */

update reserva_folio_vista_uso
set dtarifa=(dtarifa*475.0/710.0),
	dtarifa_adic=(dtarifa_adic*475.0/710.0)
where dolar_updated=1 and substring(dflleg,1,4)='2016';


/* para el 2017 uso dolar 660 */

update reserva_folio_vista_uso
set dtarifa=(dtarifa*475.0/660.0),
	dtarifa_adic=(dtarifa_adic*475.0/660.0)
where dolar_updated=1 and substring(dflleg,1,4)='2017';


/* para el 2018 uso dolar 600 */

update reserva_folio_vista_uso
set dtarifa=(dtarifa*475.0/600.0),
	dtarifa_adic=(dtarifa_adic*475.0/600.0)
where dolar_updated=1 and substring(dflleg,1,4)='2018';


/* para el 2019 uso dolar 670 */

update reserva_folio_vista_uso
set dtarifa=(dtarifa*475.0/670.0),
	dtarifa_adic=(dtarifa_adic*475.0/670.0)
where dolar_updated=1 and substring(dflleg,1,4)='2019';

/* para el 2021 uso dolar 720 */

update reserva_folio_vista_uso
set dtarifa=(dtarifa*475.0/720.0),
	dtarifa_adic=(dtarifa_adic*475.0/720.0)
where dolar_updated=1 and substring(dflleg,1,4)='2021';

/* para el 2022 uso dolar 800 */
update reserva_folio_vista_uso
set dtarifa=(dtarifa*475.0/800.0),
	dtarifa_adic=(dtarifa_adic*475.0/800.0)
where dolar_updated=1 and substring(dflleg,1,4)='2022';

/* para el 2023 uso dolar 850 */
update reserva_folio_vista_uso
set dtarifa=(dtarifa*475.0/800.0),
	dtarifa_adic=(dtarifa_adic*475.0/850.0)
where dolar_updated=1 and substring(dflleg,1,4)='2023';

/*102 y 104 crean semanas y paises; las omito porque copio tablas*/

/* 106_create_final_semanas.sql */
/* completo tabla con semana de temporada y dia de la semana */

drop table if exists final_semanas;
create table final_semanas
select reserva_folio_vista_uso.*,semanas.agno,semanas.dia_semana,semanas.semana_temp from reserva_folio_vista_uso left join valle_diccionario.semanas semanas on reserva_folio_vista_uso.fecha_uso = semanas.fecha_uso;

/* 108_create_final_final_last */
/* 6 de Julio, se agrega campo dagenc */
/* se agrega también habitaciones_noche, que para cada reserva_folio cuenta cuántas noches de una semana estuvo ocupada */

drop table if exists final_final;
create table final_final
select dnorsv,dfolio,fecha_vista,agno, semana_temp,sum(dtarifa)+sum(dtarifa_adic) as ingreso_neto,sum(dadult)+sum(dadult_adic) as dadult,
sum(dninos)+sum(dninos_adic) as dninos,sum(dteen)+sum(dteen_adic) as dteen,sum(dinfantes)+sum(dinfantes_adic) as dinfantes,
sum(dadult)+sum(dadult_adic) + sum(dninos)+sum(dninos_adic) + sum(dteen)+sum(dteen_adic) as noches_cama,
max(dnacio) as dnacio,max(hotel) as hotel, max(tipohabrm) as tipohabrm,max(nivel) as nivel,max(dtaras) as dtaras,max(ibe) as ibe,
max(itau) as itau, max(mastercard) as mastercard, max(directo) as directo, max(early) as early,max(dcance) as dcance, min(fecha_uso) as fecha_uso, max(dagenc) as dagenc, max(dmotiv) as dmotiv, max(dtapor) as dtapor, count(*) as habitaciones_noches, min(nacionalidad_gestion) as nacionalidad_gestion, max(complementary) as complementary from final_semanas group by dnorsv,dfolio,fecha_vista,agno,semana_temp;

/*
drop table if exists final_final_last;
create table final_final_last
select *,floor(datediff(fecha_vista,fecha_uso)/7) as anticipacion from final_final;
*/

drop table if exists final_final_last;
create table final_final_last
select *,ceiling(datediff(fecha_vista,fecha_uso)/7) as anticipacion from final_final;



/*
drop table if exists final_final_last;
create table final_final_last
select f.*,(g.semana_vista - f.semana_temp) as anticipacion from final_final left join 
*/

/* agregado a pedido LEM, 16 de Agosto 2014 */
update final_final_last set nivel='N0' where early=1;


/* aqui viene lo de Luis */


/* Importa y limpia final_final_last. Esto puede que sea redundante ahora que Alvaro lo corrigio */


DELETE FROM final_final_last WHERE complementary<>0;


UPDATE final_final_last
SET nacionalidad_gestion='OTH' WHERE nacionalidad_gestion='OTROS';

UPDATE final_final_last
SET tipohabrm='Double' WHERE (tipohabrm='Cuadruple' OR tipohabrm='Triple') AND hotel='HTP';

UPDATE final_final_last
SET tipohabrm='DoubleSouth' WHERE tipohabrm='Double' AND hotel='HPS';

UPDATE final_final_last
SET tipohabrm='DblDblSouth' WHERE tipohabrm='Cuadruple' AND hotel='HPS';

UPDATE final_final_last
SET nivel='N0' WHERE early='1';

CREATE INDEX idx_final ON final_final_last(fecha_vista, semana_temp, hotel, tipohabrm,nacionalidad_gestion, nivel);


/* a partir de aqui, nuevo 2018 */


/* A partir de final_semanas se genera un final_final_last_diario alternativo
al que se le aplican los mismos filtros y ajustes que a final_final_last */ 


drop table if exists final_final_diario;
create table final_final_diario
select dnorsv,dfolio,fecha_vista,agno, semana_temp, fecha_uso, sum(dtarifa)+sum(dtarifa_adic) as ingreso_neto,sum(dadult)+sum(dadult_adic) as dadult,
sum(dninos)+sum(dninos_adic) as dninos,sum(dteen)+sum(dteen_adic) as dteen,sum(dinfantes)+sum(dinfantes_adic) as dinfantes,
sum(dadult)+sum(dadult_adic) + sum(dninos)+sum(dninos_adic) + sum(dteen)+sum(dteen_adic) as noches_cama,
max(dnacio) as dnacio,max(hotel) as hotel, max(tipohabrm) as tipohabrm,max(nivel) as nivel,max(dtaras) as dtaras,max(ibe) as ibe,
max(itau) as itau, max(mastercard) as mastercard, max(directo) as directo, max(early) as early,max(dcance) as dcance, max(dagenc) as dagenc, max(dmotiv) as dmotiv, max(dtapor) as dtapor, count(*) as habitaciones_noches, min(nacionalidad_gestion) as nacionalidad_gestion, max(complementary) as complementary from final_semanas group by dnorsv,dfolio,fecha_vista,agno,semana_temp, fecha_uso;


drop table if exists final_final_last_diario;
create table final_final_last_diario
select *,ceiling(datediff(fecha_vista,fecha_uso)/7) as anticipacion from final_final_diario;


/* se replican los filtros de final_final_last agregado a pedido LEM, 16 de Agosto 2014 */

update final_final_last_diario set nivel='N0' where early=1;


DELETE FROM final_final_last_diario WHERE complementary<>0;


UPDATE final_final_last_diario
SET nacionalidad_gestion='OTH' WHERE nacionalidad_gestion='OTROS';

UPDATE final_final_last_diario
SET tipohabrm='Double' WHERE (tipohabrm='Cuadruple' OR tipohabrm='Triple') AND hotel='HTP';

UPDATE final_final_last_diario
SET tipohabrm='DoubleSouth' WHERE tipohabrm='Double' AND hotel='HPS';

UPDATE final_final_last_diario
SET tipohabrm='DblDblSouth' WHERE tipohabrm='Cuadruple' AND hotel='HPS';

UPDATE final_final_last_diario
SET nivel='N0' WHERE early='1';

delete from final_final_last_diario where agno>2023;


CREATE INDEX idx_final ON final_final_last_diario(fecha_vista, semana_temp, hotel, tipohabrm,nacionalidad_gestion, nivel, fecha_uso);
CREATE INDEX idx_agenc ON final_final_last_diario(dagenc);
CREATE INDEX idx_dmotiv ON final_final_last_diario (dmotiv);
CREATE INDEX idx_dtapor ON final_final_last_diario (dtapor);
CREATE INDEX idx_pos ON final_final_last_diario(dnacio);
CREATE INDEX idx_tarifa ON final_final_last_diario(dtaras);
CREATE INDEX idx_hotel ON final_final_last_diario(hotel);
CREATE INDEX idx_habitacion ON final_final_last_diario(tipohabrm);


