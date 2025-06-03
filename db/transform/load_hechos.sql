--
-- load_hechos.sql
-- De STG_HECHOS_RAW a HECHOS
--

BEGIN;

DROP TABLE IF EXISTS temp_hechos_map;
CREATE TEMP TABLE temp_hechos_map AS
SELECT
  CAST(h.id_hecho_raw AS INTEGER)        AS id_hecho,
  TO_DATE(h.fecha_raw, 'DD/MM/YYYY')     AS fecha_incidente,
  h.hora_raw                              AS hora_incidente,
  dpto.departamento_id                   AS departamento_id,
  muni.municipio_id                      AS municipio_id,
  h.tipo_via_raw                          AS tipo_via,
  h.condicion_clima_raw                   AS condicion_climatica,
  CASE
    WHEN h.duracion_interv_raw ~ '^[0-9]+(\.[0-9]+)?$' 
      THEN CAST(h.duracion_interv_raw AS NUMERIC)
    ELSE NULL
  END                                    AS duracion_intervencion
FROM stg_hechos_raw h
LEFT JOIN CAT_DEPARTAMENTO dpto
  ON dpto.nombre_departamento = h.departamento_raw
LEFT JOIN CAT_MUNICIPIO muni
  ON muni.nombre_municipio = h.municipio_raw
  AND muni.departamento_id = dpto.departamento_id
WHERE h.id_hecho_raw IS NOT NULL;

-- Insertar sólo los que tengan municipio válido
INSERT INTO HECHOS (
  id_hecho,
  fecha_incidente,
  hora_incidente,
  municipio_id,
  tipo_via,
  condicion_climatica,
  duracion_intervencion
)
SELECT
  id_hecho,
  fecha_incidente,
  hora_incidente,
  municipio_id,
  tipo_via,
  condicion_climatica,
  duracion_intervencion
FROM temp_hechos_map
WHERE municipio_id IS NOT NULL;

-- Registrar los errores (sin municipio_id)
INSERT INTO ERRORES_HECHOS (id_hecho_raw, mensaje_error)
SELECT
  h.id_hecho_raw,
  'Depto/municipio no mapeados: ' 
   || h.departamento_raw || ' / ' || h.municipio_raw
FROM stg_hechos_raw h
LEFT JOIN CAT_DEPARTAMENTO dpto
  ON dpto.nombre_departamento = h.departamento_raw
LEFT JOIN CAT_MUNICIPIO muni
  ON muni.nombre_municipio = h.municipio_raw
  AND muni.departamento_id = dpto.departamento_id
WHERE muni.municipio_id IS NULL;

COMMIT;
