-- ======================================
-- 0) (Opcional) Borrar tablas previas
-- ======================================
DROP TABLE IF EXISTS hechos_accidentes    CASCADE;
DROP TABLE IF EXISTS dim_tipo_accidente   CASCADE;
DROP TABLE IF EXISTS dim_vehiculo         CASCADE;
DROP TABLE IF EXISTS dim_persona          CASCADE;
DROP TABLE IF EXISTS dim_ubicacion        CASCADE;
DROP TABLE IF EXISTS dim_fecha            CASCADE;
DROP TABLE IF EXISTS stg_vehiculos        CASCADE;
DROP TABLE IF EXISTS stg_hechos           CASCADE;
DROP TABLE IF EXISTS stg_fallecidos       CASCADE;

-- ======================================
-- 1) Tablas de Staging
-- ======================================
CREATE TABLE IF NOT EXISTS stg_fallecidos (
  fecha       DATE      NOT NULL,
  cod_depto   INT       NOT NULL,
  cod_mupio   INT,
  zona        TEXT,
  sexo        SMALLINT,
  edad        INT,
  tipo_veh    TEXT,       
  marca_veh   TEXT,      
  color_veh   TEXT,      
  modelo_veh  INT,        
  tipo_eve    SMALLINT,
  fall_les    SMALLINT
);

CREATE TABLE IF NOT EXISTS stg_hechos (
  fecha       DATE,
  cod_depto   INT,
  cod_mupio   INT,
  zona        TEXT,
  tipo_eve    SMALLINT
);

CREATE TABLE IF NOT EXISTS stg_vehiculos (
  fecha       DATE      NOT NULL,
  cod_depto   INT       NOT NULL,
  cod_mupio   INT,
  zona        TEXT,
  tipo_veh    TEXT,
  marca_veh   TEXT,
  color_veh   TEXT,
  modelo_veh  INT
);

-- ======================================
-- 2) Dimensiones
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
    cod_depto    INT    NOT NULL,
    nombre_depto TEXT,
    cod_mupio    INT    NOT NULL,
    nombre_mupio TEXT,
    zona         TEXT,
    UNIQUE (cod_depto, cod_mupio, zona)
);

CREATE TABLE IF NOT EXISTS dim_persona (
    persona_id   SERIAL PRIMARY KEY,
    sexo         CHAR(1) CHECK (sexo IN ('M','F')),
    edad         INT,
    condicion    TEXT   CHECK (condicion IN ('Fallecido','Lesionado')),
    UNIQUE (sexo, edad, condicion)
);

CREATE TABLE IF NOT EXISTS dim_vehiculo (
    vehiculo_id  SERIAL PRIMARY KEY,
    tipo_vehiculo TEXT,
    marca        TEXT,
    color        TEXT,
    modelo       INT,
    UNIQUE (tipo_vehiculo, marca, color, modelo)
);

CREATE TABLE IF NOT EXISTS dim_tipo_accidente (
    tipo_accidente_id SERIAL PRIMARY KEY,
    descripcion       TEXT UNIQUE
);

-- ======================================
-- 3) Tabla de Hechos
-- ======================================
CREATE TABLE IF NOT EXISTS hechos_accidentes (
    id_hecho          SERIAL PRIMARY KEY,
    fecha_id          INT NOT NULL REFERENCES dim_fecha(fecha_id),
    ubicacion_id      INT NOT NULL REFERENCES dim_ubicacion(ubicacion_id),
    persona_id        INT NOT NULL REFERENCES dim_persona(persona_id),
    vehiculo_id       INT NOT NULL REFERENCES dim_vehiculo(vehiculo_id),
    tipo_accidente_id INT NOT NULL REFERENCES dim_tipo_accidente(tipo_accidente_id),
    num_heridos       INT,
    num_fallecidos    INT
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
-- 5) Poblar Dimensiones desde Staging
-- ======================================

