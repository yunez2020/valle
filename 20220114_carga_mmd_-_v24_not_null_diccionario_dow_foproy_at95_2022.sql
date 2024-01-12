/*---------------------------------------------------------------------------------------------------------------
--  ***************************************        CARGA DE DATOS       ************************************** --
---------------------------------------------------------------------------------------------------------------*/

/* tmp_semana_temporada: Contiene las semanas que serán mostradas en el reporte */
DROP TABLE IF EXISTS tmp_semana_temporada;
CREATE TABLE tmp_semana_temporada
(
	id_semana_temp SMALLINT,
	PRIMARY KEY (id_semana_temp)
);
INSERT INTO tmp_semana_temporada VALUES (1);
INSERT INTO tmp_semana_temporada VALUES (2);
INSERT INTO tmp_semana_temporada VALUES (3);
INSERT INTO tmp_semana_temporada VALUES (4);
INSERT INTO tmp_semana_temporada VALUES (5);
INSERT INTO tmp_semana_temporada VALUES (6);
INSERT INTO tmp_semana_temporada VALUES (7);
INSERT INTO tmp_semana_temporada VALUES (8);
INSERT INTO tmp_semana_temporada VALUES (9);
INSERT INTO tmp_semana_temporada VALUES (10);
INSERT INTO tmp_semana_temporada VALUES (11);
INSERT INTO tmp_semana_temporada VALUES (12);
INSERT INTO tmp_semana_temporada VALUES (13);
INSERT INTO tmp_semana_temporada VALUES (14);
INSERT INTO tmp_semana_temporada VALUES (15);

/* tmp_dow: Contiene los días de la semana que serán mostrados en el reporte */



/*---------------------------------------------------------------------------------------------------------------
--                                              CARGA TABLAS LOOKUP                                            --
---------------------------------------------------------------------------------------------------------------*/

/* lt_anhos: Carga los años disponibles en el origen de datos */
DROP TABLE IF EXISTS lt_anhos;
CREATE TABLE lt_anhos
(
	id_anho SMALLINT,
	PRIMARY KEY (id_anho)
);
INSERT INTO lt_anhos
SELECT DISTINCT LEFT(fecha_uso, 4) AS anho
FROM final_final_last ffl
LEFT JOIN lt_anhos a
ON LEFT(ffl.fecha_uso, 4) = a.id_anho
WHERE a.id_anho IS NULL;


/* lt_fechas: Contiene información de todas las fechas de uso disponibles en el origen de datos */
DROP TABLE IF EXISTS lt_fechas;
CREATE TABLE lt_fechas
(
	id_fecha int,
	id_mes_anho MEDIUMINT,
	id_anho SMALLINT,
	id_semana_temp smallint,
	dsc_fecha date,
    dow int,
	PRIMARY KEY (id_fecha)
);
INSERT INTO lt_fechas
select fecha_uso, substr(fecha_uso,6),agno,semana_temp,CONCAT(LEFT(fecha_uso, 4), '-', SUBSTR(fecha_uso, 5, 2), '-', SUBSTR(fecha_uso, 7, 2)), dia_semana
from valle_diccionario.semanas s
inner join lt_anhos a
on s.agno=a.id_anho;

/* lt_tipo_habitacion: Contiene todos los tipos de habitaciones disponibles en el origen de datos */
DROP TABLE IF EXISTS lt_tipo_habitacion;
CREATE TABLE lt_tipo_habitacion
(
	id_tipo_habitacion tinyint NOT NULL AUTO_INCREMENT,
	cdg_tipo_habitacion char(15),
	PRIMARY KEY (id_tipo_habitacion),
	KEY (cdg_tipo_habitacion)
);
INSERT INTO lt_tipo_habitacion (cdg_tipo_habitacion)
SELECT DISTINCT tipohabrm
FROM final_final_last ffl
LEFT JOIN lt_tipo_habitacion ta
ON ta.cdg_tipo_habitacion = ffl.tipohabrm
WHERE ta.id_tipo_habitacion IS NULL;


/* lt_nacionalidades: Contiene todas las nacionalidades disponibles en el origen de datos */
DROP TABLE IF EXISTS lt_nacionalidades;
CREATE TABLE lt_nacionalidades
(
	id_nacionalidad smallint NOT NULL AUTO_INCREMENT,
	cdg_nacionalidad char(3),
	PRIMARY KEY (id_nacionalidad),
	KEY (cdg_nacionalidad)
);
INSERT INTO lt_nacionalidades (cdg_nacionalidad)
SELECT DISTINCT dnacio
FROM final_final_last ffl
LEFT JOIN lt_nacionalidades n
ON n.cdg_nacionalidad = ffl.dnacio
WHERE n.id_nacionalidad IS NULL;
INSERT INTO lt_nacionalidades (cdg_nacionalidad)
SELECT DISTINCT CASE WHEN ffl.nacionalidad_gestion = 'OTROS' THEN 'OTH' ELSE ffl.nacionalidad_gestion END AS nacionalidad_gestion
FROM final_final_last ffl
LEFT JOIN lt_nacionalidades n
ON n.cdg_nacionalidad = CASE WHEN ffl.nacionalidad_gestion = 'OTROS' THEN 'OTH' ELSE ffl.nacionalidad_gestion END
WHERE n.id_nacionalidad IS NULL;


/* lt_pos: Contiene todos los POS disponibles en el origen de datos */
DROP TABLE IF EXISTS lt_pos;
CREATE TABLE lt_pos like valle_diccionario.lt_pos;

INSERT INTO lt_pos 
SELECT * from valle_diccionario.lt_pos;

/* lt_hoteles: Contiene todos los hoteles disponibles en el origen de datos */
DROP TABLE IF EXISTS lt_hoteles;
CREATE TABLE lt_hoteles
(
	id_hotel tinyint NOT NULL AUTO_INCREMENT,
	cdg_hotel char(3),
	PRIMARY KEY (id_hotel),
	KEY (cdg_hotel)
);
INSERT INTO lt_hoteles (cdg_hotel)
SELECT DISTINCT hotel
FROM final_final_last ffl
LEFT JOIN lt_hoteles h
ON h.cdg_hotel = ffl.hotel
WHERE h.id_hotel IS NULL;


/* lt_habitaciones: Contiene la relación entre los hoteles y tipos de habitaciones, más las capacidades de las habitaciones */
DROP TABLE IF EXISTS lt_habitaciones;
CREATE TABLE lt_habitaciones
(
	id_habitacion smallint NOT NULL AUTO_INCREMENT,
	id_hotel tinyint,
	id_tipo_habitacion tinyint,
	nro_habitaciones tinyint,
	nro_camas double,
	PRIMARY KEY (id_habitacion)
);
INSERT INTO lt_habitaciones (id_hotel, id_tipo_habitacion, nro_habitaciones, nro_camas)
SELECT DISTINCT h.id_hotel, th.id_tipo_habitacion, c.nro_habitaciones, c.nro_camas
FROM final_final_last ffl
INNER JOIN lt_hoteles h
ON h.cdg_hotel = ffl.hotel
INNER JOIN lt_tipo_habitacion th
ON th.cdg_tipo_habitacion = ffl.tipohabrm
LEFT JOIN valle_diccionario.capacidades c
ON c.hotel = ffl.hotel AND c.tipohabrm = ffl.tipohabrm
LEFT JOIN lt_habitaciones hb
ON hb.id_hotel = h.id_hotel AND hb.id_tipo_habitacion = th.id_tipo_habitacion
WHERE id_habitacion IS NULL;


/* lt_nivel_tarifa: Contiene todos niveles tarifarios disponibles en el origen de datos */
DROP TABLE IF EXISTS lt_nivel_tarifa;
CREATE TABLE lt_nivel_tarifa
(
	id_nivel_tarifa int NOT NULL AUTO_INCREMENT,
	cdg_nivel_tarifa char(3),
	PRIMARY KEY (id_nivel_tarifa),
	KEY (cdg_nivel_tarifa)
);
INSERT INTO lt_nivel_tarifa (cdg_nivel_tarifa)
SELECT DISTINCT CASE WHEN ffl.nivel = '' OR ffl.nivel IS NULL THEN '--' ELSE ffl.nivel END
FROM final_final_last ffl
LEFT JOIN lt_nivel_tarifa nt
ON nt.cdg_nivel_tarifa = CASE WHEN ffl.nivel = '' OR ffl.nivel IS NULL THEN '--' ELSE ffl.nivel END
WHERE nt.id_nivel_tarifa IS NULL;


/* lt_canal_reserva: Contiene los canales de reserva predefinidos */
DROP TABLE IF EXISTS lt_canal_reserva;
CREATE TABLE lt_canal_reserva
(
	id_canal_reserva SMALLINT,
	cdg_canal_reserva CHAR(10),
	PRIMARY KEY (id_canal_reserva)
);
INSERT INTO lt_canal_reserva VALUES (0, 'INDEFINIDO');
INSERT INTO lt_canal_reserva VALUES (1, 'DIRECTO');
INSERT INTO lt_canal_reserva VALUES (2, 'EARLY');
INSERT INTO lt_canal_reserva VALUES (3, 'IBE');
INSERT INTO lt_canal_reserva VALUES (4, 'ITAU');


