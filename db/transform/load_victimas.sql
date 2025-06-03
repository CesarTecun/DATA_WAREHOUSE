--
-- load_victimas.sql
-- De STG_VICTIMAS_RAW a VICTIMAS
--

BEGIN;

DROP TABLE IF EXISTS temp_victimas_map;
CREATE TEMP TABLE temp_victimas_map AS
SELECT
  CAST(v.id_victima_raw AS INTEGER)               AS id_victima,
  CAST(v.id_hecho_raw   AS INTEGER)               AS id_hecho,
  UPPER(v.sexo_raw)                                AS sexo,
  CAST(v.edad_raw       AS INTEGER)               AS edad,
  tp.tipo_participacion_id                         AS tipo_participacion_id,
  tl.tipo_lesion_id                                AS tipo_lesion_id
FROM stg_victimas_raw v
LEFT JOIN CAT_TIPO_PARTICIPACION tp
  ON tp.descripcion = UPPER(v.tipo_participacion_raw)
LEFT JOIN CAT_TIPO_LESION tl
  ON tl.descripcion = UPPER(v.tipo_lesion_raw)
WHERE v.id_victima_raw IS NOT NULL
  AND v.id_hecho_raw   IS NOT NULL;

-- Insertar sólo filas válidas
INSERT INTO VICTIMAS (
  id_victima,
  id_hecho,
  sexo,
  edad,
  tipo_participacion_id,
  tipo_lesion_id
)
SELECT
  id_victima,
  id_hecho,
  sexo,
  edad,
  tipo_participacion_id,
  tipo_lesion_id
FROM temp_victimas_map
WHERE id_hecho IN (SELECT id_hecho FROM HECHOS)
  AND tipo_participacion_id IS NOT NULL
  AND tipo_lesion_id IS NOT NULL;

-- Registrar errores
INSERT INTO ERRORES_VICTIMAS (id_victima_raw, mensaje_error)
SELECT
  v.id_victima_raw,
  'Hecho inexistente o tipo_participacion/tipo_lesion no mapeados: '
   || v.id_hecho_raw 
   || ' / ' || v.tipo_participacion_raw 
   || ' / ' || v.tipo_lesion_raw
FROM stg_victimas_raw v
LEFT JOIN CAT_TIPO_PARTICIPACION tp
  ON tp.descripcion = UPPER(v.tipo_participacion_raw)
LEFT JOIN CAT_TIPO_LESION tl
  ON tl.descripcion = UPPER(v.tipo_lesion_raw)
LEFT JOIN HECHOS h
  ON h.id_hecho = CAST(v.id_hecho_raw AS INTEGER)
WHERE h.id_hecho IS NULL
   OR tp.tipo_participacion_id IS NULL
   OR tl.tipo_lesion_id IS NULL;

COMMIT;
