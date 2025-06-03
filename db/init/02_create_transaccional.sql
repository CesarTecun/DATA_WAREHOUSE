--
-- 02_create_transaccional.sql
-- Crea las tablas transaccionales (OLTP) y las tablas de errores
--

-- Tabla HECHOS
CREATE TABLE IF NOT EXISTS HECHOS (
  id_hecho               SERIAL       PRIMARY KEY,
  fecha_incidente        DATE         NOT NULL,
  hora_incidente         VARCHAR(5)   NULL,
  cod_depto              INTEGER      NOT NULL,
  cod_mupio              INTEGER      NOT NULL,
  tipo_via               VARCHAR(50)  NULL,
  condicion_climatica    VARCHAR(50)  NULL,
  duracion_intervencion  NUMERIC(7,2) NULL,
  num_total_vehiculos    INTEGER      DEFAULT 0 NOT NULL,
  num_total_victimas     INTEGER      DEFAULT 0 NOT NULL,
  CONSTRAINT fk_hechos_muni
    FOREIGN KEY (cod_depto, cod_mupio)
    REFERENCES ref_municipios(cod_depto, cod_mupio)
);

-- Tabla VICTIMAS
CREATE TABLE IF NOT EXISTS VICTIMAS (
  id_victima             SERIAL       PRIMARY KEY,
  id_hecho               INTEGER      NOT NULL,
  sexo                   CHAR(1)      NOT NULL CHECK (sexo IN ('M','F')),
  edad                   INTEGER      NOT NULL,
  tipo_lesion_id         INTEGER      NOT NULL,
  CONSTRAINT fk_vic_hecho
    FOREIGN KEY (id_hecho)
    REFERENCES HECHOS(id_hecho),
  CONSTRAINT fk_vic_lesion
    FOREIGN KEY (tipo_lesion_id)
    REFERENCES cat_tipo_lesion(tipo_lesion_id)
);

-- Tabla VEHICULOS
-- NOTA: Todas las referencias son INTEGER y FK a las tablas de referencia
--       (ref_tipo_vehiculo, ref_marca_vehiculo, ref_color_vehiculo)
CREATE TABLE IF NOT EXISTS VEHICULOS (
  id_vehiculo            SERIAL      PRIMARY KEY,
  id_hecho               INTEGER     NOT NULL,
  cod_tipo               INTEGER     NOT NULL,
  cod_marca              INTEGER     NULL,
  modelo                 INTEGER     NULL,
  anio_vehiculo          INTEGER     NULL,
  cod_color              INTEGER     NULL,
  CONSTRAINT fk_veh_hecho
    FOREIGN KEY (id_hecho)
    REFERENCES HECHOS(id_hecho),
  CONSTRAINT fk_veh_tipo
    FOREIGN KEY (cod_tipo)
    REFERENCES ref_tipo_vehiculo(cod_tipo),
  CONSTRAINT fk_veh_marca
    FOREIGN KEY (cod_marca)
    REFERENCES ref_marca_vehiculo(cod_marca),
  CONSTRAINT fk_veh_color
    FOREIGN KEY (cod_color)
    REFERENCES ref_color_vehiculo(cod_color)
);

-- Tablas de errores (opcional, para filas malformadas)
CREATE TABLE IF NOT EXISTS ERRORES_HECHOS (
  id SERIAL PRIMARY KEY,
  id_hecho_raw     VARCHAR(20),
  mensaje_error    TEXT,
  fecha_proceso    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ERRORES_VICTIMAS (
  id SERIAL PRIMARY KEY,
  id_victima_raw   VARCHAR(20),
  mensaje_error    TEXT,
  fecha_proceso    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ERRORES_VEHICULOS (
  id SERIAL PRIMARY KEY,
  id_vehiculo_raw  VARCHAR(20),
  mensaje_error    TEXT,
  fecha_proceso    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
