#!/usr/bin/env python3
"""
Script para exportar tablas de PostgreSQL a archivos CSV
para la segunda fase del proyecto de Data Warehouse.
"""

import psycopg2
import csv
import os
from datetime import datetime

# Configuración de la conexión a PostgreSQL
DB_CONFIG = {
    'host': 'localhost',
    'database': 'dw_transito',  # Base de datos del docker-compose
    'user': 'dw_user',          # Usuario del docker-compose
    'password': 'dw_password',  # Contraseña del docker-compose
    'port': 5432
}

# Directorio donde se guardarán los archivos CSV
OUTPUT_DIR = 'csv_exports'

# Lista de tablas a exportar (tablas dimensionales y de hechos)
TABLES = [
    'dim_fecha',
    'dim_ubicacion',
    'dim_persona',
    'dim_vehiculo',
    'dim_tipo_accidente',
    'hechos_accidentes',
    # Tablas de referencia
    'ref_departamentos',
    'ref_municipios',
    'ref_tipo_vehiculo',
    'ref_marca_vehiculo',
    'ref_color_vehiculo'
]

def ensure_output_dir():
    """Asegura que el directorio de salida exista."""
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"Directorio {OUTPUT_DIR} creado.")

def export_table_to_csv(conn, table_name):
    """Exporta una tabla a un archivo CSV."""
    cursor = conn.cursor()
    
    # Obtener los nombres de las columnas
    cursor.execute(f"SELECT * FROM {table_name} LIMIT 0")
    column_names = [desc[0] for desc in cursor.description]
    
    # Consulta para obtener todos los datos
    cursor.execute(f"SELECT * FROM {table_name}")
    rows = cursor.fetchall()
    
    # Nombre del archivo CSV
    timestamp = datetime.now().strftime("%Y%m%d")
    filename = f"{OUTPUT_DIR}/{table_name}_{timestamp}.csv"
    
    # Escribir al archivo CSV
    with open(filename, 'w', newline='') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(column_names)  # Escribir encabezados
        csvwriter.writerows(rows)         # Escribir datos
    
    print(f"Tabla {table_name} exportada a {filename} ({len(rows)} filas)")
    return filename

def main():
    """Función principal."""
    ensure_output_dir()
    
    try:
        # Conectar a la base de datos
        conn = psycopg2.connect(**DB_CONFIG)
        print("Conexión a PostgreSQL establecida.")
        
        # Exportar cada tabla
        exported_files = []
        for table in TABLES:
            try:
                filename = export_table_to_csv(conn, table)
                exported_files.append(filename)
            except Exception as e:
                print(f"Error al exportar la tabla {table}: {e}")
        
        print("\nResumen de exportación:")
        for file in exported_files:
            print(f"- {file}")
        
    except Exception as e:
        print(f"Error de conexión: {e}")
    finally:
        if 'conn' in locals():
            conn.close()
            print("Conexión a PostgreSQL cerrada.")

if __name__ == "__main__":
    main()
