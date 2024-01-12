#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Dec 23 10:03:52 2019

@author: ierbetta
"""


import pandas as pd
import pyodbc
from sqlalchemy import create_engine

engine2 = create_engine('mysql+mysqlconnector://admin:efficientis@valle.mysql.simplermp.com:3306/valle_lastview', echo=False)

engine = create_engine('mssql+pyodbc://art2fly:Art2Fly_.,@200.29.187.26:1433/SQLFRONT_ART2FLY?driver=ODBC+Driver+17+for+SQL+Server', echo=False)


# df = pd.read_sql_query('''select * from origindest where (to_char(depdate,'yyyy-mm-dd') not in ('0001-01-01') and to_char(arrdate,'yyyy-mm-dd') not in ('0001-01-01') );''', engine)
# df.to_sql(name='origindest', con=engine2, if_exists = 'replace', index=False,chunksize=100)

# df = pd.read_sql_query('''select * from pax;''', engine)
# df.to_sql(name='pax', con=engine2, if_exists = 'replace', index=False,chunksize=100)

df = pd.read_sql_query('''select * from dbo.opdat where left([DFECREA],4) in ('2018','2019', '2020', '2021','2022','2023');''', engine)
df.to_sql(name='opdat', con=engine2, if_exists = 'replace', index=False,chunksize=100)

df1 = pd.read_sql_query('''select * from dbo.OPHFO;''', engine)
df1.to_sql(name='opfho', con=engine2, if_exists = 'replace', index=False,chunksize=100)

df2 = pd.read_sql_query('''select * from dbo.optar;''', engine)
df2.to_sql(name='optar', con=engine2, if_exists = 'replace', index=False,chunksize=100)

df3 = pd.read_sql_query('''select * from dbo.opdat_coti;''', engine)
df3.to_sql(name='opdat_coti', con=engine2, if_exists = 'replace', index=False,chunksize=100)

