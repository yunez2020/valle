/* lt_agencia_gestion: Contiene los ttoo relevantes para la gestion que estan en dic_agencia_valle*/
DROP TABLE IF EXISTS lt_agencia_gestion;
CREATE TABLE lt_agencia_gestion
(
	id_agencia_gestion int NOT NULL AUTO_INCREMENT,
	agencia_gestion varchar(25),
	PRIMARY KEY (id_agencia_gestion)
);
INSERT INTO lt_agencia_gestion (agencia_gestion)
SELECT DISTINCT agencia_gestion from valle_diccionario.dic_agencias_valle;

DROP TABLE IF EXISTS lt_descripcion_agencias_tmp;
CREATE TABLE lt_descripcion_agencias_tmp
(
	id_agencia smallint(6) NOT NULL,
	id_canal_reserva smallint(6) NOT NULL,
    cdg_agencia varchar(10) NOT NULL,
	nombre_agencia varchar(45),
	grupo_agencia varchar(45),
	agencia_gestion varchar(25),
    Canal_ varchar(12),
    id_agencia_gestion int,
    PRIMARY KEY (id_agencia)
);

INSERT INTO lt_descripcion_agencias_tmp
SELECT ag.*, c.id_agencia_gestion
FROM (
select a.id_agencia, a.id_canal_reserva, a.cdg_agencia, d.nombre_agencia,d.grupo_agencia,d.agencia_gestion, d.Canal_ from 
lt_agencias a
LEFT OUTER JOIN valle_diccionario.dic_agencias_valle d
ON a.cdg_agencia=d.cdg_agencia
where nombre_agencia is not null) ag
LEFT OUTER JOIN lt_agencia_gestion c
ON ag.agencia_gestion=c.agencia_gestion;


/* ft_reservas_consolidadas: Contiene información agregada de reservas disponibles el origen de datos con agencia*/
DROP TABLE IF EXISTS ft_reservas_consolidadas_agencias;
CREATE TABLE ft_reservas_consolidadas_agencias
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
    id_agencia_gestion int NOT NULL,
    Canal_ varchar(12),
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_noches_cama double DEFAULT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
    PRIMARY KEY (id_fecha_vista, id_anho_uso, id_pos, id_agencia_gestion, id_hotel, id_semana_temp)
);
INSERT INTO ft_reservas_consolidadas_agencias
SELECT r.id_fecha_vista, f.id_anho AS id_anho_uso, a.id_agencia_gestion, a.Canal_, r.id_nacionalidad_gestion AS id_pos, h.id_hotel, f.id_semana_temp, 
SUM(r.nro_noches_cama) AS nro_noches_cama, SUM(r.nro_habitaciones_ocupadas) AS nro_habitaciones_ocupadas, SUM(r.ingreso_neto) AS ingreso_neto
FROM ft_reservas r
INNER JOIN lt_habitaciones h
ON h.id_habitacion = r.id_habitacion
INNER JOIN lt_descripcion_agencias_tmp a
ON r.id_agencia = a.id_agencia
INNER JOIN lt_fechas f
ON f.id_fecha = r.id_fecha_uso
WHERE EXISTS (SELECT 1 FROM tmp_semana_temporada WHERE id_semana_temp = f.id_semana_temp) AND r.id_fecha_vista>'20111230'
GROUP BY r.id_fecha_vista, f.id_anho, a.id_agencia_gestion, a.Canal_, r.id_nacionalidad_gestion, h.id_hotel, f.id_semana_temp;


/* ft_reservas_consolidadas_fp: Se agrega factor de prorrateo a la información de reservas consolidadas */
DROP TABLE IF EXISTS ft_reservas_consolidadas_agencias_fp;
CREATE TABLE ft_reservas_consolidadas_agencias_fp
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_agencia_gestion int NOT NULL,
    Canal_ varchar(12),
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_noches_cama double DEFAULT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
	factor_habitaciones_ocupadas double DEFAULT NULL,
    PRIMARY KEY (id_fecha_vista, id_anho_uso, id_pos, id_agencia_gestion, id_hotel, id_semana_temp)
);
INSERT INTO ft_reservas_consolidadas_agencias_fp
SELECT rc.id_fecha_vista, rc.id_anho_uso, rc.id_agencia_gestion, rc.Canal_, rc.id_pos, rc.id_hotel, rc.id_semana_temp, 
rc.nro_noches_cama, rc.nro_habitaciones_ocupadas, rc.ingreso_neto, rc.nro_habitaciones_ocupadas / t.total_habitaciones_ocupadas AS factor_habitaciones_ocupadas
FROM ft_reservas_consolidadas_agencias rc
INNER JOIN
(
	SELECT id_fecha_vista, id_anho_uso, id_agencia_gestion, Canal_, id_hotel, id_semana_temp, SUM(nro_habitaciones_ocupadas) AS total_habitaciones_ocupadas
	FROM ft_reservas_consolidadas_agencias
	GROUP BY id_fecha_vista, id_anho_uso, id_agencia_gestion, Canal_, id_hotel, id_semana_temp
) t
ON t.id_fecha_vista = rc.id_fecha_vista AND t.id_agencia_gestion = rc.id_agencia_gestion AND t.id_anho_uso = rc.id_anho_uso AND t.id_hotel = rc.id_hotel
AND t.id_semana_temp = rc.id_semana_temp;


