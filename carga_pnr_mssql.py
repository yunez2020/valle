#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Dec 23 10:03:52 2019

@author: ierbetta
"""



import pandas as pd
from sqlalchemy import create_engine

engine2 = create_engine('mssql+pyodbc://efficientis:Efi$$ien7i1s@amaszonas.database.windows.net:1433/RM', echo=False)


engine = create_engine('postgresql://rsadv:fUc23e#rlxZkpxbL@adwa-z8.cw8dkf4ytbva.us-east-2.redshift.amazonaws.com:5439/sbrres')
# df = pd.read_sql_query('''select * from origindest where (to_char(depdate,'yyyy-mm-dd') not in ('0001-01-01') and to_char(arrdate,'yyyy-mm-dd') not in ('0001-01-01') );''', engine)
# df.to_sql(name='origindest', con=engine2, if_exists = 'replace', index=False,chunksize=100)

# df = pd.read_sql_query('''select * from pax;''', engine)
# df.to_sql(name='pax', con=engine2, if_exists = 'replace', index=False,chunksize=100)

df = pd.read_sql_query('''select * from pnr;''', engine)
df.to_sql(name='pnr', con=engine2, if_exists = 'replace', index=False,chunksize=100)