/* lt_agencias: Contiene todas las agencias disponibles en el origen de datos asocidados a un canal de reserva */
DROP TABLE IF EXISTS lt_agencias;
CREATE TABLE lt_agencias
(
	id_agencia SMALLINT NOT NULL AUTO_INCREMENT,
	id_canal_reserva SMALLINT,
	cdg_agencia CHAR(10),
	PRIMARY KEY (id_agencia),
	KEY (cdg_agencia)
);
INSERT INTO lt_agencias (id_canal_reserva, cdg_agencia)
SELECT DISTINCT cr.id_canal_reserva, CASE WHEN LEFT(TRIM(REPLACE(ffl.dagenc, ',', '')), 3) = '' THEN '---' ELSE LEFT(TRIM(REPLACE(ffl.dagenc, ',', '')), 3) END
FROM final_final_last ffl
INNER JOIN lt_canal_reserva cr
ON cr.id_canal_reserva = CASE 
WHEN ffl.early <> 0 THEN 2
WHEN ffl.ibe <> 0 THEN 3
WHEN ffl.itau <> 0 THEN 4
WHEN ffl.directo <> 0 THEN 1
ELSE 0
END
LEFT JOIN lt_agencias a
ON a.id_canal_reserva = cr.id_canal_reserva
AND a.cdg_agencia = CASE WHEN LEFT(TRIM(REPLACE(ffl.dagenc, ',', '')), 3) = '' THEN '---' ELSE LEFT(TRIM(REPLACE(ffl.dagenc, ',', '')), 3) END
WHERE a.id_agencia IS NULL;


/* lt_nivel_tarifa: Contiene todas las tarifas disponibles en el origen de datos */
DROP TABLE IF EXISTS lt_tarifas;
CREATE TABLE lt_tarifas
(
	id_tarifa int NOT NULL AUTO_INCREMENT,
	cdg_tarifa char(3),
	PRIMARY KEY (id_tarifa),
	KEY (cdg_tarifa)
);
INSERT INTO lt_tarifas (cdg_tarifa)
SELECT DISTINCT CASE WHEN LEFT(TRIM(REPLACE(ffl.dtaras, ',', '')), 3) = '' THEN '---' ELSE LEFT(TRIM(REPLACE(ffl.dtaras, ',', '')), 3) END
FROM final_final_last ffl
LEFT JOIN lt_tarifas t
ON t.cdg_tarifa = CASE WHEN LEFT(TRIM(REPLACE(ffl.dtaras, ',', '')), 3) = '' THEN '---' ELSE LEFT(TRIM(REPLACE(ffl.dtaras, ',', '')), 3) END
WHERE t.id_tarifa IS NULL;


/* ft_reservas: Contiene información normalizada de reservas disponibles el origen de datos */
DROP TABLE IF EXISTS ft_reservas;
CREATE TABLE ft_reservas
(
	id_fecha_vista int NOT NULL,
	id_fecha_uso int NOT NULL,
	id_agencia smallint NOT NULL,
	id_habitacion smallint NOT NULL,
	id_nacionalidad smallint NOT NULL,
	id_nacionalidad_gestion smallint NOT NULL,
	id_tarifa int NOT NULL,
	id_nivel_tarifa int NOT NULL,
	id_anticipacion smallint NOT NULL,
	nro_adultos double,
	nro_adolescentes double,
	nro_ninhos double,
	nro_infantes double,
	nro_noches_cama double,
	nro_habitaciones_ocupadas double,
	nro_total_mas_infantes double,
	nro_total_sin_infantes double,
	ingreso_neto double,
	PRIMARY KEY (id_fecha_vista, id_fecha_uso, id_agencia, id_habitacion, id_nacionalidad, id_nacionalidad_gestion, id_tarifa, id_nivel_tarifa, id_anticipacion)
);
INSERT INTO ft_reservas
SELECT ffl.fecha_vista, ffl.fecha_uso, a.id_agencia , hb.id_habitacion, n.id_nacionalidad, p.id_pos, t.id_tarifa, nt.id_nivel_tarifa,
ffl.anticipacion, SUM(dadult) AS dadult, SUM(dteen) AS dteen, SUM(dninos) AS dninos, SUM(dinfantes) AS dinfantes, SUM(noches_cama) AS noches_cama,
SUM(habitaciones_noches) AS habitaciones_noches, SUM(dadult + dteen + dninos + dinfantes) AS nro_total_mas_infantes,
SUM(dadult + dteen + dninos) AS nro_total_sin_infantes, SUM(ingreso_neto) AS ingreso_neto
FROM final_final_last ffl
INNER JOIN lt_agencias a
ON a.cdg_agencia = CASE WHEN LEFT(TRIM(REPLACE(ffl.dagenc, ',', '')), 3) = '' THEN '---' ELSE LEFT(TRIM(REPLACE(ffl.dagenc, ',', '')), 3) END
AND a.id_canal_reserva = CASE 
WHEN ffl.early <> 0 THEN 2
WHEN ffl.ibe <> 0 THEN 3
WHEN ffl.itau <> 0 THEN 4
WHEN ffl.directo <> 0 THEN 1
ELSE 0
END
INNER JOIN lt_hoteles h
ON h.cdg_hotel = ffl.hotel
INNER JOIN lt_tipo_habitacion th
ON th.cdg_tipo_habitacion = ffl.tipohabrm
INNER JOIN lt_habitaciones hb
ON hb.id_hotel = h.id_hotel AND hb.id_tipo_habitacion = th.id_tipo_habitacion
INNER JOIN lt_nacionalidades n
ON n.cdg_nacionalidad = ffl.dnacio
INNER JOIN lt_pos p
ON p.cdg_pos = CASE WHEN ffl.nacionalidad_gestion IN ('ARG', 'CHI', 'USA', 'BRA', 'SKT') THEN ffl.nacionalidad_gestion ELSE 'OTH' END
INNER JOIN lt_tarifas t
ON t.cdg_tarifa = CASE WHEN LEFT(TRIM(REPLACE(ffl.dtaras, ',', '')), 3) = '' THEN '---' ELSE LEFT(TRIM(REPLACE(ffl.dtaras, ',', '')), 3) END
INNER JOIN lt_nivel_tarifa nt
ON nt.cdg_nivel_tarifa = CASE WHEN ffl.nivel = '' OR ffl.nivel IS NULL THEN '--' ELSE ffl.nivel END
GROUP BY ffl.fecha_vista, ffl.fecha_uso, a.id_agencia , hb.id_habitacion, n.id_nacionalidad, p.id_pos, t.id_tarifa, nt.id_nivel_tarifa, ffl.anticipacion;


/* ft_reservas_consolidadas: Contiene información agregada de reservas disponibles el origen de datos */
DROP TABLE IF EXISTS ft_reservas_consolidadas;
CREATE TABLE ft_reservas_consolidadas
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_noches_cama double DEFAULT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
	PRIMARY KEY (id_fecha_vista, id_anho_uso, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp)
);
INSERT INTO ft_reservas_consolidadas
SELECT r.id_fecha_vista, f.id_anho AS id_anho_uso, r.id_nacionalidad_gestion AS id_pos, h.id_hotel, h.id_tipo_habitacion, r.id_nivel_tarifa, f.id_semana_temp, 
SUM(r.nro_noches_cama) AS nro_noches_cama, SUM(r.nro_habitaciones_ocupadas) AS nro_habitaciones_ocupadas, SUM(r.ingreso_neto) AS ingreso_neto
FROM ft_reservas r
INNER JOIN lt_habitaciones h
ON h.id_habitacion = r.id_habitacion
INNER JOIN lt_fechas f
ON f.id_fecha = r.id_fecha_uso
WHERE EXISTS (SELECT 1 FROM tmp_semana_temporada WHERE id_semana_temp = f.id_semana_temp)
GROUP BY r.id_fecha_vista, f.id_anho, r.id_nacionalidad_gestion, h.id_hotel, h.id_tipo_habitacion, r.id_nivel_tarifa, f.id_semana_temp;


/* ft_reservas_consolidadas_fp: Se agrega factor de prorrateo a la información de reservas consolidadas */
DROP TABLE IF EXISTS ft_reservas_consolidadas_fp;
CREATE TABLE ft_reservas_consolidadas_fp
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_noches_cama double DEFAULT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
	factor_habitaciones_ocupadas double DEFAULT NULL,
	PRIMARY KEY (id_fecha_vista, id_anho_uso, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp)
);
INSERT INTO ft_reservas_consolidadas_fp
SELECT rc.id_fecha_vista, rc.id_anho_uso, rc.id_pos, rc.id_hotel, rc.id_tipo_habitacion, rc.id_nivel_tarifa, rc.id_semana_temp, 
rc.nro_noches_cama, rc.nro_habitaciones_ocupadas, rc.ingreso_neto, rc.nro_habitaciones_ocupadas / t.total_habitaciones_ocupadas AS factor_habitaciones_ocupadas
FROM ft_reservas_consolidadas rc
INNER JOIN
(
	SELECT id_fecha_vista, id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp, SUM(nro_habitaciones_ocupadas) AS total_habitaciones_ocupadas
	FROM ft_reservas_consolidadas
	GROUP BY id_fecha_vista, id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp
) t
ON t.id_fecha_vista = rc.id_fecha_vista AND t.id_anho_uso = rc.id_anho_uso AND t.id_hotel = rc.id_hotel AND t.id_tipo_habitacion = rc.id_tipo_habitacion
AND t.id_semana_temp = rc.id_semana_temp;


