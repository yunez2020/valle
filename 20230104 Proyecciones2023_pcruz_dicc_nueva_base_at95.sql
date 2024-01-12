
/* Limpia final_final_last. Esto puede que sea redundante ahora que Alvaro lo corrigio */

update final_final_last
set nacionalidad_gestion='OTH' where nacionalidad_gestion='OTROS';

update final_final_last
set tipohabrm='Double' where (tipohabrm='Cuadruple' or tipohabrm='Triple') and hotel='HTP';

update final_final_last
set tipohabrm='DoubleSouth' where tipohabrm='Double' and hotel='HPS';

update final_final_last
set tipohabrm='DblDblSouth' where tipohabrm='Cuadruple' and hotel='HPS';

update final_final_last
set nivel='N0' where early='1';

delete from final_final_last where agno>2023;

create index idx_final_1 on final_final_last(fecha_vista, semana_temp, hotel, tipohabrm,nacionalidad_gestion, nivel);

/* se establece la maxima fecha de vista con datos del anho actual */

set @fecha_ultima_vista:= (select max(fecha_vista) from final_final_last);

/*Se hace forecast un proceso para autollenar reservas que tengan ingreso menor a US$50 que se asumen errores */




drop table if exists aux0;

create table aux0
select sum(ingreso_neto)/NULLIF(sum(noches_cama),0) as ing_medio, fecha_vista, semana_temp, hotel, tipohabrm, nacionalidad_gestion, nivel 
from final_final_last
where ingreso_neto>50
group by fecha_vista, semana_temp, hotel, tipohabrm,nacionalidad_gestion, nivel;



create index idx_aux0 on aux0(fecha_vista, semana_temp, hotel, tipohabrm,nacionalidad_gestion, nivel);


update final_final_last
set ingreso_neto=noches_cama*(select ing_medio from aux0
where final_final_last.fecha_vista=aux0.fecha_vista and
final_final_last.semana_temp=aux0.semana_temp and
final_final_last.hotel=aux0.hotel and
final_final_last.tipohabrm=aux0.tipohabrm and
final_final_last.nacionalidad_gestion=aux0.nacionalidad_gestion and
final_final_last.nivel=aux0.nivel)
where ingreso_neto <=50;

/* fin de autollenado */

/* crea la tabla ppto_nc que es un agregado sin nivel del presupuesto */

drop table if exists ppto_nc;
create table ppto_nc
select hotel, semana_temp as semana, pos, tipohabrm, sum(ppto_nc) as ppto_nc, sum(ppto_ingreso) as ppto_ing
from valle_diccionario.presupuesto
group by hotel, semana_temp, pos, tipohabrm;
 
/* Crea las tablas base en que agrega los ingresos y noches cama de final_final_last
por fecha vista, hotel, tipohabitacion, POS y semana temporada */

drop table if exists base0;

CREATE TABLE base0 (
  agno int(11) DEFAULT '0',
  anticipacion decimal(7,0) DEFAULT NULL,
  semana_temp int(11) DEFAULT '0',
  fecha_vista varchar(8) DEFAULT NULL,
  tipohabrm varchar(30) DEFAULT NULL,
  hotel varchar(30) DEFAULT NULL,
  pos varchar(3) DEFAULT NULL,
  ingreso_neto double DEFAULT NULL,
  noches_cama double DEFAULT NULL,
  habitaciones_noche double DEFAULT NULL,
pct_deberia float Default 0,
nc_pe int DEfault 0,
hn_pe int default 0,
nc_out_unc int Default 0,
hn_out_unc int default 0
);


/*selecciona solo los registros relevantes para la proyeccion de hoteles en la temporada actual */

insert into base0 (agno,anticipacion, semana_temp, fecha_vista, tipohabrm, hotel, pos, ingreso_neto, noches_cama, habitaciones_noche) 
select agno,anticipacion, semana_temp, fecha_vista, tipohabrm, hotel, nacionalidad_gestion, sum(ingreso_neto), sum(noches_cama), sum(habitaciones_noches) from final_final_last 
where semana_temp>0 and semana_temp<=15 and anticipacion>=-45 and anticipacion<=15 and hotel in('HPS','HTP','HVN') and complementary=0 and substring(fecha_uso,1,4)=2023
group by agno,anticipacion,semana_temp,fecha_vista,tipohabrm,hotel,nacionalidad_gestion;




