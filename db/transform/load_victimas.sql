-- load_victimas.sql
-- De STG_FALLECIDOS a VICTIMAS
--

BEGIN;

-- Eliminamos cualquier temp previa
DROP TABLE IF EXISTS temp_victimas_map;

-- Creamos la tabla temporal con la lógica mínima:
-- - id_hecho: lo buscamos a partir de (fecha, cod_depto, cod_mupio, zona, tipo_eve)
-- - sexo: solo permitimos 'M' o 'F'; el resto queda NULL y se filtra luego
-- - edad viene directamente de stg_fallecidos
-- - tipo_lesion_id: mapeamos "Fallecido" → 1, "Lesionado" → 2
CREATE TEMP TABLE temp_victimas_map AS
SELECT
  h.id_hecho                                                                 AS id_hecho,
  -- Mapear sexo solo si es 'M' o 'F'; cualquier otro valor se convierte en NULL
  CASE
    WHEN UPPER(f.sexo) IN ('M','F') THEN UPPER(f.sexo)
    ELSE NULL
  END                                                                         AS sexo,
  f.edad                                                                     AS edad,
  CASE
    WHEN UPPER(f.fall_les) = 'FALLECIDO' THEN 1
    ELSE 2
  END                                                                         AS tipo_lesion_id
FROM stg_fallecidos f
  JOIN HECHOS h
    ON h.fecha_incidente     = f.fecha
   AND h.cod_depto           = f.cod_depto
   AND h.cod_mupio           = f.cod_mupio
   AND h.zona                = f.zona
   AND h.tipo_accidente_id   = (f.tipo_eve::integer)
WHERE f.sexo  IS NOT NULL
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
ON CONFLICT ON CONSTRAINT VICTIMAS_pkey DO NOTHING;

COMMIT;
