--
-- load_vehiculos.sql
-- De STG_VEHICULOS_RAW a VEHICULOS
--

BEGIN;

DROP TABLE IF EXISTS temp_vehiculos_map;
CREATE TEMP TABLE temp_vehiculos_map AS
SELECT
  CAST(v.id_vehiculo_raw AS INTEGER)        AS id_vehiculo,
  CAST(v.id_hecho_raw   AS INTEGER)        AS id_hecho,
  tv.tipo_vehiculo_id                         AS tipo_vehiculo_id,
  v.marca_raw                                 AS marca,
  v.modelo_raw                                AS modelo,
  CASE
    WHEN v.anio_vehiculo_raw ~ '^[0-9]{4}$'
      THEN CAST(v.anio_vehiculo_raw AS INTEGER)
    ELSE NULL
  END                                         AS anio_vehiculo,
  ev.estado_vehiculo_id                       AS estado_vehiculo_id
FROM stg_vehiculos_raw v
LEFT JOIN CAT_TIPO_VEHICULO tv
  ON tv.descripcion = UPPER(v.tipo_vehiculo_raw)
LEFT JOIN CAT_ESTADO_VEHICULO ev
  ON ev.descripcion = UPPER(v.estado_vehiculo_raw)
WHERE v.id_vehiculo_raw IS NOT NULL
  AND v.id_hecho_raw   IS NOT NULL;

-- Insertar sólo filas válidas
INSERT INTO VEHICULOS (
  id_vehiculo,
  id_hecho,
  tipo_vehiculo_id,
  marca,
  modelo,
  anio_vehiculo,
  estado_vehiculo_id
)
SELECT
  id_vehiculo,
  id_hecho,
  tipo_vehiculo_id,
  marca,
  modelo,
  anio_vehiculo,
  estado_vehiculo_id
FROM temp_vehiculos_map
WHERE id_hecho IN (SELECT id_hecho FROM HECHOS)
  AND tipo_vehiculo_id IS NOT NULL;

-- Registrar errores
INSERT INTO ERRORES_VEHICULOS (id_vehiculo_raw, mensaje_error)
SELECT
  v.id_vehiculo_raw,
  'Hecho inexistente o tipo_vehiculo/estado no mapeados: '
   || v.id_hecho_raw 
   || ' / ' || v.tipo_vehiculo_raw 
   || ' / ' || v.estado_vehiculo_raw
FROM stg_vehiculos_raw v
LEFT JOIN CAT_TIPO_VEHICULO tv
  ON tv.descripcion = UPPER(v.tipo_vehiculo_raw)
LEFT JOIN CAT_ESTADO_VEHICULO ev
  ON ev.descripcion = UPPER(v.estado_vehiculo_raw)
LEFT JOIN HECHOS h
  ON h.id_hecho = CAST(v.id_hecho_raw AS INTEGER)
WHERE h.id_hecho IS NULL
   OR tv.tipo_vehiculo_id IS NULL;

COMMIT;
