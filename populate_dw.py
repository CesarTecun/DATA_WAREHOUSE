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
    INSERT INTO dim_vehiculo(tipo_vehiculo, marca, color, modelo)
    SELECT DISTINCT tipo_veh, marca_veh, color_veh, modelo_veh
    FROM stg_vehiculos
    ON CONFLICT DO NOTHING;
    """,

    # Dim Tipo de Accidente
    """
    INSERT INTO dim_tipo_accidente(descripcion)
    SELECT DISTINCT tipo_eve::TEXT
    FROM (
      SELECT tipo_eve FROM stg_fallecidos
      UNION ALL
      SELECT tipo_eve FROM stg_hechos
    ) x
    ON CONFLICT DO NOTHING;
    """,

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
      JOIN dim_vehiculo         dv  ON dv.tipo_vehiculo = sf.tipo_veh
                                 AND dv.marca        = sf.marca_veh
                                 AND dv.color        = sf.color_veh
                                 AND dv.modelo       = sf.modelo_veh
      JOIN dim_tipo_accidente   dta ON sf.tipo_eve::TEXT = dta.descripcion
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
