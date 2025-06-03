-- load_vehiculos.sql
-- De STG_VEHICULOS a VEHICULOS
--

BEGIN;

-- Eliminamos cualquier temp previa
DROP TABLE IF EXISTS temp_vehiculos_map;

-- Creamos la tabla temporal con la lógica mínima:
-- - id_hecho: lo buscamos igual que en load_victimas (fechas y códigos)
-- - cod_tipo, cod_marca, cod_color, modelo: vienen de stg_vehiculos, pero convertidos a INTEGER para validar FK
CREATE TEMP TABLE temp_vehiculos_map AS
SELECT
  h.id_hecho                                                               AS id_hecho,
  -- Convertimos a integer para que coincida con ref_tipo_vehiculo.cod_tipo
  (v.tipo_veh::INTEGER)                                                     AS cod_tipo,
  -- Convertimos a integer para que coincida con ref_marca_vehiculo.cod_marca
  (v.marca_veh::INTEGER)                                                    AS cod_marca,
  v.modelo_veh                                                              AS modelo,
  -- Convertimos a integer para que coincida con ref_color_vehiculo.cod_color
  (v.color_veh::INTEGER)                                                     AS cod_color
FROM stg_vehiculos v
  JOIN HECHOS h
    ON h.fecha_incidente    = v.fecha
   AND h.cod_depto          = v.cod_depto
   AND h.cod_mupio          = v.cod_mupio
   AND h.zona               = v.zona
   -- Aquí suponemos que "tipo_accidente_id" corresponde al campo de hecho,
   -- y "v.tipo_veh" era el campo numérico del tipo de vehículo; los unimos directamente.
   AND h.tipo_accidente_id  = (v.tipo_veh::INTEGER)
WHERE v.tipo_veh IS NOT NULL
  AND v.marca_veh IS NOT NULL
  AND v.color_veh IS NOT NULL
;

-- Insertar únicamente filas válidas en VEHICULOS, 
-- descartando aquellas cuyo tipo, marca o color no exista en su tabla de catálogo:
INSERT INTO VEHICULOS (
  id_hecho,
  cod_tipo,
  cod_marca,
  modelo,
  cod_color
)
SELECT
  tm.id_hecho,
  tm.cod_tipo,
  tm.cod_marca,
  tm.modelo,
  tm.cod_color
FROM temp_vehiculos_map tm
-- Validamos existencia en ref_tipo_vehiculo
JOIN ref_tipo_vehiculo   rtv ON rtv.cod_tipo  = tm.cod_tipo
-- Validamos existencia en ref_marca_vehiculo
JOIN ref_marca_vehiculo  rmv ON rmv.cod_marca = tm.cod_marca
-- Validamos existencia en ref_color_vehiculo
JOIN ref_color_vehiculo  rcv ON rcv.cod_color = tm.cod_color
ON CONFLICT ON CONSTRAINT VEHICULOS_pkey DO NOTHING;

COMMIT;
