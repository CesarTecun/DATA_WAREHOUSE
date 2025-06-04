
-- ==========================================
-- REPOBLAR TODAS LAS DIMENSIONES DEL DW
-- ==========================================

BEGIN;

-- Truncar dimensiones (y reiniciar IDs)
TRUNCATE TABLE
  dim_fecha,
  dim_ubicacion,
  dim_persona,
  dim_vehiculo,
  dim_tipo_accidente
RESTART IDENTITY CASCADE;

-- 1. dim_fecha
INSERT INTO dim_fecha (fecha, anio, mes, dia, dia_semana)
SELECT DISTINCT
  h.fecha_incidente,
  EXTRACT(YEAR  FROM h.fecha_incidente),
  EXTRACT(MONTH FROM h.fecha_incidente),
  EXTRACT(DAY   FROM h.fecha_incidente),
  TO_CHAR(h.fecha_incidente, 'FMDay')
FROM HECHOS h
WHERE h.fecha_incidente IS NOT NULL;

-- 2. dim_ubicacion
INSERT INTO dim_ubicacion (cod_depto, cod_mupio, zona)
SELECT DISTINCT
  h.cod_depto,
  h.cod_mupio,
  h.zona
FROM HECHOS h
WHERE h.cod_depto IS NOT NULL AND h.cod_mupio IS NOT NULL;

-- 3. dim_persona
INSERT INTO dim_persona (sexo, edad, condicion)
SELECT DISTINCT
  v.sexo,
  v.edad,
  CASE WHEN v.tipo_lesion_id = 1 THEN 'Fallecido' ELSE 'Lesionado' END
FROM VICTIMAS v
WHERE v.sexo IS NOT NULL AND v.edad IS NOT NULL;

-- 4. dim_vehiculo
INSERT INTO dim_vehiculo (tipo_vehiculo, marca, color, modelo)
SELECT DISTINCT
  ve.cod_tipo,
  ve.cod_marca,
  ve.cod_color,
  ve.modelo
FROM VEHICULOS ve
WHERE ve.cod_tipo IS NOT NULL;

-- 5. dim_tipo_accidente
INSERT INTO dim_tipo_accidente (tipo_accidente_id, descripcion) VALUES
  (1,  'Colisión entre vehículos en el mismo sentido en tramo recto'),
  (2,  'Colisión entre vehículos en sentidos opuestos en tramo recto'),
  (3,  'Colisión entre vehículos en el mismo sentido en intersección'),
  (4,  'Colisión entre vehículos en sentidos opuestos en intersección'),
  (5,  'Colisión entre vehículos desde carriles contiguos en intersección'),
  (6,  'Colisión entre vehículo y peatón'),
  (7,  'Colisión con vehículo estacionado o detenido'),
  (8,  'Colisión con objeto fijo'),
  (9,  'Salida de la vía sin colisión'),
  (10, 'Vuelco sin colisión'),
  (11, 'Colisión con animal'),
  (12, 'Colisión con tren'),
  (99, 'Otro tipo de accidente')
ON CONFLICT (tipo_accidente_id) DO NOTHING;

COMMIT;