drop table if exists base;
create table base like base0;
insert into base (agno,anticipacion, semana_temp, fecha_vista, tipohabrm, hotel, pos, ingreso_neto, noches_cama, habitaciones_noche) 
   select agno,anticipacion, semana_temp, fecha_vista, tipohabrm, hotel, pos, sum(ingreso_neto), sum(noches_cama), sum(habitaciones_noche) from base0 group by agno,anticipacion,semana_temp,fecha_vista,tipohabrm,hotel,pos;
create index idx_base on base(pos,semana_temp,hotel,tipohabrm);

DROP TABLE IF EXISTS base_cruz;
CREATE TABLE base_cruz 
SELECT p.*, b.ingreso_neto,b.noches_cama,b.habitaciones_noche,b.pct_deberia,b.nc_pe, b.hn_pe, b.nc_out_unc, b.hn_out_unc 
FROM valle_diccionario.producto_cruz p 
LEFT JOIN base b ON (p.agno=b.agno AND p.anticipacion=b.anticipacion AND p.semana_temp=b.semana_temp AND p.fecha_vista=b.fecha_vista AND p.tipohabrm=b.tipohabrm AND p.hotel=b.hotel AND p.pos = b.pos);
CREATE INDEX idx_base_cruz ON base_cruz(pos,semana_temp,hotel,tipohabrm);

UPDATE base_cruz SET ingreso_neto=0,noches_cama=0,habitaciones_noche=0,pct_deberia=0,nc_pe=0, nc_out_unc=0 WHERE ingreso_neto IS NULL;

delete from base_cruz where fecha_vista > @fecha_ultima_vista; 

/* se agrega campo pct_deberia desde la curva de entrada que se obtiene de la curva del año anterior
Ademas, se agrega un cruce con la tabla de parametros que tiene un factor de ajuste de anticipacion en caso 
que se crea que en la temporada actual va a ser mas rapido o mas lento el ingreso de reservas del agno anterior. Es un factor aditivo.
*/

update base_cruz
  set pct_deberia= if(base_cruz.anticipacion<=0,least((select esperado from valle_diccionario.curva_entrada 
where 	valle_diccionario.curva_entrada.anticipacion = base_cruz.anticipacion and 
		valle_diccionario.curva_entrada.semana_temp = base_cruz.semana_temp) + 
	(select factor_ajuste_anticipacion from valle_diccionario.parametros
where valle_diccionario.parametros.fecha_vista=base_cruz.fecha_vista),1),1);  



update base_cruz
  set nc_pe= if(base_cruz.anticipacion<=1,(select nc_pe from valle_diccionario.base_proyeccion 
where 	valle_diccionario.base_proyeccion.pos = base_cruz.pos and
		valle_diccionario.base_proyeccion.hotel = base_cruz.hotel and 
		valle_diccionario.base_proyeccion.tipohabrm = base_cruz.tipohabrm and 
        valle_diccionario.base_proyeccion.semana_temp = base_cruz.semana_temp and
        valle_diccionario.base_proyeccion.anticipacion = base_cruz.anticipacion) * (1- 
	(select factor_ajuste_anticipacion from valle_diccionario.parametros
where valle_diccionario.parametros.fecha_vista=base_cruz.fecha_vista)),0);  

update base_cruz
  set hn_pe= if(base_cruz.anticipacion<=1,(select hn_pe from valle_diccionario.base_proyeccion 
where 	valle_diccionario.base_proyeccion.pos = base_cruz.pos and
		valle_diccionario.base_proyeccion.hotel = base_cruz.hotel and 
		valle_diccionario.base_proyeccion.tipohabrm = base_cruz.tipohabrm and 
        valle_diccionario.base_proyeccion.semana_temp = base_cruz.semana_temp and
        valle_diccionario.base_proyeccion.anticipacion = base_cruz.anticipacion) * (1- 
	(select factor_ajuste_anticipacion from valle_diccionario.parametros
where valle_diccionario.parametros.fecha_vista=base_cruz.fecha_vista)),0);  


