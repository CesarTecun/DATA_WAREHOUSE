#!/usr/bin/env python3
"""
Recalcula num_total_vehiculos y num_total_victimas en HECHOS
usando las tablas OLTP (HECHOS, VEHICULOS y VICTIMAS).
"""

import os
import psycopg2

DB_HOST = os.getenv("DB_HOST", "postgres_dw")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "dw_transito")
DB_USER = os.getenv("DB_USER", "dw_user")
DB_PASS = os.getenv("DB_PASS", "dw_password")

def main():
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )
    cur = conn.cursor()
    # 1) Actualizar num_total_vehiculos
    cur.execute("""
    UPDATE HECHOS h
       SET num_total_vehiculos = COALESCE(sub.cnt, 0)
    FROM (
      SELECT id_hecho, COUNT(*) AS cnt
      FROM VEHICULOS
      GROUP BY id_hecho
    ) AS sub
    WHERE h.id_hecho = sub.id_hecho;
    """)
    cur.execute("UPDATE HECHOS SET num_total_vehiculos = 0 WHERE num_total_vehiculos IS NULL;")

    # 2) Actualizar num_total_victimas
    cur.execute("""
    UPDATE HECHOS h
       SET num_total_victimas = COALESCE(sub.cnt, 0)
    FROM (
      SELECT id_hecho, COUNT(*) AS cnt
      FROM VICTIMAS
      GROUP BY id_hecho
    ) AS sub
    WHERE h.id_hecho = sub.id_hecho;
    """)
    cur.execute("UPDATE HECHOS SET num_total_victimas = 0 WHERE num_total_victimas IS NULL;")

    conn.commit()
    cur.close()
    conn.close()
    print("✓ Contadores en HECHOS actualizados.")

if __name__ == "__main__":
    main()