/*---------------------------------------------------------------------------------------------------------------
--                                          GENERACIÓN TABLA PIVOTE                                            --
---------------------------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_pivote_agencias_aux;
CREATE TABLE tmp_pivote_agencias_aux
(
	id_fecha_vista_ay int(11) NOT NULL,
	id_fecha_vista_ly int(11) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_agencia_gestion int NOT NULL,
    id_hotel tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    Canal_ varchar(12) NOT NULL,
	KEY idx_fecha_vista_ay (id_fecha_vista_ay, id_pos, id_agencia_gestion, id_hotel, id_semana_temp),
	KEY idx_fecha_vista_ly (id_fecha_vista_ly, id_pos, id_agencia_gestion, id_hotel, id_semana_temp)
);
TRUNCATE TABLE tmp_pivote_agencias_aux;
INSERT INTO tmp_pivote_agencias_aux
SELECT DISTINCT pv.id_fecha_vista_ay, pv.id_fecha_vista_ly, pv.id_pos, pv.id_agencia_gestion, pv.id_hotel, pv.id_semana_temp, pv.Canal_
FROM
(
	SELECT fal.id_fecha_vista_ay, fal.id_fecha_vista_ly, p.id_pos, a.id_agencia_gestion, h.id_hotel, st.id_semana_temp, a.Canal_
	FROM valle_diccionario.tmp_fecha_vista_ay_ly_lw fal
	CROSS JOIN lt_hoteles h
	CROSS JOIN lt_pos p
	CROSS JOIN tmp_semana_temporada st
	CROSS JOIN lt_descripcion_agencias_tmp a
	WHERE fal.id_fecha_vista_ay < CONCAT((SELECT MAX(id_anho) + 1 FROM lt_anhos), '0101') 
) pv;

DROP TABLE IF EXISTS tmp_pivote_agencias;
CREATE TABLE tmp_pivote_agencias
(
	id_fecha_vista_ay int(11) NOT NULL,
	id_fecha_vista_ly int(11) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_agencia_gestion int NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	Canal_ varchar(12) NOT NULL,
    id_anho_uso smallint(6) NOT NULL,
	KEY idx_fecha_vista_ay (id_fecha_vista_ay, id_anho_uso, id_pos, id_agencia_gestion, id_hotel, id_semana_temp),
	KEY idx_fecha_vista_ly (id_fecha_vista_ly, id_anho_uso, id_pos, id_agencia_gestion, id_hotel, id_semana_temp)
);
TRUNCATE TABLE tmp_pivote_agencias;
INSERT INTO tmp_pivote_agencias
SELECT tpaa.*, a.id_anho AS id_anho_uso
FROM tmp_pivote_agencias_aux tpaa
CROSS JOIN lt_anhos a;


/*---------------------------------------------------------------------------------------------------------------
--                                              CONSTRUCCIÓN LYOUT AGENCIAS                                           --
---------------------------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_lyout_temporada_agencias;
CREATE TABLE tmp_lyout_temporada_agencias
(
  id_fecha_vista_ay INT NOT NULL,
  id_anho_uso SMALLINT NOT NULL,
  id_agencia_gestion smallint NOT NULL,
  Canal_ varchar(12),
  id_semana_temp SMALLINT NOT NULL,
  ingreso_neto_lyout DOUBLE,
  nro_noches_cama_lyout DOUBLE,
  nro_habitaciones_ocupadas_lyout DOUBLE,
  PRIMARY KEY (id_fecha_vista_ay, id_anho_uso, id_agencia_gestion, id_semana_temp)
);
TRUNCATE TABLE tmp_lyout_temporada_agencias;
INSERT INTO tmp_lyout_temporada_agencias
SELECT r.id_fecha_vista, LEFT(f.id_fecha, 4) AS id_anho_uso, a.id_agencia_gestion, a.Canal_, f.id_semana_temp, SUM(r.ingreso_neto) AS ingreso_neto_lyout, 
SUM(r.nro_noches_cama) AS nro_noches_cama_lyout, SUM(r.nro_habitaciones_ocupadas) AS nro_habitaciones_ocupadas_lyout
FROM ft_reservas r
INNER JOIN lt_fechas f
ON f.id_fecha = r.id_fecha_uso
INNER JOIN lt_descripcion_agencias_tmp a
ON r.id_agencia = a.id_agencia
WHERE r.id_fecha_vista = (SELECT MAX(id_fecha_vista) FROM ft_reservas_consolidadas_agencias)
GROUP BY r.id_fecha_vista, LEFT(f.id_fecha, 4), f.id_semana_temp;


DROP TABLE IF EXISTS tmp_lyout_anual_agencias;
CREATE TABLE tmp_lyout_anual_agencias
(
	id_fecha_vista_ay INT NOT NULL,
	id_anho_uso SMALLINT NOT NULL,
	id_agencia_gestion smallint NOT NULL,
    Canal_ varchar(12), 
	ingreso_neto_lyout DOUBLE,
	nro_noches_cama_lyout DOUBLE,
	nro_habitaciones_ocupadas_lyout DOUBLE,
	PRIMARY KEY (id_fecha_vista_ay, id_anho_uso, id_agencia_gestion)
);
INSERT INTO tmp_lyout_anual_agencias
SELECT id_fecha_vista_ay, id_anho_uso, id_agencia_gestion, Canal_, SUM(ingreso_neto_lyout) AS ingreso_neto_lyout, 
SUM(nro_noches_cama_lyout) AS nro_noches_cama_lyout, SUM(nro_habitaciones_ocupadas_lyout) AS nro_habitaciones_ocupadas_lyout
FROM tmp_lyout_temporada_agencias lt
WHERE EXISTS (SELECT 1 FROM tmp_semana_temporada WHERE id_semana_temp = lt.id_semana_temp)
GROUP BY id_fecha_vista_ay, id_anho_uso, id_agencia_gestion;


DROP TABLE IF EXISTS tmp_lyout_agencias;
CREATE TABLE tmp_lyout_agencias
(
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_agencia_gestion smallint NOT NULL,
    Canal_ varchar(12),
	id_hotel tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_habitaciones_ocupadas_lyout double DEFAULT NULL,
	ingreso_neto_lyout double DEFAULT NULL,
	nro_noches_cama_lyout double DEFAULT NULL,
    PRIMARY KEY (id_anho_uso, id_pos, id_agencia_gestion, id_hotel, id_semana_temp)
);
INSERT INTO tmp_lyout_agencias
SELECT r.id_anho_uso, r.id_pos, r.id_agencia_gestion, r.Canal_, r.id_hotel, r.id_semana_temp,
SUM(r.nro_habitaciones_ocupadas) AS nro_nro_habitaciones_ocupadas_lyout,
SUM(r.ingreso_neto) AS ingreso_neto_lyout, SUM(r.nro_noches_cama) AS nro_noches_cama_lyout
FROM ft_reservas_consolidadas_agencias r
WHERE r.id_fecha_vista = (SELECT MAX(id_fecha_vista) FROM ft_reservas_consolidadas_agencias) 
AND EXISTS (SELECT 1 FROM tmp_semana_temporada WHERE id_semana_temp = r.id_semana_temp)
GROUP BY r.id_anho_uso, r.id_pos, r.id_agencia_gestion, r.id_hotel, r.id_semana_temp;


DROP TABLE IF EXISTS tmp_lyout_agencias_fp;
CREATE TABLE tmp_lyout_agencias_fp
(
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_agencia_gestion smallint NOT NULL,
    Canal_ varchar(12),
	id_hotel tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_habitaciones_ocupadas_lyout double DEFAULT NULL,
	ingreso_neto_lyout double DEFAULT NULL,
	nro_noches_cama_lyout double DEFAULT NULL,
	factor_habitaciones_ocupadas_lyout double DEFAULT NULL,
    PRIMARY KEY (id_anho_uso, id_pos, id_agencia_gestion, Canal_, id_hotel, id_semana_temp)
);
INSERT INTO tmp_lyout_agencias_fp
SELECT ly.id_anho_uso, ly.id_pos, ly.id_agencia_gestion, ly.Canal_, ly.id_hotel, ly.id_semana_temp, 
ly.nro_habitaciones_ocupadas_lyout, ly.ingreso_neto_lyout, ly.nro_noches_cama_lyout, 
ly.nro_habitaciones_ocupadas_lyout / t.total_habitaciones_ocupadas_lyout AS factor_habitaciones_ocupadas_lyout
FROM tmp_lyout_agencias ly
INNER JOIN
(
	SELECT id_anho_uso, id_pos, id_agencia_gestion, Canal_, id_hotel,id_semana_temp, SUM(nro_habitaciones_ocupadas_lyout) AS total_habitaciones_ocupadas_lyout
	FROM tmp_lyout_agencias
	GROUP BY id_anho_uso, id_hotel, id_agencia_gestion, Canal_, id_semana_temp
) t
ON t.id_anho_uso = ly.id_anho_uso AND t.id_hotel = ly.id_hotel AND t.id_agencia_gestion = ly.id_agencia_gestion AND t.id_semana_temp = ly.id_semana_temp;



/*---------------------------------------------------------------------------------------------------------------
--                                         CONSTRUCCIÓN CUBO PANEL AGENCIAS                                         --
---------------------------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS ft_overview_tmp_agencias;
CREATE TABLE ft_overview_tmp_agencias
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_agencia_gestion smallint NOT NULL,
    Canal_ varchar(12),
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_habitaciones_ocupadas_ay double DEFAULT NULL,
	nro_noches_cama_ay double DEFAULT NULL,
	ingreso_neto_ay double DEFAULT NULL,
	factor_habitaciones_ocupadas_ay double DEFAULT NULL,
	nro_habitaciones_ocupadas_ly double DEFAULT NULL,
	nro_noches_cama_ly double DEFAULT NULL,
	ingreso_neto_ly double DEFAULT NULL,
	factor_habitaciones_ocupadas_ly double DEFAULT NULL,
	nro_habitaciones_ocupadas_lyout double DEFAULT NULL,
	nro_noches_cama_lyout double DEFAULT NULL,
	ingreso_neto_lyout double DEFAULT NULL,
	factor_habitaciones_ocupadas_lyout double DEFAULT NULL,
	PRIMARY KEY (id_fecha_vista, id_anho_uso, id_pos, id_agencia_gestion, Canal_, id_hotel, id_semana_temp)
);
TRUNCATE TABLE ft_overview_tmp_agencias;
INSERT INTO ft_overview_tmp_agencias
SELECT pv.id_fecha_vista_ay, pv.id_anho_uso, pv.id_agencia_gestion, pv.Canal_, pv.id_pos, pv.id_hotel, pv.id_semana_temp,
rc.nro_habitaciones_ocupadas AS nro_habitaciones_ocupadas_ay, 
rc.nro_noches_cama AS nro_noches_cama_ay, 
rc.ingreso_neto AS ingreso_neto_ay, 
rc.factor_habitaciones_ocupadas AS factor_habitaciones_ocupadas_ay,
rcly.nro_habitaciones_ocupadas AS nro_habitaciones_ocupadas_ly, 
rcly.nro_noches_cama AS nro_noches_cama_ly, 
rcly.ingreso_neto AS ingreso_neto_ly,
rcly.factor_habitaciones_ocupadas AS factor_habitaciones_ocupadas_ly,
ly.nro_habitaciones_ocupadas_lyout AS nro_habitaciones_ocupadas_lyout, 
ly.nro_noches_cama_lyout AS nro_noches_cama_lyout, 
ly.ingreso_neto_lyout AS ingreso_neto_lyout,
ly.factor_habitaciones_ocupadas_lyout AS factor_habitaciones_ocupadas_lyout
FROM tmp_pivote_agencias pv
LEFT JOIN ft_reservas_consolidadas_agencias_fp rc
ON rc.id_fecha_vista = pv.id_fecha_vista_ay AND rc.id_anho_uso=pv.id_anho_uso AND rc.id_agencia_gestion = pv.id_agencia_gestion AND rc.id_pos = pv.id_pos AND rc.id_hotel = pv.id_hotel 
AND rc.id_semana_temp = pv.id_semana_temp
LEFT JOIN ft_reservas_consolidadas_agencias_fp rcly
ON rcly.id_fecha_vista = pv.id_fecha_vista_ly AND rcly.id_anho_uso = pv.id_anho_uso - 3 AND rcly.id_agencia_gestion = pv.id_agencia_gestion AND rcly.id_pos = pv.id_pos AND rcly.id_hotel = pv.id_hotel 
AND rcly.id_semana_temp = pv.id_semana_temp
LEFT JOIN tmp_lyout_agencias_fp ly
ON ly.id_anho_uso = pv.id_anho_uso - 3 AND ly.id_agencia_gestion = pv.id_agencia_gestion AND ly.id_pos = pv.id_pos AND ly.id_hotel = pv.id_hotel AND ly.id_semana_temp = pv.id_semana_temp
WHERE rc.nro_habitaciones_ocupadas IS NOT NULL OR rc.nro_noches_cama IS NOT NULL OR rc.ingreso_neto IS NOT NULL 
OR rcly.nro_habitaciones_ocupadas IS NOT NULL OR rcly.nro_noches_cama IS NOT NULL OR rcly.ingreso_neto IS NOT NULL
OR ly.nro_habitaciones_ocupadas_lyout IS NOT NULL OR ly.nro_noches_cama_lyout IS NOT NULL OR ly.ingreso_neto_lyout IS NOT NULL;


DROP TABLE IF EXISTS ft_overview_agencias;
CREATE TABLE ft_overview_agencias
(
	id_vista char(5) NOT NULL,
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
    id_agencia_gestion smallint NOT NULL,
    Canal_ varchar(12),
    id_pos smallint(6) NOT NULL,
    id_hotel tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	nro_noches_cama double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
	PRIMARY KEY (id_vista, id_fecha_vista, id_anho_uso, id_pos,id_agencia_gestion, Canal_, id_hotel, id_semana_temp)
);
INSERT INTO ft_overview_agencias
SELECT 'AY' AS id_vista, ot.id_fecha_vista, ot.id_anho_uso, ot.id_agencia_gestion, ot.Canal_, ot.id_pos, ot.id_hotel, ot.id_semana_temp, 
ot.nro_habitaciones_ocupadas_ay, ot.nro_noches_cama_ay, ot.ingreso_neto_ay
FROM ft_overview_tmp_agencias ot
WHERE nro_habitaciones_ocupadas_ay IS NOT NULL OR nro_noches_cama_ay IS NOT NULL OR ingreso_neto_ay IS NOT NULL
UNION ALL
SELECT 'LY' AS id_vista, ot.id_fecha_vista, ot.id_anho_uso, ot.id_agencia_gestion, ot.Canal_, ot.id_pos, ot.id_hotel, ot.id_semana_temp, 
ot.nro_habitaciones_ocupadas_ly, ot.nro_noches_cama_ly, ot.ingreso_neto_ly
FROM ft_overview_tmp_agencias ot
WHERE nro_habitaciones_ocupadas_ly IS NOT NULL OR nro_noches_cama_ly IS NOT NULL OR ingreso_neto_Ly IS NOT NULL
UNION ALL
SELECT 'LYOUT' AS id_vista, ot.id_fecha_vista, ot.id_anho_uso, ot.id_agencia_gestion, ot.Canal_, ot.id_pos, ot.id_hotel, ot.id_semana_temp, 
ot.nro_habitaciones_ocupadas_lyout, ot.nro_noches_cama_lyout, ot.ingreso_neto_lyout
FROM ft_overview_tmp_agencias ot
WHERE nro_habitaciones_ocupadas_lyout IS NOT NULL OR nro_noches_cama_lyout IS NOT NULL OR ingreso_neto_lyout IS NOT NULL;

/*
insert into `ft_overview_agencias`

select

'LLLY' as id_vista, date_format(str_to_date(df.fecha, '%Y-%m-%d'),'%Y%m%d') as fecha,f16.id_anho_uso,f16.id_agencia_gestion,f16.id_pos,f16.id_hotel,f16.id_semana_temp,f16.nro_habitaciones_ocupadas,f16.nro_noches_cama,f16.ingreso_neto

from Valle_RM_20171208.ft_overview_agencias f16 inner join valle_diccionario.dic_fechas_copy_copy df on date_format(str_to_date(df.fecha_llly, '%Y-%m-%d'),'%Y%m%d')=f16.id_fecha_vista and f16.id_vista='AY' and id_anho_uso='2016'
;

union all

select

'LLY' as id_vista, date_format(str_to_date(df.fecha, '%Y-%m-%d'),'%Y%m%d') as fecha,f17.id_anho_uso,f17.id_agencia_gestion,f17.id_pos,f17.id_hotel,f17.id_semana_temp,f17.nro_habitaciones_ocupadas,f17.nro_noches_cama,f17.ingreso_neto

from Valle_RM_20190222.ft_overview_agencias f17 inner join valle_diccionario.dic_fechas_copy_copy df on date_format(str_to_date(df.fecha_lly, '%Y-%m-%d'),'%Y%m%d')=f17.id_fecha_vista and f17.id_vista='AY' and id_anho_uso='2017';
*/

update ft_overview_agencias set id_anho_uso='2023' where id_vista in ('LLY','LLLY');

delete from ft_overview_agencias where id_fecha_vista<'20180526';

analyze table `ft_overview_agencias`;