/* ft_presupuestos: Contiene información normalizada del presupuesto disponible el origen de datos */
DROP TABLE IF EXISTS ft_presupuestos;
CREATE TABLE ft_presupuestos
(
	id_anho_ppto SMALLINT NOT NULL,
	id_hotel TINYINT NOT NULL,
	id_semana_temp SMALLINT NOT NULL,
	id_tipo_habitacion TINYINT NOT NULL,
	id_nivel_tarifa INT NOT NULL,
	id_pos SMALLINT NOT NULL,
	ppto_noche_cama DOUBLE,
	ppto_ingreso DOUBLE,
	ppto_tarifa DOUBLE,
	PRIMARY KEY (id_anho_ppto, id_hotel, id_semana_temp, id_tipo_habitacion, id_nivel_tarifa, id_pos)
);
INSERT INTO ft_presupuestos
SELECT 2022 AS id_anho_ppto, h.id_hotel, p.semana_temp, th.id_tipo_habitacion, nt.id_nivel_tarifa, n.id_pos,
SUM(COALESCE(p.ppto_nc, 0)) AS ppto_noche_cama, SUM(COALESCE(p.ppto_ingreso, 0)) AS ppto_ingreso, SUM(COALESCE(p.ppto_tarifa, 0)) AS ppto_tarifa
FROM valle_diccionario.presupuesto p
INNER JOIN lt_hoteles h
ON h.cdg_hotel = p.hotel
INNER JOIN lt_tipo_habitacion th
ON UCASE(th.cdg_tipo_habitacion) = UCASE(p.tipohabrm)
INNER JOIN lt_nivel_tarifa nt
ON nt.cdg_nivel_tarifa = CASE WHEN CASE WHEN TRIM(p.nivel) IN ('0', '1', '2', '3') THEN CONCAT('N', p.nivel) ELSE TRIM(p.nivel) END = '' 
OR CASE WHEN TRIM(p.nivel) IN ('0', '1', '2', '3') THEN CONCAT('N', p.nivel) ELSE TRIM(p.nivel) END IS NULL THEN '--' ELSE 
CASE WHEN TRIM(p.nivel) IN ('0', '1', '2', '3') THEN CONCAT('N', p.nivel) ELSE TRIM(p.nivel) END END
INNER JOIN lt_pos n
ON n.cdg_pos = p.pos
LEFT JOIN ft_presupuestos fp
ON fp.id_anho_ppto = 2022 AND fp.id_hotel = h.id_hotel AND fp.id_semana_temp = p.semana_temp AND fp.id_tipo_habitacion = th.id_tipo_habitacion
AND fp.id_nivel_tarifa = nt.id_nivel_tarifa AND fp.id_pos = n.id_pos
WHERE fp.id_anho_ppto IS NULL
GROUP BY 1, 2, 3, 4, 5, 6;


/* ft_presupuestos_fp: Se agrega factor de prorrateo a la información de presupuesto */
/*DROP TABLE IF EXISTS ft_presupuestos_fp;
CREATE TABLE ft_presupuestos_fp
(
	id_anho_ppto SMALLINT NOT NULL,
	id_hotel TINYINT NOT NULL,
	id_semana_temp SMALLINT NOT NULL,
	id_tipo_habitacion TINYINT NOT NULL,
	id_nivel_tarifa INT NOT NULL,
	id_pos SMALLINT NOT NULL,
	ppto_noche_cama DOUBLE,
	ppto_ingreso DOUBLE,
	ppto_tarifa DOUBLE,
	factor_noches_cama double DEFAULT NULL,
	PRIMARY KEY (id_anho_ppto, id_hotel, id_semana_temp, id_tipo_habitacion, id_nivel_tarifa, id_pos)
);
INSERT INTO ft_presupuestos_fp
SELECT ppto.id_anho_ppto, ppto.id_hotel, ppto.id_semana_temp, ppto.id_tipo_habitacion, ppto.id_nivel_tarifa, ppto.id_pos, 
ppto.ppto_noche_cama, ppto.ppto_ingreso, ppto.ppto_tarifa, 
CASE WHEN t.total_nro_noches_cama = 0 THEN
	0
ELSE
	ppto.ppto_noche_cama / t.total_nro_noches_cama
END AS factor_noches_cama
FROM ft_presupuestos ppto
INNER JOIN
(
	SELECT id_anho_ppto, id_hotel, id_tipo_habitacion, id_semana_temp, SUM(ppto_noche_cama) AS total_nro_noches_cama
	FROM ft_presupuestos
	GROUP BY id_anho_ppto, id_hotel, id_tipo_habitacion, id_semana_temp
) t
ON t.id_anho_ppto = ppto.id_anho_ppto AND t.id_hotel = ppto.id_hotel AND t.id_tipo_habitacion = ppto.id_tipo_habitacion
AND t.id_semana_temp = ppto.id_semana_temp;*/


/* ft_proyecciones: Contiene información normalizada de proyecciones disponible el origen de datos */

DROP TABLE IF EXISTS ft_proyecciones;
CREATE TABLE ft_proyecciones
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    id_anticipacion smallint NOT NULL,
	delta_habitaciones_ocupadas_proy double DEFAULT NULL,
	delta_nro_noches_cama_proy double DEFAULT NULL,
	delta_ingreso_neto_proy double DEFAULT NULL,
	PRIMARY KEY (id_fecha_vista, id_anho_uso, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp)
);
INSERT INTO ft_proyecciones
SELECT id_fecha_vista, id_anho_uso, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp, id_anticipacion,
SUM(delta_habitaciones_ocupadas_proy) AS delta_habitaciones_ocupadas_proy, SUM(delta_noches_cama_proy) AS delta_noches_cama_proy, 
SUM(delta_ingreso_proy) AS delta_ingreso_proy
FROM
(
	SELECT fc.fecha_vista AS id_fecha_vista, agno AS id_anho_uso, p.id_pos, h.id_hotel, th.id_tipo_habitacion, 
	nt.id_nivel_tarifa, fc.semana_temp AS id_semana_temp, anticipacion AS id_anticipacion, 
    peN0_hn AS delta_habitaciones_ocupadas_proy, peN0 AS delta_noches_cama_proy, peN0 * prN0 AS delta_ingreso_proy
	FROM forecast fc
	INNER JOIN lt_hoteles h
	ON h.cdg_hotel = fc.hotel
	INNER JOIN lt_tipo_habitacion th
	ON UCASE(th.cdg_tipo_habitacion) = UCASE(fc.tipohabrm)
	INNER JOIN lt_nivel_tarifa nt
	ON nt.cdg_nivel_tarifa = 'N0'
	INNER JOIN lt_pos p
	ON p.cdg_pos = fc.pos
	WHERE peN0 <> 0
	UNION ALL
	SELECT fc.fecha_vista AS id_fecha_vista, agno AS id_anho_uso, p.id_pos, h.id_hotel, th.id_tipo_habitacion, 
	nt.id_nivel_tarifa, fc.semana_temp AS id_semana_temp, anticipacion AS id_anticipacion, 
    peN1_hn AS delta_habitaciones_ocupadas_proy, peN1 AS delta_noches_cama_proy, peN1 * prN1 AS delta_ingreso_proy
	FROM forecast fc
	INNER JOIN lt_hoteles h
	ON h.cdg_hotel = fc.hotel
	INNER JOIN lt_tipo_habitacion th
	ON UCASE(th.cdg_tipo_habitacion) = UCASE(fc.tipohabrm)
	INNER JOIN lt_nivel_tarifa nt
	ON nt.cdg_nivel_tarifa = 'N1'
	INNER JOIN lt_pos p
	ON p.cdg_pos = fc.pos
	WHERE peN1 <> 0
	UNION ALL
	SELECT fc.fecha_vista AS id_fecha_vista, agno AS id_anho_uso, p.id_pos, h.id_hotel, th.id_tipo_habitacion, 
	nt.id_nivel_tarifa, fc.semana_temp AS id_semana_temp, anticipacion AS id_anticipacion,
    peN2_hn AS delta_habitaciones_ocupadas_proy, peN2 AS delta_noches_cama_proy, peN2 * prN2 AS delta_ingreso_proy
	FROM forecast fc
	INNER JOIN lt_hoteles h
	ON h.cdg_hotel = fc.hotel
	INNER JOIN lt_tipo_habitacion th
	ON UCASE(th.cdg_tipo_habitacion) = UCASE(fc.tipohabrm)
	INNER JOIN lt_nivel_tarifa nt
	ON nt.cdg_nivel_tarifa = 'N2'
	INNER JOIN lt_pos p
	ON p.cdg_pos = fc.pos
	WHERE peN2 <> 0
	UNION ALL
	SELECT fc.fecha_vista AS id_fecha_vista, agno AS id_anho_uso, p.id_pos, h.id_hotel, th.id_tipo_habitacion, 
	nt.id_nivel_tarifa, fc.semana_temp AS id_semana_temp, anticipacion AS id_anticipacion,
    peN3_hn AS delta_habitaciones_ocupadas_proy, peN3 AS delta_noches_cama_proy, peN3 * prN3 AS delta_ingreso_proy
	FROM forecast fc
	INNER JOIN lt_hoteles h
	ON h.cdg_hotel = fc.hotel
	INNER JOIN lt_tipo_habitacion th
	ON UCASE(th.cdg_tipo_habitacion) = UCASE(fc.tipohabrm)
	INNER JOIN lt_nivel_tarifa nt
	ON nt.cdg_nivel_tarifa = 'N3'
	INNER JOIN lt_pos p
	ON p.cdg_pos = fc.pos
	WHERE peN3 <> 0
    UNION ALL
	SELECT fc.fecha_vista AS id_fecha_vista, agno AS id_anho_uso, p.id_pos, h.id_hotel, th.id_tipo_habitacion, 
	nt.id_nivel_tarifa, fc.semana_temp AS id_semana_temp, anticipacion AS id_anticipacion,
    peSP_hn AS delta_habitaciones_ocupadas_proy, peSP AS delta_noches_cama_proy, peSP * prSP AS delta_ingreso_proy
	FROM forecast fc
	INNER JOIN lt_hoteles h
	ON h.cdg_hotel = fc.hotel
	INNER JOIN lt_tipo_habitacion th
	ON UCASE(th.cdg_tipo_habitacion) = UCASE(fc.tipohabrm)
	INNER JOIN lt_nivel_tarifa nt
	ON nt.cdg_nivel_tarifa = fc.spill_level
	INNER JOIN lt_pos p
	ON p.cdg_pos = fc.pos
	WHERE peSP <> 0
    UNION ALL
	SELECT fc.fecha_vista AS id_fecha_vista, agno AS id_anho_uso, p.id_pos, h.id_hotel, th.id_tipo_habitacion, 
	nt.id_nivel_tarifa, fc.semana_temp AS id_semana_temp, anticipacion AS id_anticipacion,
    peST_hn AS delta_habitaciones_ocupadas_proy, peST AS delta_noches_cama_proy, peST * prST AS delta_ingreso_proy
	FROM forecast fc
	INNER JOIN lt_hoteles h
	ON h.cdg_hotel = fc.hotel
	INNER JOIN lt_tipo_habitacion th
	ON UCASE(th.cdg_tipo_habitacion) = UCASE(fc.tipohabrm)
	INNER JOIN lt_nivel_tarifa nt
	ON nt.cdg_nivel_tarifa = 'ST'
	INNER JOIN lt_pos p
	ON p.cdg_pos = fc.pos
	WHERE peST <> 0
) d
GROUP BY id_fecha_vista, id_anho_uso, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp, id_anticipacion;