/* se agrega presupuesto de noches_cama en campo nc */
drop table if exists base1;
create table base1 
select base_cruz.*, ppto_nc.ppto_nc from base_cruz left outer join ppto_nc on base_cruz.pos=ppto_nc.pos and base_cruz.semana_temp=ppto_nc.semana and base_cruz.hotel=ppto_nc.hotel and base_cruz.tipohabrm=ppto_nc.tipohabrm;
create index idx_base1 on base1(pos,semana_temp,hotel,tipohabrm);

/* se calcula proyección de noches cama unconstrained como lo actual más porcentaje que falta por entrar sobre presupuesto */
update base1
 set nc_out_unc= if(anticipacion<-32,ppto_nc, if(anticipacion>0, noches_cama, greatest(noches_cama + nc_pe, 0)));

update base1
 set hn_out_unc= if(anticipacion<-32,floor(ppto_nc/2), if(anticipacion>0, habitaciones_noche, greatest(habitaciones_noche + hn_pe, 0)));



/* nuevo proceso de constrained */

/*1 calculo de factor constrained por semana y fecha de vista*/
drop table if exists constrainer;
create table constrainer
select base1.fecha_vista, base1.semana_temp, sum(noches_cama), sum(nc_out_unc), if(sum(nc_out_unc)>max_fo*max_cap_sem,(max_fo*max_cap_sem)/sum(nc_out_unc),1) as coef_const from base1 left outer join valle_diccionario.parametros p on base1.fecha_vista=p.fecha_vista
group by base1.fecha_vista, semana_temp;



/*2 actualizar base1 con la proyeccion constrained*/

drop table if exists base2;
create table base2
select base1.*, greatest(base1.noches_cama,constrainer.coef_const*nc_out_unc) as nc_out_const, greatest(base1.habitaciones_noche,constrainer.coef_const*hn_out_unc) as hn_out_const from base1 left outer join constrainer on base1.fecha_vista=constrainer.fecha_vista and base1.semana_temp=constrainer.semana_temp;

create index idx_base2 on base2(semana_temp, fecha_vista, hotel, tipohabrm);

/*3 calcular BPs AUs por fecha vista hotel tipo hab semana y agregarle Proy CONST y NC TOT
Proy CONST y NC TOT son las noches cama proyectada constrained y las actuales por tipo habitacion semana
es decir, sumada para todos los POS */

drop table if exists bps;
create table bps
select s.*,capacidad_semanal*stock as bp from valle_diccionario.stock s left outer join valle_diccionario.capacidad c on s.hotel=c.hotel and s.tipohab=c.tipohabrm;


drop table if exists aus;
create table aus
select *, bp0 as au0, bp0+bp1 as au1,bp0+bp1+bp2 as au2,bp0+bp1+bp2+bp3 as au3
from (
select semana, Hotel, TipoHab,
	sum(if(Nivel='N0',bp,0)) as bp0, 
	sum(if(Nivel='N1',bp,0)) as bp1,
	sum(if(Nivel='N2',bp,0)) as bp2,
	sum(if(Nivel='N3',bp,0)) as bp3
from bps
group by semana, Hotel, TipoHab) as s;

/*4 calcular factores por nivel y spill*/

drop table if exists pe_coef;
create table pe_coef
select *,  
	if(pe_tot=0,0,greatest(least(bp0,au0-nc_tot,proy_const_tot,pe_tot),0)/pe_tot) as coef0,
	if(pe_tot=0,0,greatest(least(bp1,au1-nc_tot,proy_const_tot-au0,pe_tot),0)/pe_tot) as coef1,	
	if(pe_tot=0,0,greatest(least(bp2,au2-nc_tot,proy_const_tot-au1,pe_tot),0)/pe_tot) as coef2,	
	if(pe_tot=0,0,greatest(least(bp3,au3-nc_tot,proy_const_tot-au2,pe_tot),0)/pe_tot) as coef3,
	if(pe_tot=0,0,greatest(least(proy_const_tot-au3,pe_tot),0)/pe_tot) as coef_spill
