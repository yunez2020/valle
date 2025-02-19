/* Este script permite importar el presupuesto en formato csv 
a la tabla ppto_original_excel */

truncate ppto_original_excel;

LOAD DATA LOCAL INFILE 
'C:/Users/luism/Dropbox/My Documents/Efficientis/VN/VN/PPTO 2025 hoteles.csv' 
INTO TABLE ppto_original_excel
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;