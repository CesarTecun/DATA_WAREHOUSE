-- De STG_VEHICULOS a VEHICULOS

BEGIN;

-- Eliminamos cualquier temp previa
DROP TABLE IF EXISTS temp_vehiculos_map;

-- Creamos la tabla temporal con la lógica mínima:
-- - id_hecho: lo buscamos sin zona (por ambigüedad en fuente)
-- - cod_tipo, cod_marca, cod_color, modelo: convertidos a INTEGER
CREATE TEMP TABLE temp_vehiculos_map AS
SELECT
  h.id_hecho                                                                 AS id_hecho,
  (v.tipo_veh::INTEGER)                                                      AS cod_tipo,
  (v.marca_veh::INTEGER)                                                     AS cod_marca,
  v.modelo_veh                                                               AS modelo,
  (v.color_veh::INTEGER)                                                     AS cod_color
FROM stg_vehiculos v
JOIN HECHOS h
  ON h.fecha_incidente  = v.fecha
 AND h.cod_depto        = v.cod_depto
 AND h.cod_mupio        = v.cod_mupio
 -- 🧨 ¡ZONA eliminada para permitir más matches!
WHERE v.tipo_veh IS NOT NULL
  AND v.marca_veh IS NOT NULL
  AND v.color_veh IS NOT NULL;

-- Insertar únicamente filas válidas en VEHICULOS
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
JOIN ref_tipo_vehiculo   rtv ON rtv.cod_tipo  = tm.cod_tipo
JOIN ref_marca_vehiculo  rmv ON rmv.cod_marca = tm.cod_marca
JOIN ref_color_vehiculo  rcv ON rcv.cod_color = tm.cod_color
ON CONFLICT ON CONSTRAINT VEHICULOS_pkey DO NOTHING;

COMMIT;