/*---------------------------------------------------------------------------------------------------------------
--                                          GENERACIÓN TABLA PIVOTE                                            --
---------------------------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_pivote;
CREATE TABLE tmp_pivote
(
	id_fecha_vista_ay int(11) NOT NULL,
	id_fecha_vista_ly int(11) NOT NULL,
    id_fecha_vista_lw int(11) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    id_anticipacion smallint not null,
    last_day_semana_temp int(11) NOT NULL,
	KEY idx_fecha_vista_ay (id_fecha_vista_ay, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp),
	KEY idx_fecha_vista_ly (id_fecha_vista_ly, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp),
    KEY idx_fecha_vista_lw (id_fecha_vista_lw, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp)
);
TRUNCATE TABLE tmp_pivote;
INSERT INTO tmp_pivote
SELECT pv.id_fecha_vista_ay, pv.id_fecha_vista_ly, pv.id_fecha_vista_lw, pv.id_pos, pv.id_hotel, pv.id_tipo_habitacion, pv.id_nivel_tarifa, st.semana_temp, ceiling(datediff(pv.id_fecha_vista_ay,st.last_day_semana_temp)/7), st.last_day_semana_temp
FROM
(
	SELECT fal.id_fecha_vista_ay, fal.id_fecha_vista_ly, fal.id_fecha_vista_lw, p.id_pos, h.id_hotel, th.id_tipo_habitacion, nt.id_nivel_tarifa
	FROM valle_diccionario.tmp_fecha_vista_ay_ly_lw fal
	CROSS JOIN lt_hoteles h
	INNER JOIN lt_habitaciones hb
	ON hb.id_hotel = h.id_hotel
	INNER JOIN lt_tipo_habitacion th
	ON th.id_tipo_habitacion = hb.id_tipo_habitacion
	CROSS JOIN lt_nivel_tarifa nt
	CROSS JOIN lt_pos p
	WHERE fal.id_fecha_vista_ay < CONCAT((SELECT MAX(id_anho) + 1 FROM lt_anhos), '0101') 
) pv
CROSS JOIN 
(SELECT semana_temp, max(fecha_uso) as last_day_semana_temp FROM valle_diccionario.semanas
where agno=(SELECT MAX(id_anho) FROM lt_anhos) and semana_temp between 1 and 15
group by semana_temp) st;


DROP TABLE IF EXISTS tmp_pivote_proy;
CREATE TABLE tmp_pivote_proy
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	PRIMARY KEY (id_fecha_vista, id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp)
);
INSERT INTO tmp_pivote_proy
SELECT pv.id_fecha_vista_ay AS id_fecha_vista, a.id_anho AS id_anho_uso, pv.id_hotel, pv.id_tipo_habitacion, pv.id_semana_temp
FROM tmp_pivote pv
CROSS JOIN lt_anhos a
GROUP BY pv.id_fecha_vista_ay, a.id_anho, pv.id_hotel, pv.id_tipo_habitacion, pv.id_semana_temp;


/*---------------------------------------------------------------------------------------------------------------
--                                              CONSTRUCCIÓN LYOUT                                             --
---------------------------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_lyout_temporada;
CREATE TABLE tmp_lyout_temporada
(
  id_fecha_vista_ay INT NOT NULL,
  id_anho_uso SMALLINT NOT NULL,
  id_semana_temp SMALLINT NOT NULL,
  ingreso_neto_lyout DOUBLE,
  nro_noches_cama_lyout DOUBLE,
  nro_habitaciones_ocupadas_lyout DOUBLE,
  PRIMARY KEY (id_fecha_vista_ay, id_anho_uso, id_semana_temp)
);
TRUNCATE TABLE tmp_lyout_temporada;
INSERT INTO tmp_lyout_temporada
SELECT r.id_fecha_vista, LEFT(f.id_fecha, 4) AS id_anho_uso, f.id_semana_temp, SUM(r.ingreso_neto) AS ingreso_neto_lyout, 
SUM(r.nro_noches_cama) AS nro_noches_cama_lyout, SUM(r.nro_habitaciones_ocupadas) AS nro_habitaciones_ocupadas_lyout
FROM ft_reservas r
INNER JOIN lt_fechas f
ON f.id_fecha = r.id_fecha_uso
WHERE r.id_fecha_vista = (SELECT MAX(id_fecha_vista) FROM ft_reservas_consolidadas)
GROUP BY r.id_fecha_vista, LEFT(f.id_fecha, 4), f.id_semana_temp;


DROP TABLE IF EXISTS tmp_lyout_anual;
CREATE TABLE tmp_lyout_anual
(
	id_fecha_vista_ay INT NOT NULL,
	id_anho_uso SMALLINT NOT NULL,
	ingreso_neto_lyout DOUBLE,
	nro_noches_cama_lyout DOUBLE,
	nro_habitaciones_ocupadas_lyout DOUBLE,
	PRIMARY KEY (id_fecha_vista_ay, id_anho_uso)
);
INSERT INTO tmp_lyout_anual
SELECT id_fecha_vista_ay, id_anho_uso, SUM(ingreso_neto_lyout) AS ingreso_neto_lyout, 
SUM(nro_noches_cama_lyout) AS nro_noches_cama_lyout, SUM(nro_habitaciones_ocupadas_lyout) AS nro_habitaciones_ocupadas_lyout
FROM tmp_lyout_temporada lt
WHERE EXISTS (SELECT 1 FROM tmp_semana_temporada WHERE id_semana_temp = lt.id_semana_temp)
GROUP BY id_fecha_vista_ay, id_anho_uso;


DROP TABLE IF EXISTS tmp_lyout;
CREATE TABLE tmp_lyout
(
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_habitaciones_ocupadas_lyout double DEFAULT NULL,
	ingreso_neto_lyout double DEFAULT NULL,
	nro_noches_cama_lyout double DEFAULT NULL,
	PRIMARY KEY (id_anho_uso, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp)
);
INSERT INTO tmp_lyout
SELECT r.id_anho_uso, r.id_pos, r.id_hotel, r.id_tipo_habitacion, r.id_nivel_tarifa, r.id_semana_temp,
SUM(r.nro_habitaciones_ocupadas) AS nro_nro_habitaciones_ocupadas_lyout,
SUM(r.ingreso_neto) AS ingreso_neto_lyout, SUM(r.nro_noches_cama) AS nro_noches_cama_lyout
FROM ft_reservas_consolidadas r
WHERE r.id_fecha_vista = (SELECT MAX(id_fecha_vista) FROM ft_reservas_consolidadas) 
AND EXISTS (SELECT 1 FROM tmp_semana_temporada WHERE id_semana_temp = r.id_semana_temp)
GROUP BY r.id_anho_uso, r.id_pos, r.id_hotel, r.id_tipo_habitacion, r.id_nivel_tarifa, r.id_semana_temp;


DROP TABLE IF EXISTS tmp_lyout_fp;
CREATE TABLE tmp_lyout_fp
(
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_habitaciones_ocupadas_lyout double DEFAULT NULL,
	ingreso_neto_lyout double DEFAULT NULL,
	nro_noches_cama_lyout double DEFAULT NULL,
	factor_habitaciones_ocupadas_lyout double DEFAULT NULL,
	PRIMARY KEY (id_anho_uso, id_pos, id_hotel, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp)
);
INSERT INTO tmp_lyout_fp
SELECT ly.id_anho_uso, ly.id_pos, ly.id_hotel, ly.id_tipo_habitacion, ly.id_nivel_tarifa, ly.id_semana_temp, 
ly.nro_habitaciones_ocupadas_lyout, ly.ingreso_neto_lyout, ly.nro_noches_cama_lyout, 
ly.nro_habitaciones_ocupadas_lyout / t.total_habitaciones_ocupadas_lyout AS factor_habitaciones_ocupadas_lyout
FROM tmp_lyout ly
INNER JOIN
(
	SELECT id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp, SUM(nro_habitaciones_ocupadas_lyout) AS total_habitaciones_ocupadas_lyout
	FROM tmp_lyout
	GROUP BY id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp
) t
ON t.id_anho_uso = ly.id_anho_uso AND t.id_hotel = ly.id_hotel AND t.id_tipo_habitacion = ly.id_tipo_habitacion AND t.id_semana_temp = ly.id_semana_temp;


/*---------------------------------------------------------------------------------------------------------------
--                                 CONSTRUCCIÓN FACTOR PRORRATEO PROYECCIONES                                  --
---------------------------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_proy_habitaciones_ocupadas_out;
CREATE TABLE tmp_proy_habitaciones_ocupadas_out
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	PRIMARY KEY (id_fecha_vista, id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp)
);
INSERT INTO tmp_proy_habitaciones_ocupadas_out
SELECT rc.id_fecha_vista, rc.id_anho_uso, rc.id_hotel, rc.id_tipo_habitacion, rc.id_semana_temp, SUM(rc.nro_habitaciones_ocupadas) AS nro_habitaciones_ocupadas
FROM ft_reservas_consolidadas rc
GROUP BY rc.id_fecha_vista, rc.id_anho_uso, rc.id_hotel, rc.id_tipo_habitacion, rc.id_semana_temp;


DROP TABLE IF EXISTS tmp_proy_habitaciones_ocupadas;
CREATE TABLE tmp_proy_habitaciones_ocupadas
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	delta_habitaciones_ocupadas double DEFAULT NULL,
	PRIMARY KEY (id_fecha_vista, id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp)
);
INSERT INTO tmp_proy_habitaciones_ocupadas
SELECT py.id_fecha_vista, py.id_anho_uso, py.id_hotel, py.id_tipo_habitacion, py.id_semana_temp, SUM(py.delta_habitaciones_ocupadas_proy) AS delta_habitaciones_ocupadas
FROM ft_proyecciones py
GROUP BY py.id_fecha_vista, py.id_anho_uso, py.id_hotel, py.id_tipo_habitacion, py.id_semana_temp;


DROP TABLE IF EXISTS tmp_proy_total_habitaciones_ocupadas;
CREATE TABLE tmp_proy_total_habitaciones_ocupadas
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	PRIMARY KEY (id_fecha_vista, id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp)
);
INSERT INTO tmp_proy_total_habitaciones_ocupadas
SELECT pv.id_fecha_vista, pv.id_anho_uso, pv.id_hotel, pv.id_tipo_habitacion, pv.id_semana_temp,
COALESCE(py.delta_habitaciones_ocupadas, 0) + COALESCE(rc.nro_habitaciones_ocupadas, 0)
FROM tmp_pivote_proy pv
LEFT JOIN tmp_proy_habitaciones_ocupadas py
ON py.id_fecha_vista = pv.id_fecha_vista AND py.id_anho_uso = pv.id_anho_uso AND py.id_hotel = pv.id_hotel 
AND py.id_tipo_habitacion = pv.id_tipo_habitacion AND py.id_semana_temp = pv.id_semana_temp
LEFT JOIN tmp_proy_habitaciones_ocupadas_out rc
ON rc.id_fecha_vista = pv.id_fecha_vista AND rc.id_anho_uso = pv.id_anho_uso AND rc.id_hotel = pv.id_hotel 
AND rc.id_tipo_habitacion = pv.id_tipo_habitacion AND rc.id_semana_temp = pv.id_semana_temp
WHERE py.delta_habitaciones_ocupadas IS NOT NULL OR rc.nro_habitaciones_ocupadas IS NOT NULL;


/*---------------------------------------------------------------------------------------------------------------
--                                         CONSTRUCCIÓN CUBO OVERVIEW                                          --
---------------------------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS ft_overview_tmp;
CREATE TABLE ft_overview_tmp
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    last_day_semana_temp int(11) not null,
	nro_habitaciones_ocupadas_ay double DEFAULT NULL,
	nro_noches_cama_ay double DEFAULT NULL,
	ingreso_neto_ay double DEFAULT NULL,
	factor_habitaciones_ocupadas_ay double DEFAULT NULL,
	nro_habitaciones_ocupadas_ly double DEFAULT NULL,
	nro_noches_cama_ly double DEFAULT NULL,
	ingreso_neto_ly double DEFAULT NULL,
	factor_habitaciones_ocupadas_ly double DEFAULT NULL,
    nro_habitaciones_ocupadas_lw double DEFAULT NULL,
	nro_noches_cama_lw double DEFAULT NULL,
	ingreso_neto_lw double DEFAULT NULL,
	factor_habitaciones_ocupadas_lw double DEFAULT NULL,
	nro_habitaciones_ocupadas_lyout double DEFAULT NULL,
	nro_noches_cama_lyout double DEFAULT NULL,
	ingreso_neto_lyout double DEFAULT NULL,
	factor_habitaciones_ocupadas_lyout double DEFAULT NULL,
--	nro_habitaciones_ocupadas_ppto double DEFAULT NULL,
	ppto_noche_cama double DEFAULT NULL,
	ppto_ingreso double DEFAULT NULL,
--	factor_habitaciones_ocupadas_ppto double DEFAULT NULL,
	nro_habitaciones_ocupadas_proy double DEFAULT NULL,
	nro_noches_cama_proy double DEFAULT NULL,
	ingreso_neto_proy double DEFAULT NULL,
	factor_habitaciones_ocupadas_proy double DEFAULT NULL,
    id_anticipacion smallint DEFAULT NULL
);
TRUNCATE TABLE ft_overview_tmp;
INSERT INTO ft_overview_tmp
SELECT pv.id_fecha_vista_ay, a.id_anho AS id_anho_uso, pv.id_pos, pv.id_hotel, pv.id_tipo_habitacion, pv.id_nivel_tarifa, pv.id_semana_temp, pv.last_day_semana_temp,
rc.nro_habitaciones_ocupadas AS nro_habitaciones_ocupadas_ay, 
rc.nro_noches_cama AS nro_noches_cama_ay, 
rc.ingreso_neto AS ingreso_neto_ay, 
rc.factor_habitaciones_ocupadas AS factor_habitaciones_ocupadas_ay,
rcly.nro_habitaciones_ocupadas AS nro_habitaciones_ocupadas_ly, 
rcly.nro_noches_cama AS nro_noches_cama_ly, 
rcly.ingreso_neto AS ingreso_neto_ly,
rcly.factor_habitaciones_ocupadas AS factor_habitaciones_ocupadas_ly,
rclw.nro_habitaciones_ocupadas AS nro_habitaciones_ocupadas_lw, 
rclw.nro_noches_cama AS nro_noches_cama_lw, 
rclw.ingreso_neto AS ingreso_neto_lw,
rclw.factor_habitaciones_ocupadas AS factor_habitaciones_ocupadas_lw,
ly.nro_habitaciones_ocupadas_lyout AS nro_habitaciones_ocupadas_lyout, 
ly.nro_noches_cama_lyout AS nro_noches_cama_lyout, 
ly.ingreso_neto_lyout AS ingreso_neto_lyout,
ly.factor_habitaciones_ocupadas_lyout AS factor_habitaciones_ocupadas_lyout,
-- p.nro_habitaciones_ocupadas AS nro_habitaciones_ocupadas_ppto, 
p.ppto_noche_cama,
p.ppto_ingreso,
-- p.factor_habitaciones_ocupadas AS factor_habitaciones_ocupadas_ppto,
COALESCE(rc.nro_habitaciones_ocupadas, 0) + COALESCE(py.delta_habitaciones_ocupadas_proy, 0) AS nro_habitaciones_ocupadas_proy,
COALESCE(rc.nro_noches_cama, 0) + COALESCE(py.delta_nro_noches_cama_proy, 0) AS nro_noches_cama_proy,
COALESCE(rc.ingreso_neto, 0) + COALESCE(py.delta_ingreso_neto_proy, 0) AS ingreso_proy,
(COALESCE(rc.nro_habitaciones_ocupadas, 0) + COALESCE(py.delta_habitaciones_ocupadas_proy, 0)) / NULLIF(tho.nro_habitaciones_ocupadas,0) AS factor_habitaciones_ocupadas_proy, pv.id_anticipacion
FROM tmp_pivote pv
CROSS JOIN lt_anhos a
LEFT JOIN ft_reservas_consolidadas_fp rc
ON rc.id_fecha_vista = pv.id_fecha_vista_ay AND rc.id_anho_uso = a.id_anho AND rc.id_pos = pv.id_pos AND rc.id_hotel = pv.id_hotel 
AND rc.id_tipo_habitacion = pv.id_tipo_habitacion AND rc.id_nivel_tarifa = pv.id_nivel_tarifa AND rc.id_semana_temp = pv.id_semana_temp
LEFT JOIN ft_reservas_consolidadas_fp rcly
ON rcly.id_fecha_vista = pv.id_fecha_vista_ly AND rcly.id_anho_uso = a.id_anho - 3 AND rcly.id_pos = pv.id_pos AND rcly.id_hotel = pv.id_hotel 
AND rcly.id_tipo_habitacion = pv.id_tipo_habitacion AND rcly.id_nivel_tarifa = pv.id_nivel_tarifa AND rcly.id_semana_temp = pv.id_semana_temp
LEFT JOIN ft_reservas_consolidadas_fp rclw
ON rclw.id_fecha_vista = pv.id_fecha_vista_lw AND rclw.id_anho_uso = a.id_anho AND rclw.id_pos = pv.id_pos AND rclw.id_hotel = pv.id_hotel 
AND rclw.id_tipo_habitacion = pv.id_tipo_habitacion AND rclw.id_nivel_tarifa = pv.id_nivel_tarifa AND rclw.id_semana_temp = pv.id_semana_temp
LEFT JOIN tmp_lyout_fp ly
ON ly.id_anho_uso = a.id_anho - 3 AND ly.id_pos = pv.id_pos AND ly.id_hotel = pv.id_hotel AND ly.id_tipo_habitacion = pv.id_tipo_habitacion AND ly.id_nivel_tarifa = pv.id_nivel_tarifa AND ly.id_semana_temp = pv.id_semana_temp
-- LEFT JOIN ft_presupuestos_fp p
LEFT JOIN ft_presupuestos p
ON p.id_anho_ppto = a.id_anho AND p.id_pos = pv.id_pos AND p.id_hotel = pv.id_hotel AND p.id_tipo_habitacion = pv.id_tipo_habitacion
AND p.id_nivel_tarifa = pv.id_nivel_tarifa AND p.id_semana_temp = pv.id_semana_temp
LEFT JOIN ft_proyecciones py
ON py.id_fecha_vista = pv.id_fecha_vista_ay AND py.id_anho_uso = a.id_anho AND py.id_pos = pv.id_pos AND py.id_hotel = pv.id_hotel 
AND py.id_tipo_habitacion = pv.id_tipo_habitacion AND py.id_nivel_tarifa = pv.id_nivel_tarifa AND py.id_semana_temp = pv.id_semana_temp
LEFT JOIN tmp_proy_total_habitaciones_ocupadas tho
ON pv.id_fecha_vista_ay = tho.id_fecha_vista AND a.id_anho = tho.id_anho_uso AND pv.id_hotel = tho.id_hotel 
AND pv.id_tipo_habitacion = tho.id_tipo_habitacion AND pv.id_semana_temp = tho.id_semana_temp
WHERE rc.nro_habitaciones_ocupadas IS NOT NULL OR rc.nro_noches_cama IS NOT NULL OR rc.ingreso_neto IS NOT NULL 
OR rcly.nro_habitaciones_ocupadas IS NOT NULL OR rcly.nro_noches_cama IS NOT NULL OR rcly.ingreso_neto IS NOT NULL
OR rclw.nro_habitaciones_ocupadas IS NOT NULL OR rclw.nro_noches_cama IS NOT NULL OR rclw.ingreso_neto IS NOT NULL
OR ly.nro_habitaciones_ocupadas_lyout IS NOT NULL OR ly.nro_noches_cama_lyout IS NOT NULL OR ly.ingreso_neto_lyout IS NOT NULL
/*OR p.nro_habitaciones_ocupadas IS NOT NULL */ OR p.ppto_noche_cama IS NOT NULL OR p.ppto_ingreso IS NOT NULL
OR py.delta_habitaciones_ocupadas_proy OR py.delta_nro_noches_cama_proy IS NOT NULL OR py.delta_ingreso_neto_proy IS NOT NULL;

