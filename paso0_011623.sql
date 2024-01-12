drop table if exists opfho;
CREATE TABLE opfho like valle_lastview.opfho;
INSERT INTO opfho 
SELECT * FROM valle_lastview.opfho;

drop table if exists opdat;
CREATE TABLE opdat like valle_lastview.opdat;
INSERT INTO opdat 
SELECT * FROM valle_lastview.opdat;

UPDATE opdat SET dninos=0 WHERE dninos IS NULL;
UPDATE opdat SET dadult=0 WHERE dadult IS NULL;
UPDATE opdat SET dteen=0 WHERE dteen IS NULL;
UPDATE opdat SET dinfantes=0 WHERE dinfantes IS NULL;
UPDATE opdat SET dtarifa=0 WHERE dtarifa IS NULL;
UPDATE opdat SET dagecom=0 WHERE dagecom IS NULL;
UPDATE opdat SET descuento=0 WHERE descuento IS NULL;

ALTER TABLE `opdat` 
CHANGE COLUMN `DFECREA` `DFECREA` VARCHAR(8) NULL DEFAULT NULL ;

ALTER TABLE `opfho` 
CHANGE COLUMN `LFECHA` `LFECHA` VARCHAR(8) NULL DEFAULT NULL ;


DELETE FROM opdat WHERE dnorsv='1804379';
DELETE FROM opdat WHERE dnorsv='1800326';
DELETE FROM opdat WHERE dnorsv='1900304';
DELETE FROM opdat WHERE dnorsv='1900305';

DROP TABLE IF EXISTS opdat_ocupa;
DROP TABLE IF EXISTS opdat_ocupa_aux;
CREATE TABLE opdat_ocupa_aux 
SELECT w.*,y.Esbase,y.Nivel, y.hotel,y.TipoHabRM,y.TipoHabCRM FROM (SELECT * FROM opdat WHERE opdat.dflleg>'20171231' AND opdat.dnorsv IS NOT null) w LEFT JOIN codigo_ocupa y
ON (w.DTARAS=y.CodHW AND substring(w.dflleg,1,4)=y.agno);


SELECT dnorsv,dtaras,dnombr,dtarifa,dflleg, dmotiv, dtapor, docupa FROM opdat_ocupa_aux WHERE ISNULL(Esbase) AND dflleg>'20190530' AND dtaras IS NOT NULL;
/* aquí se revisa */
