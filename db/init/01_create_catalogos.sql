--
-- 01_create_catalogos.sql
-- Crea las tablas de catálogo necesarias para el modelo OLTP
--

-- ref_departamentos
CREATE TABLE IF NOT EXISTS ref_departamentos (
  cod_depto       INTEGER       PRIMARY KEY,
  nombre_depto    VARCHAR(100) NOT NULL UNIQUE
);

-- ref_municipios
CREATE TABLE IF NOT EXISTS ref_municipios (
  cod_depto          INTEGER      NOT NULL,
  cod_mupio          INTEGER      NOT NULL,
  nombre_mupio       VARCHAR(100) NOT NULL,
  PRIMARY KEY (cod_depto, cod_mupio),
  FOREIGN KEY (cod_depto) REFERENCES ref_departamentos(cod_depto),
  CONSTRAINT uq_muni_por_depto
    UNIQUE (cod_depto, nombre_mupio)
);

-- ref_tipo_vehiculo
CREATE TABLE IF NOT EXISTS ref_tipo_vehiculo (
  cod_tipo      INTEGER       PRIMARY KEY,
  descripcion   VARCHAR(50)  NOT NULL UNIQUE
);

-- ref_color_vehiculo
CREATE TABLE IF NOT EXISTS ref_color_vehiculo (
  cod_color      INTEGER       PRIMARY KEY,
  descripcion   VARCHAR(50)  NOT NULL UNIQUE
);

-- ref_marca_vehiculo
CREATE TABLE IF NOT EXISTS ref_marca_vehiculo (
  cod_marca      INTEGER       PRIMARY KEY,
  descripcion   VARCHAR(50)  NOT NULL UNIQUE
);

-- NOTA: La tabla cat_tipo_participacion ha sido eliminada ya que no se usa en el modelo transaccional ni dimensional
-- y no hay referencias a ella en las tablas transaccionales

-- cat_tipo_lesion
CREATE TABLE IF NOT EXISTS cat_tipo_lesion (
  tipo_lesion_id        INTEGER       PRIMARY KEY,
  descripcion           VARCHAR(50)  NOT NULL UNIQUE
);

-- Insertar valores iniciales para tipo_lesion
INSERT INTO cat_tipo_lesion (tipo_lesion_id, descripcion) VALUES
  (1, 'Fallecido'),
  (2, 'Lesionado')
ON CONFLICT (tipo_lesion_id) DO NOTHING;

-- Insertar valores iniciales para departamentos
INSERT INTO ref_departamentos (cod_depto, nombre_depto) VALUES
  (1, 'Guatemala'),
  (2, 'El Progreso'),
  (3, 'Sacatepéquez'),
  (4, 'Chimaltenango'),
  (5, 'Escuintla'),
  (6, 'Sololá'),
  (7, 'Totonicapán'),
  (8, 'Quetzaltenango'),
  (9, 'Suchitepéquez'),
  (10, 'Retalhuleu'),
  (11, 'San Marcos'),
  (12, 'Huehuetenango'),
  (13, 'Quiché'),
  (14, 'Baja Verapaz'),
  (15, 'Alta Verapaz'),
  (16, 'Petén'),
  (17, 'Izabal'),
  (18, 'Zacapa'),
  (19, 'Chiquimula'),
  (20, 'Jalapa'),
  (21, 'Jutiapa'),
  (22, 'Santa Rosa')
ON CONFLICT (cod_depto) DO NOTHING;

