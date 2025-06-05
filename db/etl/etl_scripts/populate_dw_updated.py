#!/usr/bin/env python3
"""
populate_dw_updated.py

Este script reemplaza tu antiguo populate_dw.py.
Lee los datos del modelo OLTP (HECHOS, VICTIMAS, VEHICULOS)
y llena las tablas DIM_FECHA, DIM_HORA, DIM_UBICACION y FACT_ACCIDENTE.
"""

import os
import pandas as pd
from sqlalchemy import create_engine, text

DB_HOST = os.getenv("DB_HOST", "postgres_dw")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "dw_transito")
DB_USER = os.getenv("DB_USER", "dw_user")
DB_PASS = os.getenv("DB_PASS", "dw_password")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(DATABASE_URL)

def cargar_dim_fecha():
    query = """
    SELECT DISTINCT 
        fecha_incidente::date as fecha_incidente
    FROM HECHOS 
    WHERE fecha_incidente IS NOT NULL
    ORDER BY fecha_incidente;
    """
    df = pd.read_sql(query, engine)
    df['fecha_incidente'] = pd.to_datetime(df['fecha_incidente'])

    df_dim = pd.DataFrame()
    df_dim['fecha'] = df['fecha_incidente']
    df_dim['anio'] = df['fecha_incidente'].dt.year
    df_dim['mes'] = df['fecha_incidente'].dt.month
    df_dim['dia'] = df['fecha_incidente'].dt.day
    df_dim['dia_semana'] = df['fecha_incidente'].dt.strftime('%A').str.title()

    with engine.begin() as conn:
        conn.execute(text("SET session_replication_role = 'replica';"))
        conn.execute(text("TRUNCATE TABLE dim_fecha CASCADE;"))
        conn.execute(text("SET session_replication_role = 'origin';"))
        df_dim.to_sql("dim_fecha", conn, if_exists="append", index=False, method='multi')

def cargar_dim_hora():
    data = [{'hora_id': h, 'hora_24h': h, 'descripcion': f"{h:02d}:00"} for h in range(24)]
    df = pd.DataFrame(data)
    with engine.begin() as conn:
        conn.execute(text("SET session_replication_role = 'replica';"))
        conn.execute(text("TRUNCATE TABLE dim_hora CASCADE;"))
        conn.execute(text("SET session_replication_role = 'origin';"))
        df.to_sql("dim_hora", conn, if_exists="append", index=False, method='multi')

def cargar_dim_ubicacion():
    query = """
    SELECT DISTINCT 
        h.cod_depto, h.cod_mupio, h.zona
    FROM HECHOS h
    WHERE h.cod_depto IS NOT NULL AND h.cod_mupio IS NOT NULL;
    """
    df = pd.read_sql(query, engine)
    with engine.begin() as conn:
        conn.execute(text("SET session_replication_role = 'replica';"))
        conn.execute(text("TRUNCATE TABLE dim_ubicacion CASCADE;"))
        conn.execute(text("SET session_replication_role = 'origin';"))
        df.to_sql("dim_ubicacion", conn, if_exists="append", index=False, method='multi')

def cargar_fact_accidente():
    query = """
    INSERT INTO hechos_accidentes (
      fecha_id, ubicacion_id, persona_id, vehiculo_id, tipo_accidente_id,
      num_heridos, num_fallecidos
    )
    SELECT
      df.fecha_id, du.ubicacion_id, dp.persona_id, dv.vehiculo_id, h.tipo_accidente_id,
      SUM(CASE WHEN v.tipo_lesion_id = 2 THEN 1 ELSE 0 END),
      SUM(CASE WHEN v.tipo_lesion_id = 1 THEN 1 ELSE 0 END)
    FROM HECHOS h
      JOIN dim_fecha df ON df.fecha = h.fecha_incidente
      JOIN dim_ubicacion du ON du.cod_depto = h.cod_depto AND du.cod_mupio = h.cod_mupio AND du.zona = h.zona
      JOIN VICTIMAS v ON v.id_hecho = h.id_hecho
      JOIN dim_persona dp ON dp.sexo = v.sexo AND dp.edad = v.edad AND dp.condicion = CASE WHEN v.tipo_lesion_id = 1 THEN 'Fallecido' ELSE 'Lesionado' END
      JOIN VEHICULOS ve ON ve.id_hecho = h.id_hecho
      JOIN dim_vehiculo dv ON dv.tipo_vehiculo = ve.cod_tipo AND dv.marca = ve.cod_marca AND dv.color = ve.cod_color AND dv.modelo = ve.modelo
    GROUP BY df.fecha_id, du.ubicacion_id, dp.persona_id, dv.vehiculo_id, h.tipo_accidente_id
    ON CONFLICT DO NOTHING;
    """
    with engine.begin() as conn:
        conn.execute(text(query))

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