/* Establece que la proyección sea el presupuesto si faltan más de 25 semanas */

update ft_overview_tmp
set nro_noches_cama_proy=ppto_noche_cama where id_anticipacion<-25;

update ft_overview_tmp
set ingreso_neto_proy=ppto_ingreso where id_anticipacion<-25;

DROP TABLE IF EXISTS ft_overview;
CREATE TABLE ft_overview
(
	id_vista char(5) NOT NULL,
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_habitacion smallint(6) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    id_anticipacion smallint not null default 0,
    last_day_semana_temp int(11) not null default 0,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	nro_noches_cama double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
	total_habitaciones double DEFAULT NULL,
	PRIMARY KEY (id_vista, id_fecha_vista, id_anho_uso, id_pos, id_habitacion, id_nivel_tarifa, id_semana_temp)
);
INSERT INTO ft_overview
SELECT 'AY' AS id_vista, ot.id_fecha_vista, ot.id_anho_uso, ot.id_pos, h.id_habitacion, ot.id_nivel_tarifa, ot.id_semana_temp, ot.id_anticipacion, ot.last_day_semana_temp,
ot.nro_habitaciones_ocupadas_ay, ot.nro_noches_cama_ay, ot.ingreso_neto_ay, (h.nro_habitaciones * 7 * ot.factor_habitaciones_ocupadas_ay) AS total_habitaciones
FROM ft_overview_tmp ot
INNER JOIN lt_habitaciones h
ON h.id_hotel = ot.id_hotel and h.id_tipo_habitacion = ot.id_tipo_habitacion
WHERE nro_habitaciones_ocupadas_ay IS NOT NULL OR nro_noches_cama_ay IS NOT NULL OR ingreso_neto_ay IS NOT NULL
UNION ALL
SELECT 'LY' AS id_vista, ot.id_fecha_vista, ot.id_anho_uso, ot.id_pos, h.id_habitacion, ot.id_nivel_tarifa, ot.id_semana_temp, ot.id_anticipacion, ot.last_day_semana_temp,
ot.nro_habitaciones_ocupadas_ly, ot.nro_noches_cama_ly, ot.ingreso_neto_ly, (h.nro_habitaciones * 7 * ot.factor_habitaciones_ocupadas_ly) AS total_habitaciones
FROM ft_overview_tmp ot
INNER JOIN lt_habitaciones h
ON h.id_hotel = ot.id_hotel and h.id_tipo_habitacion = ot.id_tipo_habitacion
WHERE nro_habitaciones_ocupadas_ly IS NOT NULL OR nro_noches_cama_ly IS NOT NULL OR ingreso_neto_ly IS NOT NULL
UNION ALL
SELECT 'LW' AS id_vista, ot.id_fecha_vista, ot.id_anho_uso, ot.id_pos, h.id_habitacion, ot.id_nivel_tarifa, ot.id_semana_temp, ot.id_anticipacion, ot.last_day_semana_temp, 
ot.nro_habitaciones_ocupadas_lw, ot.nro_noches_cama_lw, ot.ingreso_neto_lw, (h.nro_habitaciones * 7 * ot.factor_habitaciones_ocupadas_lw) AS total_habitaciones
FROM ft_overview_tmp ot
INNER JOIN lt_habitaciones h
ON h.id_hotel = ot.id_hotel and h.id_tipo_habitacion = ot.id_tipo_habitacion
WHERE nro_habitaciones_ocupadas_lw IS NOT NULL OR nro_noches_cama_lw IS NOT NULL OR ingreso_neto_lw IS NOT NULL
UNION ALL
SELECT 'LYOUT' AS id_vista, ot.id_fecha_vista, ot.id_anho_uso, ot.id_pos, h.id_habitacion, ot.id_nivel_tarifa, ot.id_semana_temp, ot.id_anticipacion, ot.last_day_semana_temp,
ot.nro_habitaciones_ocupadas_lyout, ot.nro_noches_cama_lyout, ot.ingreso_neto_lyout, (h.nro_habitaciones * 7 * ot.factor_habitaciones_ocupadas_lyout) AS total_habitaciones
FROM ft_overview_tmp ot
INNER JOIN lt_habitaciones h
ON h.id_hotel = ot.id_hotel and h.id_tipo_habitacion = ot.id_tipo_habitacion
WHERE nro_habitaciones_ocupadas_lyout IS NOT NULL OR nro_noches_cama_lyout IS NOT NULL OR ingreso_neto_lyout IS NOT NULL
UNION ALL
SELECT 'PPTO' AS id_vista, ot.id_fecha_vista, ot.id_anho_uso, ot.id_pos, h.id_habitacion, ot.id_nivel_tarifa, ot.id_semana_temp, ot.id_anticipacion, ot.last_day_semana_temp,
/* ot.nro_habitaciones_ocupadas_ppto, */ NULL AS nro_habitaciones_ocupadas_ppto, ot.ppto_noche_cama, ot.ppto_ingreso, 
/*(h.nro_habitaciones * 7 * ot.factor_habitaciones_ocupadas_ppto)*/ NULL AS total_habitaciones
FROM ft_overview_tmp ot
INNER JOIN lt_habitaciones h
ON h.id_hotel = ot.id_hotel and h.id_tipo_habitacion = ot.id_tipo_habitacion
WHERE /* nro_habitaciones_ocupadas_ppto IS NOT NULL OR */ ot.ppto_noche_cama IS NOT NULL OR ot.ppto_ingreso IS NOT NULL
UNION ALL
SELECT 'PROY' AS id_vista, ot.id_fecha_vista, ot.id_anho_uso, ot.id_pos, h.id_habitacion, ot.id_nivel_tarifa, ot.id_semana_temp, ot.id_anticipacion, ot.last_day_semana_temp,
ot.nro_habitaciones_ocupadas_proy, ot.nro_noches_cama_proy, ot.ingreso_neto_proy, (h.nro_habitaciones * 7 * ot.factor_habitaciones_ocupadas_proy) AS total_habitaciones
FROM ft_overview_tmp ot
INNER JOIN lt_habitaciones h
ON h.id_hotel = ot.id_hotel and h.id_tipo_habitacion = ot.id_tipo_habitacion
WHERE nro_habitaciones_ocupadas_ay > 0 OR nro_noches_cama_proy > 0 OR ingreso_neto_proy > 0;


