#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Nov 18 10:30:03 2019

@author: ierbetta
"""
#encabezado anterior siempre viene con script

#librerias
import os
import time
import datetime
import pandas as pd
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from dateutil.relativedelta import relativedelta, FR
#librerias

#--------- Envio de mail avisando que comenzo el proceso
me="analytics@efficientis.net"
my_password = r"GA_analytics2019"
#TO = ["ignacio.erbetta@deltapricing.com"]
TO = ["nazmy.yunez@gmail.com","luis.moreno@efficientis.net"]
#,"nazmy@deltapricing.com","jsarmiento@transoceanica.cl","vholzapfel@transoceanica.cl","aramirez@transoceanica.cl"


msg = MIMEMultipart('alternative')

msg['From'] = me
msg['Subject'] = "Proceso de Carga ValleNevado"

html = """\
        <html>
          <head></head>
          <body>
            Comienza el traspaso de opdat opfho y optar.
          </body>
        </html>
        """
part2 = MIMEText(html, 'html')
        
msg.attach(part2)
        
        # Send the message via gmail's regular server, over SSL - passwords are being sent, afterall
s = smtplib.SMTP_SSL('smtp.gmail.com')
        # uncomment if interested in the actual smtp conversation
        # s.set_debuglevel(1)
        # do the smtp auth; sends ehlo if it hasn't been sent already
s.login(me, my_password)
for you in TO:
    s.sendmail(me, you, msg.as_string())
s.quit()
#--------- Envio de mail avisando que comenzo el proceso

start_total=time.time()

#---------- corre el proceso dirigido en el archivo master de generacion de datos para power bi

os.system("python /home/ubuntu/amaszonas/carga_db/carga_opdat_opfho_optar.py") #lee de sql server y envia a mysql

#Proceso de envio de tablas output al RDS
#dump_command="mysqldump --force -h localhost -u root -pefficientis amaszonas proy_vol_g_r curva_final curva_rpk heat_r tramocerrado no_show base_ask base_margen heat_r_grp> /home/ubuntu/amaszonas/dump/new_dump.sql"
#os.system(dump_command)
#os.system("mysql -u admin -pEfts2020 -h amaszonas.cd6fyzkmxrwo.us-east-1.rds.amazonaws.com amaszonas < /home/ubuntu/amaszonas/dump/new_dump.sql")
#Proceso de envio de tablas output al RDS


end_total=time.time()
print("Duración total del Proceso de traspaso: "+str(round((end_total-start_total)/(60*60)))+" horas")



#envio correo final

html = """\
        <html>
          <head></head>
          <body>
            Finaliza el traspaso de opdat opfho y optar.
          </body>
        </html>
        """
part2 = MIMEText(html, 'html')
        
msg.attach(part2)
        
        # Send the message via gmail's regular server, over SSL - passwords are being sent, afterall
s = smtplib.SMTP_SSL('smtp.gmail.com')
        # uncomment if interested in the actual smtp conversation
        # s.set_debuglevel(1)
        # do the smtp auth; sends ehlo if it hasn't been sent already
s.login(me, my_password)
for you in TO:
    s.sendmail(me, you, msg.as_string())
s.quit()
#envio correo final

#envio correo Paso 0

html = """\
        <html>
          <head></head>
          <body>
            Se inicia proceso Paso 0
          </body>
        </html>
        """
part2 = MIMEText(html, 'html')
        
msg.attach(part2)
        
        # Send the message via gmail's regular server, over SSL - passwords are being sent, afterall
s = smtplib.SMTP_SSL('smtp.gmail.com')
        # uncomment if interested in the actual smtp conversation
        # s.set_debuglevel(1)
        # do the smtp auth; sends ehlo if it hasn't been sent already
s.login(me, my_password)
for you in TO:
    s.sendmail(me, you, msg.as_string())
s.quit()
#envio correo Paso 0

os.system("mysql -u admin -pefficientis -h valle.mysql.simplermp.com Valle_RM_actual < /home/ubuntu/Valle_scripts/paso0_111021.sql")

#envio correo Paso 0

html = """\
        <html>
          <head></head>
          <body>
            Finaliza proceso Paso 0
          </body>
        </html>
        """
part2 = MIMEText(html, 'html')
        
msg.attach(part2)
        
        # Send the message via gmail's regular server, over SSL - passwords are being sent, afterall
s = smtplib.SMTP_SSL('smtp.gmail.com')
        # uncomment if interested in the actual smtp conversation
        # s.set_debuglevel(1)
        # do the smtp auth; sends ehlo if it hasn't been sent already
s.login(me, my_password)
for you in TO:
    s.sendmail(me, you, msg.as_string())
s.quit()
#envio finalizacion correo Paso 0
