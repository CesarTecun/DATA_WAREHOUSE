-- ======================================
-- 0) (Opcional) Borrar tablas previas
-- ======================================
DROP TABLE IF EXISTS hechos_accidentes    CASCADE;
DROP TABLE IF EXISTS dim_tipo_accidente   CASCADE;
DROP TABLE IF EXISTS dim_vehiculo         CASCADE;
DROP TABLE IF EXISTS dim_persona          CASCADE;
DROP TABLE IF EXISTS dim_ubicacion        CASCADE;
DROP TABLE IF EXISTS dim_fecha            CASCADE;

-- NOTA: No se eliminan las tablas de referencia (ref_departamentos, ref_municipios, etc.)
-- ya que estas son creadas en 01_create_catalogos.sql y se usan aquí para poblar datos.
-- Las tablas de staging (stg_*_raw) tampoco se eliminan aquí, pues forman parte del ETL.

-- ======================================
-- 1) Dimensiones
-- ======================================
CREATE TABLE IF NOT EXISTS dim_fecha (
    fecha_id     SERIAL PRIMARY KEY,
    fecha        DATE    NOT NULL UNIQUE,
    anio         INT,
    mes          INT,
    dia          INT,
    dia_semana   TEXT
);

CREATE TABLE IF NOT EXISTS dim_ubicacion (
    ubicacion_id SERIAL PRIMARY KEY,
    cod_depto    INT    NOT NULL REFERENCES ref_departamentos(cod_depto),
    cod_mupio    INT    NOT NULL,
    zona         INTEGER,
    UNIQUE (cod_depto, cod_mupio, zona),
    FOREIGN KEY (cod_depto, cod_mupio)
      REFERENCES ref_municipios(cod_depto, cod_mupio)
);


CREATE TABLE IF NOT EXISTS dim_persona (
    persona_id   SERIAL PRIMARY KEY,
    sexo         CHAR(1) CHECK (sexo IN ('M','F')),
    edad         INT,
    condicion    TEXT   CHECK (condicion IN ('Fallecido','Lesionado')),
    UNIQUE (sexo, edad, condicion)
);

-- ======================================
-- 2) DimVehículo y DimTipoAccidente
-- ======================================
CREATE TABLE IF NOT EXISTS dim_vehiculo (
    vehiculo_id   SERIAL    PRIMARY KEY,
    tipo_vehiculo INT       NOT NULL REFERENCES ref_tipo_vehiculo(cod_tipo),
    marca         INT       NOT NULL REFERENCES ref_marca_vehiculo(cod_marca),
    color         INT       NOT NULL REFERENCES ref_color_vehiculo(cod_color),
    modelo        INT,
    UNIQUE (tipo_vehiculo, marca, color, modelo)
);

CREATE TABLE IF NOT EXISTS dim_tipo_accidente (
    tipo_accidente_id SERIAL PRIMARY KEY,
    descripcion       TEXT   UNIQUE
);

-- Insertar tipos de accidente
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

-- ======================================
-- 3) Tabla de Hechos
-- ======================================
CREATE TABLE IF NOT EXISTS hechos_accidentes (
    id_hecho           SERIAL PRIMARY KEY,
    fecha_id           INT    NOT NULL REFERENCES dim_fecha(fecha_id),
    ubicacion_id       INT    NOT NULL REFERENCES dim_ubicacion(ubicacion_id),
    persona_id         INT    NOT NULL REFERENCES dim_persona(persona_id),
    vehiculo_id        INT    NOT NULL REFERENCES dim_vehiculo(vehiculo_id),
    tipo_accidente_id  INT    NOT NULL REFERENCES dim_tipo_accidente(tipo_accidente_id),
    num_heridos        INT,
    num_fallecidos     INT
);

-- ======================================
-- 4) Índices de apoyo
-- ======================================
CREATE INDEX IF NOT EXISTS idx_h_fecha       ON hechos_accidentes(fecha_id);
CREATE INDEX IF NOT EXISTS idx_h_ubicacion   ON hechos_accidentes(ubicacion_id);
CREATE INDEX IF NOT EXISTS idx_h_persona     ON hechos_accidentes(persona_id);
CREATE INDEX IF NOT EXISTS idx_h_vehiculo    ON hechos_accidentes(vehiculo_id);
CREATE INDEX IF NOT EXISTS idx_h_tipo        ON hechos_accidentes(tipo_accidente_id);

