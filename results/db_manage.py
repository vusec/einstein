#!/usr/bin/env python3

import os, django, psycopg2
from django.conf import settings
from django.core.management import execute_from_command_line

def get_postgresql_max_connections():
    try:
        # Connect to PostgreSQL database to retrieve max_connections value
        conn = psycopg2.connect(dbname="einstein_db", user="einstein_user", password="einstein_password", host="127.0.0.1", port="5432")
        cursor = conn.cursor()
        cursor.execute("SHOW max_connections")
        max_connections = cursor.fetchone()[0]
        conn.close()
        return int(max_connections)
    except Exception as e:
        print("Error:", e)
        return 1

PG_MAX_CONNECTIONS = get_postgresql_max_connections()
NPROC = min(int(os.environ['NPROC']),PG_MAX_CONNECTIONS) if 'NPROC' in os.environ else 1
NUM_THREADS_PER_PROC = min(int(PG_MAX_CONNECTIONS/NPROC),16)

def init_django():
    if settings.configured:
        return

    settings.configure(
        INSTALLED_APPS=[
            'db',
        ],
        DATABASES={
            'default': {
                'ENGINE': 'dj_db_conn_pool.backends.postgresql',
                'NAME': 'einstein_db',
                'USER': 'einstein_user',
                'PASSWORD': 'einstein_password',
                'HOST': '127.0.0.1',
                'PORT': '5432',
                'POOL_OPTIONS': {
                    'POOL_SIZE': NUM_THREADS_PER_PROC,
                }
            }
        },
        DEFAULT_AUTO_FIELD='django.db.models.AutoField'
    )
    django.setup()


if __name__ == "__main__":
    init_django()
    execute_from_command_line()
