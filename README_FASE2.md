# Segunda Fase del Proyecto Data Warehouse

Este documento describe los pasos para completar la segunda fase del proyecto de Data Warehouse, que consiste en:

1. Crear archivos de texto (CSV) con información de al menos 12 meses
2. Procesar estos archivos mediante un proceso ETL
3. Preparar los datos para su carga en Metabase

## Archivos incluidos

- `export_to_csv.py`: Exporta las tablas de PostgreSQL a archivos CSV
- `etl_process.py`: Simula el proceso ETL, creando un área de staging y metadatos
- `README_FASE2.md`: Este archivo de documentación

## Paso 1: Exportar datos de PostgreSQL a CSV

Ejecuta el script `export_to_csv.py` para exportar todas las tablas relevantes de tu data warehouse a archivos CSV:

```bash
python export_to_csv.py
```

Este script:
- Crea un directorio `csv_exports` si no existe
- Exporta cada tabla a un archivo CSV con formato `tabla_YYYYMMDD.csv`
- Incluye encabezados con los nombres de las columnas
- Muestra un resumen de la exportación

**Nota**: Modifica las credenciales de la base de datos en el script antes de ejecutarlo.

## Paso 2: Procesar los datos (ETL)

Ejecuta el script `etl_process.py` para simular el proceso ETL:

```bash
python etl_process.py
```

Este script:
- Crea directorios `stage_area` y `metadata` si no existen
- Procesa los archivos CSV más recientes de cada tabla
- Copia los archivos al área de staging
- Genera metadatos para cada tabla en formato JSON
- Crea un archivo de configuración para un trabajo de Metabase

## Paso 3: Configuración en Metabase

Para configurar Metabase con los datos exportados:

1. Inicia Metabase usando Docker Compose:
   ```bash
   docker-compose up -d metabase
   ```

2. Accede a Metabase a través de tu navegador web:
   - URL: http://localhost:3000
   - Configura tu cuenta de administrador en el primer inicio

3. Configura la conexión a la base de datos PostgreSQL:
   - Host: postgres_dw
   - Puerto: 5432
   - Base de datos: dw_transito
   - Usuario: dw_user
   - Contraseña: dw_password

4. Crea dashboards y visualizaciones:
   - Utiliza el editor de preguntas de Metabase para crear consultas
   - Organiza las visualizaciones en dashboards
   - Configura filtros interactivos para explorar los datos

## Estructura de directorios

```
DATA_WAREHOUSE/
├── csv_exports/           # Archivos CSV exportados
├── stage_area/            # Área de staging para ETL
├── metadata/              # Metadatos de las tablas
├── export_to_csv.py       # Script de exportación
├── etl_process.py         # Script de proceso ETL
└── metabase_config.json # Configuración para Metabase
```

## Notas adicionales

- Los archivos CSV incluyen datos de al menos 12 meses como se requiere
- El proceso ETL está diseñado para simular las etapas que se realizarían en Metabase
- Los metadatos generados pueden ser utilizados para configurar las transformaciones en Metabase