DROP TABLE IF EXISTS lt_fecha_vista_actual;
CREATE TABLE lt_fecha_vista_actual
(
	id_anho_uso SMALLINT(6),
	id_anho_uso_actual SMALLINT(6),
	dsc_fecha_vista_actual DATE,
	PRIMARY KEY (id_anho_uso)
);
INSERT INTO lt_fecha_vista_actual
SELECT fo.id_anho_uso, a.id_anho_uso_actual, MAX(fo.id_fecha_vista) AS dsc_fecha_vista_actual
FROM ft_overview fo
INNER JOIN 
(
	SELECT MAX(id_anho) AS id_anho_uso_actual
	FROM lt_anhos
) a
WHERE fo.id_vista = 'AY'
GROUP BY fo.id_anho_uso, a.id_anho_uso_actual;


/*---------------------------------------------------------------------------------------------------------------
--                                          CONSTRUCCION CUBO POR DIA                                           --
---------------------------------------------------------------------------------------------------------------*/

/* ft_reservas_1: Es la version de ft_reservas pero desde final_final_last_diario */

DROP TABLE IF EXISTS ft_reservas_1;
CREATE TABLE ft_reservas_1
(
	id_fecha_vista int NOT NULL,
	id_fecha_uso int NOT NULL,
	id_agencia smallint NOT NULL,
	id_habitacion smallint NOT NULL,
	id_nacionalidad smallint NOT NULL,
	id_nacionalidad_gestion smallint NOT NULL,
	id_tarifa int NOT NULL,
	id_nivel_tarifa int NOT NULL,
	id_anticipacion smallint NOT NULL,
	nro_adultos double,
	nro_adolescentes double,
	nro_ninhos double,
	nro_infantes double,
	nro_noches_cama double,
	nro_habitaciones_ocupadas double,
	nro_total_mas_infantes double,
	nro_total_sin_infantes double,
	ingreso_neto double,
	PRIMARY KEY (id_fecha_vista, id_fecha_uso, id_agencia, id_habitacion, id_nacionalidad, id_nacionalidad_gestion, id_tarifa, id_nivel_tarifa, id_anticipacion)
);
INSERT INTO ft_reservas_1
SELECT ffl.fecha_vista, ffl.fecha_uso, a.id_agencia , hb.id_habitacion, n.id_nacionalidad, p.id_pos, t.id_tarifa, nt.id_nivel_tarifa,
ffl.anticipacion, SUM(dadult) AS dadult, SUM(dteen) AS dteen, SUM(dninos) AS dninos, SUM(dinfantes) AS dinfantes, SUM(noches_cama) AS noches_cama,
SUM(habitaciones_noches) AS habitaciones_noches, SUM(dadult + dteen + dninos + dinfantes) AS nro_total_mas_infantes,
SUM(dadult + dteen + dninos) AS nro_total_sin_infantes, SUM(ingreso_neto) AS ingreso_neto
FROM final_final_last_diario ffl
INNER JOIN lt_agencias a
ON a.cdg_agencia = CASE WHEN LEFT(TRIM(REPLACE(ffl.dagenc, ',', '')), 3) = '' THEN '---' ELSE LEFT(TRIM(REPLACE(ffl.dagenc, ',', '')), 3) END
AND a.id_canal_reserva = CASE 
WHEN ffl.early <> 0 THEN 2
WHEN ffl.ibe <> 0 THEN 3
WHEN ffl.itau <> 0 THEN 4
WHEN ffl.directo <> 0 THEN 1
ELSE 0
END
INNER JOIN lt_hoteles h
ON h.cdg_hotel = ffl.hotel
INNER JOIN lt_tipo_habitacion th
ON th.cdg_tipo_habitacion = ffl.tipohabrm
INNER JOIN lt_habitaciones hb
ON hb.id_hotel = h.id_hotel AND hb.id_tipo_habitacion = th.id_tipo_habitacion
INNER JOIN lt_nacionalidades n
ON n.cdg_nacionalidad = ffl.dnacio
INNER JOIN lt_pos p
ON p.cdg_pos = CASE WHEN ffl.nacionalidad_gestion IN ('ARG', 'CHI', 'USA', 'BRA', 'SKT') THEN ffl.nacionalidad_gestion ELSE 'OTH' END
INNER JOIN lt_tarifas t
ON t.cdg_tarifa = CASE WHEN LEFT(TRIM(REPLACE(ffl.dtaras, ',', '')), 3) = '' THEN '---' ELSE LEFT(TRIM(REPLACE(ffl.dtaras, ',', '')), 3) END
INNER JOIN lt_nivel_tarifa nt
ON nt.cdg_nivel_tarifa = CASE WHEN ffl.nivel = '' OR ffl.nivel IS NULL THEN '--' ELSE ffl.nivel END
GROUP BY ffl.fecha_vista, ffl.fecha_uso, a.id_agencia , hb.id_habitacion, n.id_nacionalidad, p.id_pos, t.id_tarifa, nt.id_nivel_tarifa, ffl.anticipacion;




