-- 1. Primero, truncamos la tabla para empezar desde cero
TRUNCATE TABLE hechos_accidentes;

-- 2. Insertamos los datos corregidos
INSERT INTO hechos_accidentes (
  fecha_id,
  ubicacion_id,
  persona_id,
  vehiculo_id,
  tipo_accidente_id,
  num_heridos,
  num_fallecidos
)
WITH victimas_vehiculos AS (
  -- Para cada hecho, víctima y vehículo, contar heridos y fallecidos
  SELECT
    h.id_hecho,
    v.id_victima,
    ve.id_vehiculo,
    COUNT(CASE WHEN v.tipo_lesion_id = 2 THEN 1 END) AS num_heridos,
    COUNT(CASE WHEN v.tipo_lesion_id = 1 THEN 1 END) AS num_fallecidos
  FROM HECHOS h
  JOIN VICTIMAS v ON v.id_hecho = h.id_hecho
  JOIN VEHICULOS ve ON ve.id_hecho = h.id_hecho
  GROUP BY h.id_hecho, v.id_victima, ve.id_vehiculo
)
SELECT
  df.fecha_id,
  du.ubicacion_id,
  dp.persona_id,
  dv.vehiculo_id,
  h.tipo_accidente_id,
  vv.num_heridos,
  vv.num_fallecidos
FROM victimas_vehiculos vv
JOIN HECHOS h ON h.id_hecho = vv.id_hecho
JOIN VICTIMAS v ON v.id_hecho = h.id_hecho AND v.id_victima = vv.id_victima
JOIN VEHICULOS ve ON ve.id_vehiculo = vv.id_vehiculo
JOIN dim_fecha df ON df.fecha = h.fecha_incidente
JOIN dim_ubicacion du ON du.cod_depto = h.cod_depto 
  AND du.cod_mupio = h.cod_mupio
  AND (du.zona = h.zona OR (du.zona IS NULL AND h.zona IS NULL))
JOIN dim_persona dp ON dp.sexo = v.sexo
  AND dp.edad = v.edad
  AND dp.condicion = CASE WHEN v.tipo_lesion_id = 1 THEN 'Fallecido' ELSE 'Lesionado' END
JOIN dim_vehiculo dv ON dv.tipo_vehiculo = ve.cod_tipo
  AND dv.marca = ve.cod_marca
  AND dv.color = ve.cod_color
  AND dv.modelo = ve.modelo
GROUP BY
  df.fecha_id,
  du.ubicacion_id,
  dp.persona_id,
  dv.vehiculo_id,
  h.tipo_accidente_id,
  vv.num_heridos,
  vv.num_fallecidos;