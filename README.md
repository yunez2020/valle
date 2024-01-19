En este repositorio se mantiene el código del BI de Valle Nevado
Semanalmente se realiza una actualización en que...




Al comenzar un nuevo año, hay que realizar el siguiente proceso
1) Respaldar el año previo haciendo un dump del Valle_RM_Actual en un Schema Valle_RM_YYYYMMDD donde YYYYMMDD es la última fecha_vista procesada del año previo
   Primero en la linea de comando de linux se hace un mysqldump a un archivo sql. Una vez hecho esto, se hace un mysql al nuevo schema. Finalmente se comprime el archivo sql a un tgz con el comando tar.
   Se recomienda estar en el directorio /valle_backup para ejecutar estos comandos sin escribir todo el PATH 
   >mysqldump -u admin -p -h valle.mysql.simplermp.com Valle_RM_actual > YYYYMMDD_valle_backup.sql y va a pedir el password del admin de RDS
   >mysql -u admin -p -h valle.mysql.simplermp.com Valle_RM_YYYMMDD < YYYYMMDD_valle_backup.sql
   >tar YYYYMMDD_valle_backup.tgz YYYYMMDD_valle_backup.sql
   Finalmente se sugiere eliminar el archivo YYYYMMDD_valle_backup.sql dado que está como TGZ respaldado y comprimido

2) Cargar el presupuesto del año en curso. Esto se hace en el schema valle_diccionario.
   Para esto hay que primero asegurarse que la tabla ppto_original_excel que viene del año anterior se renombre ppto_original_excel_AAAA donde AAAA es el año de ese presupuesto.
   Luego, hay que cargar el excel del presupuesto en una nueva tabla ppto_original_excel en el schema valle_diccionario.
   La tabla ppto_original_excel tiene 5 columnas: hotel varchar(3) PK, semana_temp integer PK, pos varchar(3) PK, ppto_nc decimal(65,30), ppto_ingreso decimal(65,30) 
   Lo único que se debe actualizar del código genera_apertura_presupuesto.sql es cambiar el valor año del select que está en el insert into presupuesto.
   También hay que asegurarse que estén las tablas [capacidad] y [dic_niveles] en valle_diccionario que en teoría no cambian año a año
   Se ejecuta genera_apertura_presupuesto.sql en el schema valle_diccionario y queda una tabla [presupuesto] en valle_diccionario.

3) El siguiente paso es generar el producto_cruz de hoteles, semanas, paises, habitaciones, niveles del año en curso. 
   
    

   