/* ft_reservas_consolidadas: Contiene información agregada de reservas disponibles el origen de datos */
DROP TABLE IF EXISTS ft_reservas_diarias_aux0;
CREATE TABLE ft_reservas_diarias_aux0
(
	id_fecha_vista int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
    id_habitacion tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    id_dow smallint NOT NULL,
    id_fecha_uso int(11) NOT NULL,
	nro_noches_cama double DEFAULT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
	PRIMARY KEY (id_fecha_vista, id_anho_uso, id_pos, id_hotel, id_habitacion, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp, id_dow)
);
INSERT INTO ft_reservas_diarias_aux0
SELECT r.id_fecha_vista, f.id_anho AS id_anho_uso, r.id_nacionalidad_gestion AS id_pos, h.id_hotel, h.id_habitacion, h.id_tipo_habitacion, r.id_nivel_tarifa, f.id_semana_temp, f.dow, r.id_fecha_uso,
SUM(r.nro_noches_cama) AS nro_noches_cama, SUM(r.nro_habitaciones_ocupadas) AS nro_habitaciones_ocupadas, SUM(r.ingreso_neto) AS ingreso_neto
FROM ft_reservas_1 r
INNER JOIN lt_habitaciones h
ON h.id_habitacion = r.id_habitacion
INNER JOIN lt_fechas f
ON f.id_fecha = r.id_fecha_uso
WHERE EXISTS (SELECT 1 FROM tmp_semana_temporada WHERE id_semana_temp = f.id_semana_temp)
GROUP BY r.id_fecha_vista, f.id_anho, r.id_nacionalidad_gestion, h.id_hotel, h.id_habitacion, h.id_tipo_habitacion, r.id_nivel_tarifa, f.id_semana_temp, f.dow, r.id_fecha_uso;


DROP TABLE IF EXISTS ft_reservas_diarias_aux1;
CREATE TABLE ft_reservas_diarias_aux1
(
	id_fecha_vista_ay int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_pos smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
    id_habitacion tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_nivel_tarifa int(11) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    id_dow smallint NOT NULL,
    id_fecha_uso int(11) NOT NULL,
	nro_noches_cama double DEFAULT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
    id_fecha_vista_ly int(11) NOT NULL,
    id_fecha_vista_lw int(11) NOT NULL,
	PRIMARY KEY (id_fecha_vista_ay, id_anho_uso, id_pos, id_hotel, id_habitacion, id_tipo_habitacion, id_nivel_tarifa, id_semana_temp, id_dow)
);
INSERT INTO ft_reservas_diarias_aux1
SELECT r.*, f.id_fecha_vista_ly, f.id_fecha_vista_lw
from ft_reservas_diarias_aux0 r
inner join valle_diccionario.tmp_fecha_vista_ay_ly_lw f
on r.id_fecha_vista= f.id_fecha_vista_ay;


DROP TABLE IF EXISTS ft_reservas_diarias_aux2;
CREATE TABLE ft_reservas_diarias_aux2
(
	id_fecha_vista_ay int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
    id_habitacion tinyint(4) NOT NULL,
    id_tipo_habitacion tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    id_dow smallint NOT NULL,
    id_fecha_uso int(11) NOT NULL,
	nro_noches_cama double DEFAULT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
    id_fecha_vista_ly int(11) NOT NULL,
    id_fecha_vista_lw int(11) NOT NULL,
	PRIMARY KEY (id_fecha_vista_ay, id_anho_uso, id_hotel, id_habitacion, id_semana_temp, id_dow, id_fecha_uso)
);
INSERT INTO ft_reservas_diarias_aux2
SELECT id_fecha_vista_ay, id_anho_uso, id_hotel, id_habitacion, id_tipo_habitacion, id_semana_temp, id_dow, id_fecha_uso, sum(nro_noches_cama), sum(nro_habitaciones_ocupadas), sum(ingreso_neto), id_fecha_vista_ly, id_fecha_vista_lw
from ft_reservas_diarias_aux1
group by id_fecha_vista_ay, id_anho_uso, id_hotel, id_habitacion, id_tipo_habitacion, id_semana_temp, id_dow, id_fecha_uso, id_fecha_vista_ly, id_fecha_vista_lw;


