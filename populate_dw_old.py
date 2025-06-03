#!/usr/bin/env python3
import psycopg2

DSN = "dbname=dw_transito user=dw_user password=dw_password host=postgres_dw"

SQL_POPULATE = [
    # Dim Fecha
    """
    INSERT INTO dim_fecha(fecha, anio, mes, dia, dia_semana)
    SELECT DISTINCT
        fecha,
        EXTRACT(YEAR FROM fecha),
        EXTRACT(MONTH FROM fecha),
        EXTRACT(DAY FROM fecha),
        TO_CHAR(fecha,'FMDay')
    FROM (
      SELECT fecha FROM stg_fallecidos
      UNION ALL
      SELECT fecha FROM stg_hechos
      UNION ALL
      SELECT fecha FROM stg_vehiculos
    ) x
    ON CONFLICT DO NOTHING;
    """,

    # Dim Ubicación
    """
    INSERT INTO dim_ubicacion(cod_depto, cod_mupio, zona)
    SELECT DISTINCT cod_depto, cod_mupio, zona
    FROM (
      SELECT cod_depto, cod_mupio, zona FROM stg_fallecidos
      UNION ALL
      SELECT cod_depto, cod_mupio, zona FROM stg_hechos
      UNION ALL
      SELECT cod_depto, cod_mupio, zona FROM stg_vehiculos
    ) x
    ON CONFLICT DO NOTHING;
    """,

    # Dim Persona
    """
    INSERT INTO dim_persona(sexo, edad, condicion)
    SELECT DISTINCT
        CASE WHEN sexo=1 THEN 'M' ELSE 'F' END,
        edad,
        CASE WHEN fall_les=1 THEN 'Fallecido' ELSE 'Lesionado' END
    FROM stg_fallecidos
    ON CONFLICT DO NOTHING;
    """,

    # Dim Vehículo
    """
    -- Primero aseguramos que todos los valores de referencia existan
    INSERT INTO ref_tipo_vehiculo (cod_tipo, descripcion)
    SELECT DISTINCT 
           CAST(tipo_veh AS INT), 
           'Tipo ' || tipo_veh
    FROM stg_vehiculos
    WHERE tipo_veh IS NOT NULL AND tipo_veh ~ '^[0-9]+$'
    ON CONFLICT (cod_tipo) DO NOTHING;

    INSERT INTO ref_marca_vehiculo (cod_marca, descripcion)
    SELECT DISTINCT 
           CAST(marca_veh AS INT), 
           'Marca ' || marca_veh
    FROM stg_vehiculos
    WHERE marca_veh IS NOT NULL AND marca_veh ~ '^[0-9]+$'
    ON CONFLICT (cod_marca) DO NOTHING;

    INSERT INTO ref_color_vehiculo (cod_color, descripcion)
    SELECT DISTINCT 
           CAST(color_veh AS INT), 
           'Color ' || color_veh
    FROM stg_vehiculos
    WHERE color_veh IS NOT NULL AND color_veh ~ '^[0-9]+$'
    ON CONFLICT (cod_color) DO NOTHING;

    -- Luego insertamos en dim_vehiculo usando las referencias
    INSERT INTO dim_vehiculo(tipo_vehiculo, marca, color, modelo)
    SELECT DISTINCT
           CASE WHEN tipo_veh ~ '^[0-9]+$' THEN CAST(tipo_veh AS INT) ELSE 0 END,
           CASE WHEN marca_veh ~ '^[0-9]+$' THEN CAST(marca_veh AS INT) ELSE 0 END,
           CASE WHEN color_veh ~ '^[0-9]+$' THEN CAST(color_veh AS INT) ELSE 0 END,
           modelo_veh
    FROM stg_vehiculos
    WHERE tipo_veh IS NOT NULL OR marca_veh IS NOT NULL OR color_veh IS NOT NULL
    ON CONFLICT DO NOTHING;
    """,

    # Dim Tipo de Accidente - Comentado porque ahora usamos valores predefinidos
    # """
    # INSERT INTO dim_tipo_accidente(descripcion)
    # SELECT DISTINCT tipo_eve::TEXT
    # FROM (
    #   SELECT tipo_eve FROM stg_fallecidos
    #   UNION ALL
    #   SELECT tipo_eve FROM stg_hechos
    # ) x
    # ON CONFLICT DO NOTHING;
    # """,

    # Hechos de accidentes
    """
    INSERT INTO hechos_accidentes(
        fecha_id, ubicacion_id, persona_id, vehiculo_id, tipo_accidente_id,
        num_heridos, num_fallecidos
    )
    SELECT
        df.fecha_id,
        du.ubicacion_id,
        dp.persona_id,
        dv.vehiculo_id,
        dta.tipo_accidente_id,
        CASE WHEN sf.fall_les = 2 THEN 1 ELSE 0 END AS num_heridos,
        CASE WHEN sf.fall_les = 1 THEN 1 ELSE 0 END AS num_fallecidos
    FROM stg_fallecidos sf
      JOIN dim_fecha            df  ON sf.fecha = df.fecha
      JOIN dim_ubicacion        du  ON sf.cod_depto = du.cod_depto
                                 AND sf.cod_mupio = du.cod_mupio
                                 AND sf.zona      = du.zona
      JOIN dim_persona          dp  ON (CASE WHEN sf.sexo=1 THEN 'M' ELSE 'F' END)=dp.sexo
                                 AND sf.edad        = dp.edad
                                 AND (CASE WHEN sf.fall_les=1 THEN 'Fallecido' ELSE 'Lesionado' END)=dp.condicion
      JOIN dim_vehiculo         dv  ON dv.tipo_vehiculo = CASE WHEN sf.tipo_veh ~ '^[0-9]+$' THEN CAST(sf.tipo_veh AS INT) ELSE 0 END
                                 AND dv.marca        = CASE WHEN sf.marca_veh ~ '^[0-9]+$' THEN CAST(sf.marca_veh AS INT) ELSE 0 END
                                 AND dv.color        = CASE WHEN sf.color_veh ~ '^[0-9]+$' THEN CAST(sf.color_veh AS INT) ELSE 0 END
                                 AND dv.modelo       = sf.modelo_veh
      JOIN dim_tipo_accidente   dta ON sf.tipo_eve = dta.tipo_accidente_id
    ON CONFLICT DO NOTHING;
    """
]

def main():
    conn = psycopg2.connect(DSN)
    cur = conn.cursor()
    for sql in SQL_POPULATE:
        cur.execute(sql)
        conn.commit()
    cur.close()
    conn.close()
    print("✅ Dimensiones y hechos poblados correctamente.")

if __name__ == "__main__":
    main()
