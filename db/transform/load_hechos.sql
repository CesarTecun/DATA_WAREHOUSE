--
-- load_hechos.sql
-- De STG_HECHOS a HECHOS
--

BEGIN;

-- Si ya existiera algún hecho previo en la temp, lo borramos
DROP TABLE IF EXISTS temp_hechos_map;

-- Creamos una tabla temporal con los campos mínimos necesarios:
-- id_hecho (se asignará automáticamente en HECHOS), fecha, cod_depto, cod_mupio, zona, tipo_eve
CREATE TEMP TABLE temp_hechos_map AS
SELECT
  -- No usamos CAST(id_hecho_raw) ni TO_DATE(fecha_raw): en stg_hechos ya está todo "limpio"
  h.fecha              AS fecha_incidente,
  h.cod_depto          AS cod_depto,
  h.cod_mupio          AS cod_mupio,
  h.zona               AS zona,
  h.tipo_eve           AS tipo_accidente_id
FROM stg_hechos h
WHERE h.fecha IS NOT NULL
  AND h.cod_depto IS NOT NULL
  AND h.cod_mupio IS NOT NULL;

-- Insertar en HECHOS solamente los registros que no existan aún (sin duplicar fecha+departamento+municipio+zona+tipo)
INSERT INTO HECHOS (
  fecha_incidente,
  cod_depto,
  cod_mupio,
  zona,
  tipo_accidente_id
)
SELECT
  t.fecha_incidente,
  t.cod_depto,
  t.cod_mupio,
  t.zona,
  t.tipo_accidente_id
FROM temp_hechos_map t
ON CONFLICT ON CONSTRAINT HECHOS_pkey DO NOTHING;

COMMIT;