/* Se debe generar un pivote ya que hay combinaciones de fecha_vista-habitacion-fecha-uso sin reservas pero con dispo*/

DROP TABLE IF EXISTS tmp_pivote_dow;
CREATE TABLE tmp_pivote_dow
(
	id_fecha_vista_ay int(11) NOT NULL,
    id_anho_uso smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
    id_habitacion tinyint(4) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    id_dow smallint(6) not null,
    id_fecha_uso int(11) NOT NULL,
    id_fecha_vista_ly int(11) NOT NULL,
    id_fecha_vista_lw int(11) NOT NULL,
    id_anticipacion smallint not null,
    primary key (id_fecha_vista_ay, id_anho_uso, id_hotel, id_habitacion, id_semana_temp, id_dow, id_fecha_uso)
);
TRUNCATE TABLE tmp_pivote_dow;
INSERT INTO tmp_pivote_dow
SELECT distinct r.id_fecha_vista_ay, r.id_anho_uso, h.id_hotel, hb.id_habitacion, th.id_tipo_habitacion,  f.id_semana_temp, f.dow, f.id_fecha, r.id_fecha_vista_ly, r.id_fecha_vista_lw, ceiling(datediff(r.id_fecha_vista_ay,f.id_fecha)/7) as anticipacion
FROM (select distinct id_fecha_vista_ay, id_anho_uso, id_fecha_vista_ly, id_fecha_vista_lw from ft_reservas_diarias_aux2) r
CROSS JOIN lt_hoteles h
INNER JOIN lt_habitaciones hb
ON hb.id_hotel = h.id_hotel
INNER JOIN lt_tipo_habitacion th
ON th.id_tipo_habitacion = hb.id_tipo_habitacion
CROSS JOIN (SELECT * FROM lt_fechas WHERE id_semana_temp between 1 and 15) f
on f.id_anho= r.id_anho_uso;


DROP TABLE IF EXISTS ft_reservas_diarias;
CREATE TABLE ft_reservas_diarias
(
	id_fecha_vista_ay int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
    id_habitacion tinyint(4) NOT NULL,
    id_tipo_habitacion tinyint(4) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    id_dow smallint NOT NULL,
    id_fecha_uso int(11) NOT NULL,
    id_anticipacion smallint not null,
	nro_noches_cama double DEFAULT NULL,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
    id_fecha_vista_ly int(11) NOT NULL,
    id_fecha_vista_lw int(11) NOT NULL,
	PRIMARY KEY (id_fecha_vista_ay, id_anho_uso, id_hotel, id_habitacion, id_tipo_habitacion, id_semana_temp, id_dow, id_fecha_uso)
);
INSERT INTO ft_reservas_diarias
SELECT pv.id_fecha_vista_ay, pv.id_anho_uso, pv.id_hotel, pv.id_habitacion, pv.id_tipo_habitacion, pv.id_semana_temp, pv.id_dow, pv.id_fecha_uso, pv.id_anticipacion, r.nro_noches_cama, r.nro_habitaciones_ocupadas, r.ingreso_neto, pv.id_fecha_vista_ly, pv.id_fecha_vista_lw
from tmp_pivote_dow pv
left join ft_reservas_diarias_aux2 r
on pv.id_fecha_vista_ay=r.id_fecha_vista_ay
and pv.id_anho_uso=r.id_anho_uso
and pv.id_hotel=r.id_hotel 
and pv.id_habitacion=r.id_habitacion 
and pv.id_semana_temp=r.id_semana_temp 
and  pv.id_dow=r.id_dow
and pv.id_fecha_uso=r.id_fecha_uso;


update ft_reservas_diarias
set nro_noches_cama=0 where nro_noches_cama is null;

update ft_reservas_diarias
set nro_habitaciones_ocupadas=0 where nro_habitaciones_ocupadas is null;

update ft_reservas_diarias
set ingreso_neto=0 where ingreso_neto is null;


/* Se crea el cubo ft_capacity para hacer la gestión de capacidad */

/* En esta etapa el cubo capacity estará por hotel, tipo habitacion y semana */

drop table if exists tmp_pivote_capacity;
create table tmp_pivote_capacity
(
	id_fecha_vista_ay int(11) NOT NULL,
    id_anho_uso smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
    cdg_hotel char(3) NOT NULL,
	id_tipo_habitacion tinyint(4) NOT NULL,
	cdg_tipo_habitacion char(15) NOT NULL,
    id_habitacion tinyint(4) NOT NULL,
    id_semana_temp smallint(6) NOT NULL,
    id_fecha_vista_ly int(11) NOT NULL,
    id_fecha_vista_lw int(11) NOT NULL,
    id_anticipacion smallint not null,
    primary key (id_fecha_vista_ay, id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp, id_anticipacion),
    key (cdg_hotel, cdg_tipo_habitacion, id_semana_temp, id_anticipacion)
);
TRUNCATE TABLE tmp_pivote_capacity;
INSERT INTO tmp_pivote_capacity
select distinct pv.id_fecha_vista_ay, pv.id_anho_uso, pv.id_hotel, h.cdg_hotel, pv.id_tipo_habitacion, th.cdg_tipo_habitacion, pv.id_habitacion, pv.id_semana_temp, pv.id_fecha_vista_ly, pv.id_fecha_vista_lw, pv.id_anticipacion
from tmp_pivote_dow pv
inner join lt_tipo_habitacion th
on pv.id_tipo_habitacion=th.id_tipo_habitacion
inner join lt_hoteles h
on pv.id_hotel=h.id_hotel;

drop table if exists ft_at95;
create table ft_at95
(
	id_fecha_vista_ay int(11) NOT NULL,
    id_anho_uso smallint(6) NOT NULL,
	id_hotel tinyint(4) NOT NULL,
	cdg_hotel char(3) NOT NULL,
    id_tipo_habitacion tinyint(4) NOT NULL,
	cdg_tipo_habitacion char(15) NOT NULL,
	id_habitacion tinyint(4) NOT NULL,
    id_semana_temp smallint(6) NOT NULL,
    id_fecha_vista_ly int(11) NOT NULL,
    id_fecha_vista_lw int(11) NOT NULL,
    id_anticipacion smallint not null,
    ho_at95 int,
    nc_at95 int,
    primary key (id_fecha_vista_ay, id_anho_uso, id_hotel, id_tipo_habitacion, id_semana_temp, id_anticipacion)
);
TRUNCATE TABLE ft_at95;
INSERT INTO ft_at95
select pv.*, a.ho_at95, a.nc_at95
from tmp_pivote_capacity pv
left join valle_diccionario.base_at95 a
on pv.cdg_hotel=a.hotel
and pv.cdg_tipo_habitacion = a.tipohabrm
and pv.id_semana_temp= a.semana_temp
and pv.id_anticipacion= a.anticipacion;

 
DROP TABLE IF EXISTS ft_capacity;
CREATE TABLE ft_capacity
(
	id_vista char(5) NOT NULL,
	id_fecha_vista_ay int(11) NOT NULL,
	id_anho_uso smallint(6) NOT NULL,
	id_habitacion smallint(6) NOT NULL,
	id_semana_temp smallint(6) NOT NULL,
    id_anticipacion smallint(6) not null,
	nro_habitaciones_ocupadas double DEFAULT NULL,
	nro_noches_cama double DEFAULT NULL,
	ingreso_neto double DEFAULT NULL,
	total_habitaciones double DEFAULT NULL,
	PRIMARY KEY (id_vista, id_fecha_vista_ay, id_anho_uso, id_habitacion, id_semana_temp)
);
INSERT INTO ft_capacity
select id_vista, id_fecha_vista, id_anho_uso, id_habitacion, id_semana_temp,id_anticipacion, sum(nro_habitaciones_ocupadas) as ho, sum(nro_noches_cama) as nc, sum(ingreso_neto) as ia, sum(total_habitaciones) as th
from ft_overview
group by id_vista, id_fecha_vista, id_anho_uso, id_habitacion, id_semana_temp, id_anticipacion
UNION
select 'AT95', id_fecha_vista_ay, id_anho_uso, id_habitacion, id_semana_temp, id_anticipacion, ho_at95,nc_at95,0,0
from ft_at95;

delete from ft_overview where id_anho_uso<>'2022';

insert into ft_overview (id_vista,id_fecha_vista,id_anho_uso,id_pos,id_habitacion,id_nivel_tarifa,id_semana_temp, nro_habitaciones_ocupadas,nro_noches_cama,ingreso_neto,total_habitaciones)

select 'Y2018' as id_vista,date_format(str_to_date(df.fecha, '%Y-%m-%d'),'%Y%m%d') as fecha, f18.id_anho_uso,f18.id_pos,f18.id_habitacion,f18.id_nivel_tarifa,f18.id_semana_temp, f18.nro_habitaciones_ocupadas,f18.nro_noches_cama,f18.ingreso_neto,f18.total_habitaciones

from

Valle_RM_20180921.ft_overview f18 inner join valle_diccionario.dic_fechas_llly df on date_format(str_to_date(df.fecha_lly, '%Y-%m-%d'),'%Y%m%d')=f18.id_fecha_vista and f18.id_vista='AY' and id_anho_uso='2018';

update ft_overview set id_anho_uso='2022' where id_vista in ('Y2018');

delete from ft_overview where id_fecha_vista<'20180101';

analyze table `ft_overview`;