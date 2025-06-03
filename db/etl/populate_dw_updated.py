#!/usr/bin/env python3
"""
populate_dw_updated.py

Este script reemplaza tu antiguo populate_dw.py.
Lee los datos del modelo OLTP (HECHOS, VICTIMAS, VEHICULOS)
y llena las tablas DIM_FECHA, DIM_HORA, DIM_UBICACION y FACT_ACCIDENTE.
"""

import os
import pandas as pd
from sqlalchemy import create_engine

DB_HOST = os.getenv("DB_HOST", "postgres_dw")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "dw_transito")
DB_USER = os.getenv("DB_USER", "dw_user")
DB_PASS = os.getenv("DB_PASS", "dw_password")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(DATABASE_URL)

def cargar_dim_fecha():
    query = "SELECT DISTINCT fecha_incidente FROM HECHOS ORDER BY fecha_incidente;"
    df_fechas = pd.read_sql(query, engine)

    df_fechas['fecha_id'] = df_fechas['fecha_incidente'].dt.strftime('%Y%m%d').astype(int)
    df_fechas['anio'] = df_fechas['fecha_incidente'].dt.year
    df_fechas['mes'] = df_fechas['fecha_incidente'].dt.month
    df_fechas['nombre_mes'] = df_fechas['fecha_incidente'].dt.strftime('%B').str.title()
    df_fechas['trimestre'] = df_fechas['fecha_incidente'].dt.quarter
    df_fechas['dia_mes'] = df_fechas['fecha_incidente'].dt.day
    df_fechas['dia_semana'] = df_fechas['fecha_incidente'].dt.weekday + 1  # 1=lunes … 7=domingo
    df_fechas['nombre_dia_sem'] = df_fechas['fecha_incidente'].dt.strftime('%A').str.title()
    df_fechas['es_fin_de_semana'] = df_fechas['dia_semana'].apply(lambda d: 'S' if d in (6,7) else 'N')
    df_fechas['es_festivo'] = 'N'

    df_dim = df_fechas.rename(columns={'fecha_incidente': 'fecha'})
    df_dim = df_dim[[
        'fecha_id', 'fecha', 'anio', 'mes', 'nombre_mes',
        'trimestre', 'dia_mes', 'dia_semana', 'nombre_dia_sem',
        'es_fin_de_semana', 'es_festivo'
    ]]

    with engine.begin() as conn:
        conn.execute("TRUNCATE TABLE DIM_FECHA;")
        df_dim.to_sql('dim_fecha', conn, if_exists='append', index=False)

def cargar_dim_hora():
    horas = []
    for h in range(24):
        horas.append({'hora_id': h, 'hora_24h': h, 'descripcion': f"{h:02d}:00"})
    df_hora = pd.DataFrame(horas)
    with engine.begin() as conn:
        conn.execute("TRUNCATE TABLE DIM_HORA;")
        df_hora.to_sql('dim_hora', conn, if_exists='append', index=False)

def cargar_dim_ubicacion():
    query = """
    SELECT 
      m.municipio_id    AS ubicacion_id,
      d.nombre_departamento,
      m.nombre_municipio AS municipio
    FROM CAT_MUNICIPIO m
    JOIN CAT_DEPARTAMENTO d ON m.departamento_id = d.departamento_id
    ORDER BY d.nombre_departamento, m.nombre_municipio;
    """
    df_ubi = pd.read_sql(query, engine)
    with engine.begin() as conn:
        conn.execute("TRUNCATE TABLE DIM_UBICACION;")
        df_ubi.to_sql('dim_ubicacion', conn, if_exists='append', index=False)

def cargar_fact_accidente():
    query = """
    SELECT
      h.id_hecho AS accidente_id,
      TO_CHAR(h.fecha_incidente,'YYYYMMDD')::INTEGER AS fecha_id,
      h.municipio_id AS ubicacion_id,
      CASE
        WHEN h.hora_incidente IS NOT NULL
        THEN CAST(SPLIT_PART(h.hora_incidente, ':', 1) AS INTEGER)
        ELSE NULL
      END AS hora_id,
      h.num_total_vehiculos   AS num_vehiculos,
      h.num_total_victimas    AS num_victimas,
      COALESCE(sub_fale.cnt, 0) AS num_fallecidos,
      COALESCE(sub_les.cnt, 0)  AS num_lesionados,
      h.tipo_via               AS tipo_via,
      h.condicion_climatica    AS condicion_clima,
      h.duracion_intervencion  AS duracion_interv
    FROM HECHOS h
    LEFT JOIN (
      SELECT id_hecho, COUNT(*) AS cnt
      FROM VICTIMAS
      WHERE tipo_lesion_id = (
        SELECT tipo_lesion_id 
        FROM CAT_TIPO_LESION 
        WHERE UPPER(descripcion) = 'FALLECIDO'
      )
      GROUP BY id_hecho
    ) sub_fale ON sub_fale.id_hecho = h.id_hecho
    LEFT JOIN (
      SELECT id_hecho, COUNT(*) AS cnt
      FROM VICTIMAS
      WHERE tipo_lesion_id <> (
        SELECT tipo_lesion_id 
        FROM CAT_TIPO_LESION 
        WHERE UPPER(descripcion) = 'FALLECIDO'
      )
      GROUP BY id_hecho
    ) sub_les ON sub_les.id_hecho = h.id_hecho;
    """
    df_fact = pd.read_sql(query, engine)

    with engine.begin() as conn:
        conn.execute("TRUNCATE TABLE FACT_ACCIDENTE;")
        df_fact.to_sql('fact_accidente', conn, if_exists='append', index=False)

def main():
    print("→ Cargando DIM_FECHA…")
    cargar_dim_fecha()
    print("→ Cargando DIM_HORA…")
    cargar_dim_hora()
    print("→ Cargando DIM_UBICACION…")
    cargar_dim_ubicacion()
    print("→ Cargando FACT_ACCIDENTE…")
    cargar_fact_accidente()
    print("✓ Data Warehouse dimensional poblado.")
    
if __name__ == "__main__":
    main()