-- Dim Fecha (todas las fechas únicas de los 3 staging)
INSERT INTO dim_fecha (fecha, anio, mes, dia, dia_semana)
SELECT DISTINCT fecha,
       EXTRACT(YEAR  FROM fecha),
       EXTRACT(MONTH FROM fecha),
       EXTRACT(DAY   FROM fecha),
       TO_CHAR(fecha, 'FMDay')
FROM (
  SELECT fecha FROM stg_fallecidos
  UNION
  SELECT fecha FROM stg_hechos
  UNION
  SELECT fecha FROM stg_vehiculos
) t
ON CONFLICT DO NOTHING;

-- Dim Ubicación (departamento, municipio, zona)
INSERT INTO dim_ubicacion (cod_depto, cod_mupio, zona)
SELECT DISTINCT cod_depto, cod_mupio, zona
FROM (
  SELECT cod_depto, cod_mupio, zona FROM stg_fallecidos
  UNION
  SELECT cod_depto, cod_mupio, zona FROM stg_hechos
  UNION
  SELECT cod_depto, cod_mupio, zona FROM stg_vehiculos
) u
ON CONFLICT DO NOTHING;

-- Dim Persona (solo de stg_fallecidos)
INSERT INTO dim_persona (sexo, edad, condicion)
SELECT DISTINCT
       CASE WHEN sexo = 1 THEN 'M' ELSE 'F' END,
       edad,
       CASE WHEN fall_les = 1 THEN 'Fallecido' ELSE 'Lesionado' END
FROM stg_fallecidos
ON CONFLICT DO NOTHING;

-- Dim Vehículo (solo de stg_vehiculos)
INSERT INTO dim_vehiculo (tipo_vehiculo, marca, color, modelo)
SELECT DISTINCT
       tipo_veh,
       marca_veh,
       color_veh,
       modelo_veh
FROM stg_vehiculos
ON CONFLICT DO NOTHING;


-- Dim Tipo de Accidente (de stg_fallecidos y stg_hechos)
INSERT INTO dim_tipo_accidente (descripcion)
SELECT DISTINCT tipo_eve::TEXT
FROM (
  SELECT tipo_eve FROM stg_fallecidos
  UNION
  SELECT tipo_eve FROM stg_hechos
) a
ON CONFLICT DO NOTHING;

-- ======================================
-- 6) Poblar Hechos (nivel persona + vehículo)
-- ======================================
INSERT INTO hechos_accidentes (
  fecha_id, ubicacion_id, persona_id, vehiculo_id, tipo_accidente_id,
  num_heridos, num_fallecidos
)
SELECT
  df.fecha_id,
  du.ubicacion_id,
  dp.persona_id,
  dv.vehiculo_id,
  dta.tipo_accidente_id,
  CASE WHEN sf.fall_les = 2 THEN 1 ELSE 0 END AS num_heridos,
  CASE WHEN sf.fall_les = 1 THEN 1 ELSE 0 END AS num_fallecidos
FROM stg_fallecidos sf
  JOIN dim_fecha          df  ON sf.fecha = df.fecha
  JOIN dim_ubicacion      du  ON sf.cod_depto = du.cod_depto
                           AND sf.cod_mupio = du.cod_mupio
                           AND sf.zona      = du.zona
  JOIN dim_persona        dp  ON (CASE WHEN sf.sexo=1 THEN 'M' ELSE 'F' END) = dp.sexo
                           AND sf.edad        = dp.edad
                           AND (CASE WHEN sf.fall_les=1 THEN 'Fallecido' ELSE 'Lesionado' END) = dp.condicion
  JOIN dim_vehiculo       dv  ON dv.tipo_vehiculo = sf.tipo_veh
                           AND dv.marca        = sf.marca_veh
                           AND dv.color        = sf.color_veh
                           AND dv.modelo       = sf.modelo_veh
  JOIN dim_tipo_accidente dta ON sf.tipo_eve::TEXT = dta.descripcion
ON CONFLICT DO NOTHING;