from (
select aus.*, base2.fecha_vista, 
	sum(base2.noches_cama) as nc_tot, 
	sum(base2.nc_out_const) as proy_const_tot,
	sum(base2.nc_out_const)-sum(base2.noches_cama) as pe_tot
from aus left outer join base2
on aus.semana=base2.semana_temp and aus.hotel=base2.hotel and aus.TipoHab=base2.tipohabrm
group by base2.fecha_vista, aus.semana, aus.hotel, aus.TipoHab) as s
; 

create index idx_pe_coef on pe_coef(semana, fecha_vista, Hotel, TipoHab);

/*5 asigna noches_cama por entrar a los niveles y al spill*/

drop table if exists base3;
create table base3
select 	base2.*, 
		if(pos='SKT',0,(nc_out_const-noches_cama)*coef0) as peN0,
		if(pos='SKT',0,(nc_out_const-noches_cama)*coef1) as peN1,
		if(pos='SKT',0,(nc_out_const-noches_cama)*coef2) as peN2,
		if(pos='SKT',0,(nc_out_const-noches_cama)*coef3) as peN3,
		if(pos='SKT',0,(nc_out_const-noches_cama)*coef_spill) as peSP,
        if(pos='SKT',(nc_out_const-noches_cama),0) as peST,
        if(pos='SKT',0,(hn_out_const-habitaciones_noche)*coef0) as peN0_hn,
		if(pos='SKT',0,(hn_out_const-habitaciones_noche)*coef1) as peN1_hn,
		if(pos='SKT',0,(hn_out_const-habitaciones_noche)*coef2) as peN2_hn,
		if(pos='SKT',0,(hn_out_const-habitaciones_noche)*coef3) as peN3_hn,
		if(pos='SKT',0,(hn_out_const-habitaciones_noche)*coef_spill) as peSP_hn,
        if(pos='SKT',(hn_out_const-habitaciones_noche),0) as peST_hn,
        1 as tipo_proyeccion
from base2 left outer join pe_coef on 
base2.semana_temp=pe_coef.semana and 
base2.fecha_vista=pe_coef.fecha_vista and
base2.hotel=pe_coef.Hotel and
base2.tipohabrm=pe_coef.TipoHab;

/* tipo de proyeccion es 1 si es aditiva o 0 si se impone el presupuesto */
/*obtiene los precios del presupuesto o de las tarifas base*/

drop table if exists fcst_fare0;
create table fcst_fare0
select p.*, if(p.ppto_ingreso=0 or p.ppto_nc=0, t.tarifa, p.ppto_ingreso/p.ppto_nc) as Precio 
from valle_diccionario.presupuesto p left outer join valle_diccionario.tarifas_base t
on 	t.Semana_temp=p.semana_temp
and	t.TipoHabRM=p.tipohabrm
and	t.Hotel=p.hotel
and	t.Nivel=p.nivel;

/*traspone las tarifas por nivel */

drop table if exists fcst_fare;
create table fcst_fare
select semana_temp, hotel, tipohabrm, pos,
	sum(if(Nivel='N0',Precio,0)) as prN0, 
	sum(if(Nivel='N1',Precio,0)) as prN1,
	sum(if(Nivel='N2',Precio,0)) as prN2,
	sum(if(Nivel='N3',Precio,0)) as prN3,
	sum(if(Nivel='ST',Precio,0)) as prST
from fcst_fare0
group by semana_temp, hotel, tipohabrm,pos;

/*le agrega las tarifas por entrar por nivel a la tabla base */

drop table if exists base4;
create table base4
select base3.*, fcst_fare.prN0, fcst_fare.prN1, fcst_fare.prN2, fcst_fare.prN3, fcst_fare.prST from base3 left join fcst_fare 
on 		base3.semana_temp=fcst_fare.semana_temp
and		base3.hotel=fcst_fare.hotel
and		base3.tipohabrm=fcst_fare.tipohabrm
and		base3.pos=fcst_fare.pos;


/* se obtiene la proyeccion como columnas y se crea un campo para saber de que nivel de precios seria el spill*/
drop table if exists base9;
create table base9
select base4.*, if(peN3>0,prN3,if(peN2>0,prN2,prN1)) as prSP,if(peN3>0,'N3',if(peN2>0,'N2','N1')) as spill_level from base4;
create index idx_base9 on base9(semana_temp,hotel,tipohabrm,pos);


