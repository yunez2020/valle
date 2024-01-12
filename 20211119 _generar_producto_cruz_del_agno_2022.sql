/* Este script se debe ejecutar en valle_diccionario para generar un producto_cruz de la temporada que se analiza*/

DROP TABLE IF EXISTS aux_fecha_vista;
CREATE TABLE aux_fecha_vista SELECT id_fecha_vista_ay as fecha_vista 
FROM tmp_fecha_vista_ay_ly_lw 
WHERE id_fecha_vista_ay>='20211112' AND id_fecha_vista_ay<='20221230';

DROP TABLE IF EXISTS aux_semana_temp;
CREATE TABLE aux_semana_temp 
SELECT fecha_uso, semana_temp 
FROM semanas
WHERE dia_semana=5 AND semana_temp>0 AND semana_temp<=15 AND substring(fecha_uso,1,4)='2022';

DROP TABLE IF EXISTS aux_fechas_p_cruz;
CREATE TABLE aux_fechas_p_cruz 
SELECT fecha_vista,fecha_uso,semana_temp,ceiling(datediff(fecha_vista,fecha_uso)/7) AS anticipacion 
FROM aux_fecha_vista,aux_semana_temp;

DROP TABLE IF EXISTS aux_rooms_p_cruz;
CREATE TABLE aux_rooms_p_cruz 
SELECT DISTINCT tipohabrm,hotel,pos 
FROM producto_cruz;

DROP TABLE IF EXISTS producto_cruz_2017;
CREATE TABLE producto_cruz_2017 
SELECT substring(fecha_uso,1,4) AS agno,anticipacion,semana_temp,fecha_vista,tipohabrm,hotel,pos 
FROM aux_fechas_p_cruz,aux_rooms_p_cruz;

DROP TABLE IF EXISTS aux_fecha_vista;
DROP TABLE IF EXISTS aux_semana_temp;
DROP TABLE IF EXISTS aux_fechas_p_cruz;
DROP TABLE IF EXISTS aux_rooms_p_cruz;

DROP TABLE IF EXISTS producto_cruz;
CREATE TABLE producto_cruz
SELECT * from valle_diccionario.producto_cruz_2017;

