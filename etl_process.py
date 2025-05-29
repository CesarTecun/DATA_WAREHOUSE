#!/usr/bin/env python3
"""
Script para simular el proceso ETL para la segunda fase del proyecto de Data Warehouse.
Este script procesa los archivos CSV exportados y prepara los datos para ser cargados
en Pentaho, definiendo Stage Area y Metadata.
"""

import os
import csv
import json
import shutil
from datetime import datetime

# Directorios
CSV_DIR = 'csv_exports'
STAGE_AREA = 'stage_area'
METADATA_DIR = 'metadata'

def ensure_directories():
    """Asegura que los directorios necesarios existan."""
    for directory in [STAGE_AREA, METADATA_DIR]:
        if not os.path.exists(directory):
            os.makedirs(directory)
            print(f"Directorio {directory} creado.")

def get_latest_csv_files():
    """Obtiene los archivos CSV más recientes para cada tabla."""
    if not os.path.exists(CSV_DIR):
        print(f"Error: El directorio {CSV_DIR} no existe.")
        return {}
    
    latest_files = {}
    for filename in os.listdir(CSV_DIR):
        if filename.endswith('.csv'):
            # Extraer el nombre de la tabla del formato tabla_fecha.csv
            parts = filename.split('_')
            if len(parts) >= 2:
                table_name = parts[0]
                for i in range(1, len(parts) - 1):  # Por si el nombre de la tabla tiene guiones bajos
                    if not parts[i].isdigit():
                        table_name += f"_{parts[i]}"
                
                # Verificar si ya tenemos un archivo para esta tabla y si este es más reciente
                if table_name not in latest_files or filename > latest_files[table_name]:
                    latest_files[table_name] = filename
    
    return latest_files

def process_csv_to_stage(csv_filename, table_name):
    """Procesa un archivo CSV y lo mueve al área de staging."""
    source_path = os.path.join(CSV_DIR, csv_filename)
    target_path = os.path.join(STAGE_AREA, f"{table_name}.csv")
    
    # Copiar el archivo al área de staging
    shutil.copy2(source_path, target_path)
    print(f"Archivo {csv_filename} copiado al área de staging como {table_name}.csv")
    
    # Leer el archivo para generar metadatos
    with open(source_path, 'r', newline='') as csvfile:
        reader = csv.reader(csvfile)
        headers = next(reader)  # Obtener encabezados
        
        # Contar filas
        row_count = sum(1 for _ in reader)
        
        # Generar metadatos
        metadata = {
            "table_name": table_name,
            "source_file": csv_filename,
            "columns": headers,
            "row_count": row_count,
            "processed_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        
        # Guardar metadatos
        metadata_path = os.path.join(METADATA_DIR, f"{table_name}_metadata.json")
        with open(metadata_path, 'w') as metafile:
            json.dump(metadata, metafile, indent=4)
        
        print(f"Metadatos generados para {table_name} en {metadata_path}")
    
    return target_path, metadata_path

def generate_pentaho_job_config(tables):
    """Genera un archivo de configuración para un trabajo de Pentaho."""
    job_config = {
        "job_name": "DW_ETL_Process",
        "created_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "tables": tables,
        "stages": [
            {
                "name": "Extract from CSV",
                "type": "CSV Input",
                "description": "Extract data from CSV files"
            },
            {
                "name": "Transform",
                "type": "Data Processing",
                "description": "Apply business rules and transformations"
            },
            {
                "name": "Load",
                "type": "Table Output",
                "description": "Load data into target tables"
            }
        ]
    }
    
    config_path = "pentaho_job_config.json"
    with open(config_path, 'w') as configfile:
        json.dump(job_config, configfile, indent=4)
    
    print(f"Configuración de trabajo Pentaho generada en {config_path}")
    return config_path

def main():
    """Función principal."""
    print("Iniciando proceso ETL...")
    ensure_directories()
    
    # Obtener los archivos CSV más recientes
    latest_files = get_latest_csv_files()
    if not latest_files:
        print("No se encontraron archivos CSV para procesar.")
        return
    
    print(f"Se encontraron {len(latest_files)} archivos CSV para procesar.")
    
    # Procesar cada archivo
    processed_tables = []
    for table_name, csv_filename in latest_files.items():
        try:
            stage_path, metadata_path = process_csv_to_stage(csv_filename, table_name)
            processed_tables.append({
                "table_name": table_name,
                "stage_file": stage_path,
                "metadata_file": metadata_path
            })
        except Exception as e:
            print(f"Error al procesar {csv_filename}: {e}")
    
    # Generar configuración para Pentaho
    if processed_tables:
        config_path = generate_pentaho_job_config(processed_tables)
        print("\nResumen del proceso ETL:")
        print(f"- {len(processed_tables)} tablas procesadas")
        print(f"- Archivos en área de staging: {STAGE_AREA}/")
        print(f"- Metadatos generados en: {METADATA_DIR}/")
        print(f"- Configuración de Pentaho: {config_path}")
        print("\nEl proceso ETL ha finalizado con éxito.")
    else:
        print("No se pudo procesar ningún archivo CSV.")

if __name__ == "__main__":
    main()
