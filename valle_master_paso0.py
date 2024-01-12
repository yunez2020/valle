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

#envio correo Paso 0

html = """\
        <html>
          <head></head>
          <body>
            Se inicia proceso semanal Paso0 en MySQL
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

os.system("mysql -u admin -pefficientis -h valle.mysql.simplermp.com Valle_RM_actual < /home/ubuntu/Valle_scripts/paso0_021423.sql")

#envio correo Paso 0 hasta Agencias

html = """\
        <html>
          <head></head>
          <body>
            Finaliza proceso semanal Paso 0
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