/*se aplica la lógica de que antes de 25 semanas de anticipacion se proyecta el presupuesto */

update base9
set ingreso_neto=0, noches_cama=0, habitaciones_noche=0, peN0=0, peN1=0, peN2=0, peN3=0, peST=0, 
peSP=0, prN0=0, prN1=0, prN2=0, prN3=0, prST=0, prSP=0, tipo_proyeccion=0
where anticipacion<=-32;

/*traspone el presupuesto*/

drop table if exists presupuesto_transpuesto;
create table presupuesto_transpuesto
select semana_temp, hotel, tipohabrm, pos,
	sum(if(Nivel='N0',ppto_nc,0)) as ppto_nc_N0, 
	sum(if(Nivel='N1',ppto_nc,0)) as ppto_nc_N1,
	sum(if(Nivel='N2',ppto_nc,0)) as ppto_nc_N2,
	sum(if(Nivel='N3',ppto_nc,0)) as ppto_nc_N3,
	sum(if(Nivel='ST',ppto_nc,0)) as ppto_nc_ST,
    sum(if(Nivel='N0',ppto_hn,0)) as ppto_hn_N0, 
	sum(if(Nivel='N1',ppto_hn,0)) as ppto_hn_N1,
	sum(if(Nivel='N2',ppto_hn,0)) as ppto_hn_N2,
	sum(if(Nivel='N3',ppto_hn,0)) as ppto_hn_N3,
	sum(if(Nivel='ST',ppto_hn,0)) as ppto_hn_ST,
    sum(if(Nivel='N0' and ppto_nc <> 0,ppto_ingreso/ppto_nc,0)) as ppto_prN0, 
	sum(if(Nivel='N1' and ppto_nc <> 0,ppto_ingreso/ppto_nc,0)) as ppto_prN1,
	sum(if(Nivel='N2' and ppto_nc <> 0,ppto_ingreso/ppto_nc,0)) as ppto_prN2,
	sum(if(Nivel='N3' and ppto_nc <> 0,ppto_ingreso/ppto_nc,0)) as ppto_prN3,
	sum(if(Nivel='ST' and ppto_nc <> 0,ppto_ingreso/ppto_nc,0)) as ppto_prST
from valle_diccionario.presupuesto
group by semana_temp, hotel, tipohabrm,pos;
create index idx_ppto_transpuesto on presupuesto_transpuesto(semana_temp,hotel,tipohabrm,pos);

update base9 b
set b.peN0=(select p.ppto_nc_N0 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.peN1=(select p.ppto_nc_N1 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.peN2=(select p.ppto_nc_N2 from presupuesto_transpuesto p
where b.pos=p.pos
and b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm)
where anticipacion <-32;

update base9 b
set b.peN3=(select p.ppto_nc_N3 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.peST=(select p.ppto_nc_ST from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.peN0_hn=(select p.ppto_hn_N0 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.peN1_hn=(select p.ppto_hn_N1 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.peN2_hn=(select p.ppto_hn_N2 from presupuesto_transpuesto p
where b.pos=p.pos
and b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm)
where anticipacion <-32;

update base9 b
set b.peN3_hn=(select p.ppto_hn_N3 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.peST_hn=(select p.ppto_hn_ST from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.prN0=(select p.ppto_prN0 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.prN1=(select p.ppto_prN1 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.prN2=(select p.ppto_prN2 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.prN3=(select p.ppto_prN3 from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;

update base9 b
set b.prST=(select p.ppto_prST from presupuesto_transpuesto p
where b.semana_temp=p.semana_temp
and b.hotel=p.hotel
and b.tipohabrm=p.tipohabrm
and b.pos=p.pos)
where anticipacion <-32;




/* se crea la tabla forecast */

drop table if exists forecast;
create table forecast
select base9.*, (ingreso_neto) + (peN0*prN0) + (peN1*prN1) + (peN2*prN2) + (peN3*prN3) + (peSP*prSP) + (peST*prST) as fcst_ing,
noches_cama+peN0+peN1+peN2+peN3+peSP+peST as proy_nc, habitaciones_noche+peN0_hn+peN1_hn+peN2_hn+peN3_hn+peSP_hn+peST_hn as proy_hn  from base9;


/* FIN */