-- Insertar valores iniciales para tipos de vehículo
INSERT INTO ref_tipo_vehiculo (cod_tipo, descripcion) VALUES
  (1,  'Ambulancia'),
  (2,  'Araña'),
  (3,  'Autobús'),
  (4,  'Automóvil'),
  (5,  'Bicicleta'),
  (6,  'Bus urbano'),
  (7,  'Bus extraurbano'),
  (8,  'Cabezal'),
  (9,  'Camión'),
  (10, 'Camioneta'),
  (11, 'Carretón'),
  (12, 'Carro fúnebre'),
  (13, 'Carro para golf'),
  (14, 'Casa rodante'),
  (15, 'Chasis'),
  (16, 'Cisterna'),
  (17, 'Cuatrimoto'),
  (18, 'Furgón'),
  (19, 'Furgoneta'),
  (20, 'Go-kart'),
  (21, 'Granelera (Góndola)'),
  (22, 'Grúa'),
  (23, 'Jaula cañera'),
  (24, 'Jeep'),
  (25, 'Limusina'),
  (26, 'Minitractor'),
  (27, 'Monta carga'),
  (28, 'Motocicleta'),
  (29, 'Motobicicleta'),
  (30, 'Motoneta'),
  (31, 'Motoniveladora'),
  (32, 'Mototaxi'),
  (33, 'Perforadora'),
  (34, 'Pick-up'),
  (35, 'Rastra'),
  (36, 'Remolque'),
  (37, 'Retroexcavadora'),
  (38, 'Semirremolque'),
  (39, 'Tractor'),
  (40, 'Tracción animal'),
  (41, 'Trailer'),
  (42, 'Vehículo de transporte'),
  (43, 'Tranvía'),
  (44, 'Trolebús'),
  (45, 'Trimoto'),
  (99, 'Otro tipo de vehículo')
ON CONFLICT (cod_tipo) DO NOTHING;

-- Insertar valores iniciales para colores de vehículo
INSERT INTO ref_color_vehiculo (cod_color, descripcion) VALUES
  (1,  'Blanco'),
  (2,  'Negro'),
  (3,  'Gris'),
  (4,  'Azul'),
  (5,  'Rojo'),
  (6,  'Verde'),
  (7,  'Amarillo'),
  (8,  'Plateado'),
  (9,  'Dorado'),
  (10, 'Bronce'),
  (11, 'Marrón'),
  (12, 'Beige'),
  (13, 'Naranja'),
  (14, 'Violeta'),
  (15, 'Rosa'),
  (99, 'Otro color')
ON CONFLICT (cod_color) DO NOTHING;

-- Insertar valores iniciales para marcas de vehículo
INSERT INTO ref_marca_vehiculo (cod_marca, descripcion) VALUES
  (1,  'Alfa Romeo'),
  (2,  'Aston Martin'),
  (3,  'Audi'),
  (4,  'Bentley'),
  (5,  'BMW'),
  (6,  'Bugatti'),
  (7,  'Cadillac'),
  (8,  'Chevrolet'),
  (9,  'Chrysler'),
  (10, 'Citroën'),
  (11, 'Dodge'),
  (12, 'Ferrari'),
  (13, 'Fiat'),
  (14, 'Ford'),
  (15, 'Honda'),
  (16, 'Hyundai'),
  (17, 'Infiniti'),
  (18, 'Jaguar'),
  (19, 'Jeep'),
  (20, 'Kia'),
  (21, 'Lamborghini'),
  (22, 'Land Rover'),
  (23, 'Lexus'),
  (24, 'Maserati'),
  (25, 'Mazda'),
  (26, 'Mercedes-Benz'),
  (27, 'Mini'),
  (28, 'Mitsubishi'),
  (29, 'Nissan'),
  (30, 'Peugeot'),
  (31, 'Porsche'),
  (32, 'Renault'),
  (33, 'Rolls-Royce'),
  (34, 'Seat'),
  (35, 'Skoda'),
  (36, 'Smart'),
  (37, 'Subaru'),
  (38, 'Suzuki'),
  (39, 'Tesla'),
  (40, 'Toyota'),
  (41, 'Volkswagen'),
  (42, 'Volvo'),
  (99, 'Otra marca')
ON CONFLICT (cod_marca) DO NOTHING;

-- NOTA: Esta tabla es necesaria para el modelo transaccional, ya que se usa en VICTIMAS
-- y debe tener los valores iniciales establecidos antes de crear las tablas transaccionales

-- NOTA: Todas las tablas de catálogo tienen ON CONFLICT DO NOTHING para permitir
--       múltiples ejecuciones del script sin errores de duplicidad

-- NOTA: Se cambió SERIAL por INTEGER para mejor control de los códigos,
--       ya que todos los códigos serán insertados manualmente con valores específicos

-- NOTA: La tabla cat_tipo_participacion ha sido eliminada ya que no se usa en el modelo transaccional ni dimensional
-- y no hay referencias a ella en las tablas transaccionales
