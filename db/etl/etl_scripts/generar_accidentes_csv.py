import pandas as pd
import psycopg2
import csv
from datetime import datetime

# 1) Definimos rutas dentro del contenedor Docker
BASE = "/app/data"
XLSX_FALLE = BASE + "/fallecidos-y-lesionados-2023-pnc.xlsx"
XLSX_HECH  = BASE + "/hechos-de-transito-2023-pnc.xlsx"
XLSX_VEH   = BASE + "/vehiculos-involucrados-2023-pnc.xlsx"

CSV_FALLE = BASE + "/stg_fallecidos.csv"
CSV_HECH  = BASE + "/stg_hechos.csv"
CSV_VEH   = BASE + "/stg_vehiculos.csv"

# 2) Generar los CSVs de staging
# --------------------------------

# a) Fallecidos y Lesionados
df_f = pd.read_excel(XLSX_FALLE)
df_f_stg = df_f[[
    "año_ocu","mes_ocu","dia_ocu",
    "depto_ocu","mupio_ocu","zona_ocu",
    "sexo_per","edad_per",
    "tipo_veh","marca_veh","color_veh","modelo_veh",
    "tipo_eve","fall_les"
]].rename(columns={
    "año_ocu":"anio","mes_ocu":"mes","dia_ocu":"dia",
    "depto_ocu":"cod_depto","mupio_ocu":"cod_mupio","zona_ocu":"zona",
    "sexo_per":"sexo","edad_per":"edad",
    "tipo_veh":"tipo_veh","marca_veh":"marca_veh","color_veh":"color_veh","modelo_veh":"modelo_veh",
    "tipo_eve":"tipo_eve","fall_les":"fall_les"
})
df_f_stg["fecha"] = pd.to_datetime(
    df_f_stg["anio"].astype(str) + "-" +
    df_f_stg["mes"].astype(str).str.zfill(2) + "-" +
    df_f_stg["dia"].astype(str).str.zfill(2),
    errors="coerce"
)
df_f_stg = df_f_stg[[
    "fecha","cod_depto","cod_mupio","zona",
    "sexo","edad","tipo_veh","marca_veh","color_veh","modelo_veh",
    "tipo_eve","fall_les"
]]
df_f_stg.to_csv(CSV_FALLE, index=False, encoding="utf-8")
print("✅ Generado:", CSV_FALLE)

# b) Hechos de Tránsito
df_h = pd.read_excel(XLSX_HECH)
df_h_stg = df_h[[
    "año_ocu","mes_ocu","dia_ocu",
    "depto_ocu","mupio_ocu","zona_ocu",
    "tipo_eve"
]].rename(columns={
    "año_ocu":"anio","mes_ocu":"mes","dia_ocu":"dia",
    "depto_ocu":"cod_depto","mupio_ocu":"cod_mupio","zona_ocu":"zona",
    "tipo_eve":"tipo_eve"
})
df_h_stg["fecha"] = pd.to_datetime(
    df_h_stg["anio"].astype(str) + "-" +
    df_h_stg["mes"].astype(str).str.zfill(2) + "-" +
    df_h_stg["dia"].astype(str).str.zfill(2),
    errors="coerce"
)
df_h_stg = df_h_stg[["fecha","cod_depto","cod_mupio","zona","tipo_eve"]]
df_h_stg.to_csv(CSV_HECH, index=False, encoding="utf-8")
print("✅ Generado:", CSV_HECH)

# c) Vehículos
print("📊 Leyendo archivo de vehículos...")
df_v = pd.read_excel(XLSX_VEH)

# Limpieza de códigos especiales
print(f"📊 Registros antes de limpieza: {len(df_v)}")

# 1. Convertir 999 a 99 en marca_veh (marca no identificada)
df_v['marca_veh'] = df_v['marca_veh'].replace(999, 99)

# 2. Convertir 9999 y valores vacíos a None en modelo_veh
df_v['modelo_veh'] = df_v['modelo_veh'].replace([9999, '', ' '], None)
# Asegurarse de que los valores sean numéricos o None
df_v['modelo_veh'] = pd.to_numeric(df_v['modelo_veh'], errors='coerce').astype('Int64')

# 3. Verificar códigos de tipo de vehículo (opcional, asegura que existan en ref_tipo_vehiculo)
# df_v['tipo_veh'] = df_v['tipo_veh'].replace(999, 99)  # Si es necesario

print(f"📊 Registros después de limpieza: {len(df_v)}")
print("🔍 Resumen de marcas de vehículos:")
print(df_v['marca_veh'].value_counts().head())

df_v_stg = df_v[[
    "año_ocu","mes_ocu","dia_ocu",
    "depto_ocu","mupio_ocu","zona_ocu",
    "tipo_veh","marca_veh","color_veh","modelo_veh"
]].rename(columns={
    "año_ocu":"anio","mes_ocu":"mes","dia_ocu":"dia",
    "depto_ocu":"cod_depto","mupio_ocu":"cod_mupio","zona_ocu":"zona",
    "tipo_veh":"tipo_veh","marca_veh":"marca_veh","color_veh":"color_veh","modelo_veh":"modelo_veh"
})
df_v_stg["fecha"] = pd.to_datetime(
    df_v_stg["anio"].astype(str) + "-" +
    df_v_stg["mes"].astype(str).str.zfill(2) + "-" +
    df_v_stg["dia"].astype(str).str.zfill(2),
    errors="coerce"
)
df_v_stg = df_v_stg[[
    "fecha","cod_depto","cod_mupio","zona",
    "tipo_veh","marca_veh","color_veh","modelo_veh"
]]
df_v_stg.to_csv(CSV_VEH, index=False, encoding="utf-8")
print("✅ Generado:", CSV_VEH)

# 3) Cargar cada CSV a su tabla staging en PostgreSQL
# ----------------------------------------------------
conn = psycopg2.connect(
    dbname="dw_transito", user="dw_user",
    password="dw_password", host="postgres_dw"
)
cur = conn.cursor()

def cargar_csv(csv_file, tabla, cols):
    with open(csv_file, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Procesar cada valor: convertir cadenas vacías a None
            vals = []
            for c in cols:
                val = row[c]
                # Si es una cadena vacía o solo espacios, convertir a None
                if isinstance(val, str) and val.strip() == '':
                    vals.append(None)
                else:
                    vals.append(val)
            
            # Construir la consulta con los nombres de columnas
            placeholders = ",".join(["%s"] * len(cols))
            query = f"""
                INSERT INTO {tabla} ({','.join(cols)})
                VALUES ({placeholders})
                ON CONFLICT DO NOTHING;
            """
            try:
                cur.execute(query, vals)
            except Exception as e:
                print(f"Error al insertar fila: {vals}")
                print(f"Error: {e}")
                conn.rollback()
                raise
    conn.commit()
    print(f"📥 {tabla} cargada.")

cargar_csv(CSV_FALLE, "stg_fallecidos",
           ["fecha","cod_depto","cod_mupio","zona","sexo","edad","tipo_veh","marca_veh","color_veh","modelo_veh","tipo_eve","fall_les"])
cargar_csv(CSV_HECH,  "stg_hechos",
           ["fecha","cod_depto","cod_mupio","zona","tipo_eve"])
cargar_csv(CSV_VEH,   "stg_vehiculos",
           ["fecha","cod_depto","cod_mupio","zona","tipo_veh","marca_veh","color_veh","modelo_veh"])

cur.close()
conn.close()
print("✅ ETL de staging completado.")