-- ======================================
-- 6) Poblar Dimensiones desde OLTP (HECHOS, VICTIMAS, VEHICULOS)
-- ======================================

-- 6.1) Dim Fecha
INSERT INTO dim_fecha (fecha, anio, mes, dia, dia_semana)
SELECT DISTINCT
  h.fecha_incidente,
  EXTRACT(YEAR  FROM h.fecha_incidente),
  EXTRACT(MONTH FROM h.fecha_incidente),
  EXTRACT(DAY   FROM h.fecha_incidente),
  TO_CHAR(h.fecha_incidente, 'FMDay')
FROM HECHOS h
ON CONFLICT (fecha) DO NOTHING;

-- 6.2) Dim Ubicación
INSERT INTO dim_ubicacion (cod_depto, cod_mupio, zona)
SELECT DISTINCT
  h.cod_depto,
  h.cod_mupio,
  h.zona
FROM HECHOS h
ON CONFLICT (cod_depto, cod_mupio, zona) DO NOTHING;

-- 6.3) Dim Persona
INSERT INTO dim_persona (sexo, edad, condicion)
SELECT DISTINCT
  v.sexo,
  v.edad,
  CASE WHEN v.tipo_lesion_id = 1 THEN 'Fallecido' ELSE 'Lesionado' END
FROM VICTIMAS v
ON CONFLICT (sexo, edad, condicion) DO NOTHING;

-- 6.4) Dim Vehículo
INSERT INTO dim_vehiculo (tipo_vehiculo, marca, color, modelo)
SELECT DISTINCT
  ve.cod_tipo,
  ve.cod_marca,
  ve.cod_color,
  ve.modelo
FROM VEHICULOS ve
ON CONFLICT (tipo_vehiculo, marca, color, modelo) DO NOTHING;

-- 6.5) Dim Tipo de Accidente
-- (Ya se cargó con INSERT … ON CONFLICT en la sección 2)

-- 7) Poblar Hechos (Fact)
INSERT INTO hechos_accidentes (
  fecha_id,
  ubicacion_id,
  persona_id,
  vehiculo_id,
  tipo_accidente_id,
  num_heridos,
  num_fallecidos
)
SELECT
  df.fecha_id,
  du.ubicacion_id,
  dp.persona_id,
  dv.vehiculo_id,
  h.tipo_accidente_id,
  SUM(CASE WHEN v.tipo_lesion_id = 2 THEN 1 ELSE 0 END) AS num_heridos,
  SUM(CASE WHEN v.tipo_lesion_id = 1 THEN 1 ELSE 0 END) AS num_fallecidos
FROM HECHOS h
  JOIN dim_fecha df
    ON df.fecha = h.fecha_incidente
  JOIN dim_ubicacion du
    ON du.cod_depto = h.cod_depto
   AND du.cod_mupio = h.cod_mupio
   AND du.zona      = h.zona
  JOIN VICTIMAS v
    ON v.id_hecho = h.id_hecho
  JOIN dim_persona dp
    ON dp.sexo      = v.sexo
   AND dp.edad      = v.edad
   AND dp.condicion = CASE WHEN v.tipo_lesion_id = 1 THEN 'Fallecido' ELSE 'Lesionado' END
  JOIN VEHICULOS ve
    ON ve.id_hecho = h.id_hecho
  JOIN dim_vehiculo dv
    ON dv.tipo_vehiculo = ve.cod_tipo
   AND dv.marca         = ve.cod_marca
   AND dv.color         = ve.cod_color
   AND dv.modelo        = ve.modelo
  JOIN dim_tipo_accidente dta
    ON dta.tipo_accidente_id = h.tipo_accidente_id
GROUP BY
  df.fecha_id,
  du.ubicacion_id,
  dp.persona_id,
  dv.vehiculo_id,
  h.tipo_accidente_id
ON CONFLICT DO NOTHING;