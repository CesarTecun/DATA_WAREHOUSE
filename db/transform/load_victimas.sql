-- load_victimas.sql
-- De STG_FALLECIDOS a VICTIMAS
--

BEGIN;

-- Eliminamos cualquier temp previa
DROP TABLE IF EXISTS temp_victimas_map;

-- Creamos la tabla temporal con la lógica mínima:
-- - id_hecho: lo buscamos a partir de (fecha, cod_depto, cod_mupio, zona, tipo_eve)
-- - sexo: mapeamos los valores numéricos a 'M'/'F'
-- - edad: validamos rango (0-120 años)
-- - tipo_lesion_id: mapeamos "Fallecido" → 1, "Lesionado" → 2
CREATE TEMP TABLE temp_victimas_map AS
SELECT DISTINCT
  h.id_hecho                                                                 AS id_hecho,
  -- Mapear sexo: 1 → 'M', 2 → 'F'
  CASE
    WHEN f.sexo::TEXT = '1' THEN 'M'
    WHEN f.sexo::TEXT = '2' THEN 'F'
    ELSE NULL
  END                                                                         AS sexo,
  -- Validar edad: entre 0 y 120 años
  CASE 
    WHEN f.edad BETWEEN 0 AND 120 THEN f.edad
    ELSE NULL
  END                                                                         AS edad,
  -- Mapear tipo de lesión: 1 → Fallecido, 2 → Lesionado
  CASE
    WHEN f.fall_les::TEXT = '1' THEN 1  -- Fallecido
    WHEN f.fall_les::TEXT = '2' THEN 2  -- Lesionado
    ELSE 2  -- Por defecto Lesionado
  END                                                                         AS tipo_lesion_id
FROM stg_fallecidos f
  JOIN HECHOS h
    ON h.fecha_incidente     = f.fecha
   AND h.cod_depto           = f.cod_depto
   AND h.cod_mupio           = f.cod_mupio
   AND h.zona                = f.zona
   AND h.tipo_accidente_id   = (f.tipo_eve::integer)
WHERE f.sexo IS NOT NULL
  AND f.edad IS NOT NULL;

-- Insertar en VICTIMAS solo las filas con sexo válido (M o F)
INSERT INTO VICTIMAS (
  id_hecho,
  sexo,
  edad,
  tipo_lesion_id
)
SELECT
  tv.id_hecho,
  tv.sexo,
  tv.edad,
  tv.tipo_lesion_id
FROM temp_victimas_map tv
WHERE tv.sexo IS NOT NULL
  AND tv.tipo_lesion_id IS NOT NULL
  AND tv.edad IS NOT NULL
ON CONFLICT ON CONSTRAINT VICTIMAS_pkey DO UPDATE
SET tipo_lesion_id = EXCLUDED.tipo_lesion_id;

COMMIT;
