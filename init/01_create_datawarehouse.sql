-- ======================================
-- 0) (Opcional) Borrar tablas previas
-- ======================================
DROP TABLE IF EXISTS hechos_accidentes    CASCADE;
DROP TABLE IF EXISTS dim_tipo_accidente   CASCADE;
DROP TABLE IF EXISTS dim_vehiculo         CASCADE;
DROP TABLE IF EXISTS dim_persona          CASCADE;
DROP TABLE IF EXISTS dim_ubicacion        CASCADE;
DROP TABLE IF EXISTS dim_fecha            CASCADE;
DROP TABLE IF EXISTS ref_municipios       CASCADE;
DROP TABLE IF EXISTS ref_departamentos    CASCADE;
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
-- 2) Tablas de referencia (primero)
-- ======================================
CREATE TABLE IF NOT EXISTS ref_departamentos (
    cod_depto INT PRIMARY KEY,
    nombre_depto TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ref_municipios (
    cod_depto INT NOT NULL,
    cod_mupio INT NOT NULL,
    nombre_mupio TEXT NOT NULL,
    PRIMARY KEY (cod_depto, cod_mupio),
    FOREIGN KEY (cod_depto) REFERENCES ref_departamentos(cod_depto)
);

-- ======================================
-- 3) Dimensiones
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
    zona         TEXT,
    UNIQUE (cod_depto, cod_mupio, zona),
    FOREIGN KEY (cod_depto, cod_mupio) REFERENCES ref_municipios(cod_depto, cod_mupio)
);

CREATE TABLE IF NOT EXISTS dim_persona (
    persona_id   SERIAL PRIMARY KEY,
    sexo         CHAR(1) CHECK (sexo IN ('M','F')),
    edad         INT,
    condicion    TEXT   CHECK (condicion IN ('Fallecido','Lesionado')),
    UNIQUE (sexo, edad, condicion)
);

-- Tablas de referencia para vehículos
CREATE TABLE IF NOT EXISTS ref_tipo_vehiculo (
    cod_tipo INT PRIMARY KEY,
    descripcion TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ref_marca_vehiculo (
    cod_marca INT PRIMARY KEY,
    descripcion TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ref_color_vehiculo (
    cod_color INT PRIMARY KEY,
    descripcion TEXT NOT NULL
);

-- Insertar tipos de vehículos
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
  (99, 'Otro');

-- Insertar marcas de vehículos
INSERT INTO ref_marca_vehiculo (cod_marca, descripcion) VALUES
  (1,  'Alfa Romeo'),
  (2,  'Audi'),
  (3,  'BENELLI'),
  (4,  'BMW'),
  (5,  'CF MOTO'),
  (6,  'Changan'),
  (7,  'Chevrolet'),
  (8,  'Dodge'),
  (9,  'Ducati'),
  (10, 'Fiat'),
  (11, 'Ford'),
  (12, 'GMC'),
  (13, 'Harley Davidson'),
  (14, 'Honda'),
  (15, 'Hyundai'),
  (16, 'Jaguar'),
  (17, 'Jeep'),
  (18, 'JAC'),
  (19, 'Kia'),
  (20, 'KTM'),
  (21, 'Land Rover'),
  (22, 'Lexus'),
  (23, 'Mazda'),
  (24, 'Mercedes Benz'),
  (25, 'Mini'),
  (26, 'Mitsubishi'),
  (27, 'Nissan'),
  (28, 'Peugeot'),
  (29, 'Porsche'),
  (30, 'RAM'),
  (31, 'Renault'),
  (32, 'Rover'),
  (33, 'Seat'),
  (34, 'Subaru'),
  (35, 'Suzuki'),
  (36, 'Toyota'),
  (37, 'Volkswagen'),
  (38, 'Volvo'),
  (39, 'Yamaha'),
  (40, 'MAXUS'),
  (41, 'BYD'),
  (42, 'Tesla'),
  (43, 'Great Wall'),
  (44, 'Chery'),
  (45, 'Havaz'),
  (46, 'Isuzu'),
  (47, 'Iveco'),
  (48, 'UD Trucks'),
  (49, 'Mahindra'),
  (50, 'Foton'),
  (51, 'Tata'),
  (52, 'Hino'),
  (53, 'Scania'),
  (54, 'MAN'),
  (55, 'DAF'),
  (56, 'Kawasaki'),
  (57, 'Triumph'),
  (58, 'Royal Enfield'),
  (59, 'MG'),
  (60, 'BAIC'),
  (61, 'FAW'),
  (62, 'DFSK'),
  (63, 'Citroën'),
  (64, 'Opel'),
  (65, 'Kenworth'),
  (66, 'Freightliner'),
  (67, 'Peterbilt'),
  (68, 'Marcopolo'),
  (69, 'Yutong'),
  (70, 'Daihatsu'),
  (71, 'Mack'),
  (72, 'Smart'),
  (73, 'Genesis'),
  (74, 'Acura'),
  (75, 'Infiniti'),
  (76, 'Lincoln'),
  (77, 'Cadillac'),
  (78, 'Buick'),
  (79, 'Chrysler'),
  (80, 'Maserati'),
  (81, 'Ferrari'),
  (82, 'Lamborghini'),
  (83, 'Bentley'),
  (84, 'Rolls-Royce'),
  (85, 'McLaren'),
  (86, 'Aston Martin'),
  (87, 'Lotus'),
  (88, 'Pagani'),
  (89, 'Koenigsegg'),
  (90, 'Bugatti');

-- Insertar colores de vehículos
INSERT INTO ref_color_vehiculo (cod_color, descripcion) VALUES
  (1,  'Blanco'),
  (2,  'Negro'),
  (3,  'Gris'),
  (4,  'Plateado'),
  (5,  'Rojo'),
  (6,  'Azul'),
  (7,  'Verde'),
  (8,  'Amarillo'),
  (9,  'Naranja'),
  (10, 'Marrón'),
  (11, 'Beige'),
  (12, 'Dorado'),
  (13, 'Rosa'),
  (14, 'Morado'),
  (15, 'Turquesa'),
  (16, 'Champán'),
  (17, 'Granate'),
  (18, 'Oliva'),
  (19, 'Cian'),
  (20, 'Magenta'),
  (99, 'Otro');

CREATE TABLE IF NOT EXISTS dim_vehiculo (
    vehiculo_id  SERIAL PRIMARY KEY,
    tipo_vehiculo INT NOT NULL REFERENCES ref_tipo_vehiculo(cod_tipo),
    marca        INT NOT NULL REFERENCES ref_marca_vehiculo(cod_marca),
    color        INT NOT NULL REFERENCES ref_color_vehiculo(cod_color),
    modelo       INT,
    UNIQUE (tipo_vehiculo, marca, color, modelo)
);

CREATE TABLE IF NOT EXISTS dim_tipo_accidente (
    tipo_accidente_id SERIAL PRIMARY KEY,
    descripcion       TEXT UNIQUE
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

-- No agregamos restricciones de clave foránea para dim_ubicacion por ahora

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
-- 5) Poblar tablas de referencia
-- ======================================

-- Insertar departamentos de Guatemala
INSERT INTO ref_departamentos (cod_depto, nombre_depto) VALUES
(1, 'Guatemala'),
(2, 'El Progreso'),
(3, 'Sacatepéquez'),
(4, 'Chimaltenango'),
(5, 'Escuintla'),
(6, 'Santa Rosa'),
(7, 'Sololá'),
(8, 'Totonicapán'),
(9, 'Quetzaltenango'),
(10, 'Suchitepéquez'),
(11, 'Retalhuleu'),
(12, 'San Marcos'),
(13, 'Huehuetenango'),
(14, 'Quiché'),
(15, 'Baja Verapaz'),
(16, 'Alta Verapaz'),
(17, 'Petén'),
(18, 'Izabal'),
(19, 'Zacapa'),
(20, 'Chiquimula'),
(21, 'Jalapa'),
(22, 'Jutiapa');

-- Insertar municipios de Guatemala
INSERT INTO ref_municipios (cod_depto, cod_mupio, nombre_mupio) VALUES
-- Guatemala (1)
(1, 101, 'Guatemala'),
(1, 102, 'Santa Catarina Pinula'),
(1, 103, 'San José Pinula'),
(1, 104, 'San José del Golfo'),
(1, 105, 'Palencia'),
(1, 106, 'Chinautla'),
(1, 107, 'San Pedro Ayampuc'),
(1, 108, 'Mixco'),
(1, 109, 'San Pedro Sacatepéquez'),
(1, 110, 'San Juan Sacatepéquez'),
(1, 111, 'San Raymundo'),
(1, 112, 'Chuarrancho'),
(1, 113, 'Fraijanes'),
(1, 114, 'Amatitlán'),
(1, 115, 'Villa Nueva'),
(1, 116, 'Villa Canales'),
(1, 117, 'San Miguel Petapa'),
-- El Progreso (2)
(2, 201, 'Guastatoya'),
(2, 202, 'Morazán'),
(2, 203, 'San Agustín Acasaguastlán'),
(2, 204, 'San Cristóbal Acasaguastlán'),
(2, 205, 'El Jícaro'),
(2, 206, 'Sansare'),
(2, 207, 'Sanarate'),
(2, 208, 'San Antonio La Paz'),
-- Sacatepéquez (3)
(3, 301, 'Antigua Guatemala'),
(3, 302, 'Jocotenango'),
(3, 303, 'Pastores'),
(3, 304, 'Sumpango'),
(3, 305, 'Santo Domingo Xenacoj'),
(3, 306, 'Santiago Sacatepéquez'),
(3, 307, 'San Bartolomé Milpas Altas'),
(3, 308, 'San Lucas Sacatepéquez'),
(3, 309, 'Santa Lucía Milpas Altas'),
(3, 310, 'Magdalena Milpas Altas'),
(3, 311, 'Santa María de Jesús'),
(3, 312, 'Ciudad Vieja'),
(3, 313, 'San Miguel Dueñas'),
(3, 314, 'Alotenango'),
(3, 315, 'San Antonio Aguas Calientes'),
(3, 316, 'Santa Catarina Barahona'),
-- Chimaltenango (4)
(4, 401, 'Chimaltenango'),
(4, 402, 'San José Poaquil'),
(4, 403, 'San Martín Jilotepeque'),
(4, 404, 'Comalapa'),
(4, 405, 'Santa Apolonia'),
(4, 406, 'Tecpán Guatemala'),
(4, 407, 'Patzún'),
(4, 408, 'Pochuta'),
(4, 409, 'Patzicía'),
(4, 410, 'Santa Cruz Balanyá'),
(4, 411, 'Acatenango'),
(4, 412, 'Yepocapa'),
(4, 413, 'San Andrés Itzapa'),
(4, 414, 'Parramos'),
(4, 415, 'Zaragoza'),
(4, 416, 'El Tejar'),
-- Escuintla (5)
(5, 501, 'Escuintla'),
(5, 502, 'Santa Lucía Cotzumalguapa'),
(5, 503, 'La Democracia'),
(5, 504, 'Siquinalá'),
(5, 505, 'Masagua'),
(5, 506, 'Tiquisate'),
(5, 507, 'La Gomera'),
(5, 508, 'Guanagazapa'),
(5, 509, 'San José'),
(5, 510, 'Iztapa'),
(5, 511, 'Palín'),
(5, 512, 'San Vicente Pacaya'),
(5, 513, 'Nueva Concepción'),
(5, 514, 'Sipacate'),
-- Santa Rosa (6)
(6, 601, 'Cuilapa'),
(6, 602, 'Barberena'),
(6, 603, 'Santa Rosa de Lima'),
(6, 604, 'Casillas'),
(6, 605, 'San Rafael Las Flores'),
(6, 606, 'Oratorio'),
(6, 607, 'San Juan Tecuaco'),
(6, 608, 'Chiquimulilla'),
(6, 609, 'Taxisco'),
(6, 610, 'Santa María Ixhuatán'),
(6, 611, 'Guazacapán'),
(6, 612, 'Santa Cruz Naranjo'),
(6, 613, 'Pueblo Nuevo Viñas'),
(6, 614, 'Nueva Santa Rosa'),
-- Sololá (7)
(7, 701, 'Sololá'),
(7, 702, 'San José Chacayá'),
(7, 703, 'Santa María Visitación'),
(7, 704, 'Santa Lucía Utatlán'),
(7, 705, 'Nahualá'),
(7, 706, 'Santa Catarina Ixtahuacán'),
(7, 707, 'Santa Clara La Laguna'),
(7, 708, 'Concepción'),
(7, 709, 'San Andrés Semetabaj'),
(7, 710, 'Panajachel'),
(7, 711, 'Santa Catarina Palopó'),
(7, 712, 'San Antonio Palopó'),
(7, 713, 'San Lucas Tolimán'),
(7, 714, 'Santa Cruz La Laguna'),
(7, 715, 'San Pablo La Laguna'),
(7, 716, 'San Marcos La Laguna'),
(7, 717, 'San Juan La Laguna'),
(7, 718, 'San Pedro La Laguna'),
(7, 719, 'Santiago Atitlán'),

-- Totonicapán (8)
(8, 801, 'Totonicapán'),
(8, 802, 'San Cristóbal Totonicapán'),
(8, 803, 'San Francisco El Alto'),
(8, 804, 'Santa Lucía La Reforma'),
(8, 805, 'San Andrés Xecul'),
(8, 806, 'Momostenango'),
(8, 807, 'Santa María Chiquimula'),
(8, 808, 'Santa María de Jesús'),

-- Quetzaltenango (9)
(9, 901, 'Quetzaltenango'),
(9, 902, 'Salcajá'),
(9, 903, 'Olintepeque'),
(9, 904, 'San Carlos Sija'),
(9, 905, 'Sibilia'),
(9, 906, 'Cabricán'),
(9, 907, 'Cajolá'),
(9, 908, 'San Miguel Sigüilá'),
(9, 909, 'San Juan Ostuncalco'),
(9, 910, 'San Mateo'),
(9, 911, 'Concepción Chiquirichapa'),
(9, 912, 'San Martín Sacatepéquez'),
(9, 913, 'Almolonga'),
(9, 914, 'Cantel'),
(9, 915, 'Huitán'),
(9, 916, 'Zunil'),
(9, 917, 'Colomba'),
(9, 918, 'San Francisco La Unión'),
(9, 919, 'El Palmar'),
(9, 920, 'Coatepeque'),
(9, 921, 'Génova'),
(9, 922, 'Flores Costa Cuca'),
(9, 923, 'La Esperanza'),
(9, 924, 'Palestina de Los Altos'),

-- Suchitepéquez (10)
(10, 1001, 'Mazatenango'),
(10, 1002, 'Cuyotenango'),
(10, 1003, 'San Francisco Zapotitlán'),
(10, 1004, 'San Bernardino'),
(10, 1005, 'San José El Ídolo'),
(10, 1006, 'Santo Domingo Suchitepéquez'),
(10, 1007, 'San Lorenzo'),
(10, 1008, 'Samayac'),
(10, 1009, 'San Pablo Jocopilas'),
(10, 1010, 'San Antonio Suchitepéquez'),
(10, 1011, 'San Miguel Panán'),
(10, 1012, 'San Gabriel'),
(10, 1013, 'Chicacao'),
(10, 1014, 'Patulul'),
(10, 1015, 'Santa Bárbara'),
(10, 1016, 'San Juan Bautista'),
(10, 1017, 'Santo Tomás La Unión'),
(10, 1018, 'Zunilito'),
(10, 1019, 'Pueblo Nuevo'),
(10, 1020, 'Río Bravo'),
(10, 1021, 'San José La Máquina'),

-- Retalhuleu (11)
(11, 1101, 'Retalhuleu'),
(11, 1102, 'San Sebastián'),
(11, 1103, 'Santa Cruz Muluá'),
(11, 1104, 'San Martín Zapotitlán'),
(11, 1105, 'San Felipe'),
(11, 1106, 'San Andrés Villa Seca'),
(11, 1107, 'Champerico'),
(11, 1108, 'Nuevo San Carlos'),
(11, 1109, 'El Asintal'),

-- San Marcos (12)
(12, 1201, 'San Marcos'),
(12, 1202, 'San Pedro Sacatepéquez'),
(12, 1203, 'San Antonio Sacatepéquez'),
(12, 1204, 'Comitancillo'),
(12, 1205, 'San Miguel Ixtahuacán'),
(12, 1206, 'Concepción Tutuapa'),
(12, 1207, 'Tacaná'),
(12, 1208, 'Sibinal'),
(12, 1209, 'Tajumulco'),
(12, 1210, 'Tejutla'),
(12, 1211, 'San Rafael Pie de La Cuesta'),
(12, 1212, 'Nuevo Progreso'),
(12, 1213, 'El Tumbador'),
(12, 1214, 'San José El Rodeo'),
(12, 1215, 'Malacatán'),
(12, 1216, 'Catarina'),
(12, 1217, 'Ayutla'),
(12, 1218, 'Ocós'),
(12, 1219, 'San Pablo'),
(12, 1220, 'El Quetzal'),
(12, 1221, 'La Reforma'),
(12, 1222, 'Pajapita'),
(12, 1223, 'Ixchiguán'),
(12, 1224, 'San José Ojetenam'),
(12, 1225, 'San Cristóbal Cucho'),
(12, 1226, 'Sipacapa'),
(12, 1227, 'Esquipulas Palo Gordo'),
(12, 1228, 'Río Blanco'),
(12, 1229, 'San Lorenzo'),
(12, 1230, 'La Blanca'),

-- Huehuetenango (13)
(13, 1301, 'Huehuetenango'),
(13, 1302, 'Chiantla'),
(13, 1303, 'Malacatancito'),
(13, 1304, 'Cuilco'),
(13, 1305, 'Nentón'),
(13, 1306, 'San Pedro Necta'),
(13, 1307, 'Jacaltenango'),
(13, 1308, 'Soloma'),
(13, 1309, 'Ixtahuacán'),
(13, 1310, 'Santa Bárbara'),
(13, 1311, 'La Libertad'),
(13, 1312, 'La Democracia'),
(13, 1313, 'San Miguel Acatán'),
(13, 1314, 'San Rafael La Independencia'),
(13, 1315, 'Todos Santos Cuchumatán'),
(13, 1316, 'San Juan Atitán'),
(13, 1317, 'Santa Eulalia'),
(13, 1318, 'San Mateo Ixtatán'),
(13, 1319, 'Colotenango'),
(13, 1320, 'San Sebastián Huehuetenango'),
(13, 1321, 'Tectitán'),
(13, 1322, 'Concepción Huista'),
(13, 1323, 'San Juan Ixcoy'),
(13, 1324, 'San Antonio Huista'),
(13, 1325, 'San Sebastián Coatán'),
(13, 1326, 'Santa Cruz Barillas'),
(13, 1327, 'Aguacatán'),
(13, 1328, 'San Rafael Petzal'),
(13, 1329, 'San Gaspar Ixchil'),
(13, 1330, 'Santiago Chimaltenango'),
(13, 1331, 'Santa Ana Huista'),

-- Quiché (14)
(14, 1401, 'Santa Cruz del Quiché'),
(14, 1402, 'Chiché'),
(14, 1403, 'Chinique'),
(14, 1404, 'Zacualpa'),
(14, 1405, 'Chajul'),
(14, 1406, 'Santo Tomás Chichicastenango'),
(14, 1407, 'Patzité'),
(14, 1408, 'San Antonio Ilotenango'),
(14, 1409, 'San Pedro Jocopilas'),
(14, 1410, 'Cunén'),
(14, 1411, 'San Juan Cotzal'),
(14, 1412, 'Joyabaj'),
(14, 1413, 'Nebaj'),
(14, 1414, 'San Andrés Sajcabajá'),
(14, 1415, 'San Miguel Uspantán'),
(14, 1416, 'Sacapulas'),
(14, 1417, 'San Bartolomé Jocotenango'),
(14, 1418, 'Canillá'),
(14, 1419, 'Chicamán'),
(14, 1420, 'Ixcán'),
(14, 1421, 'Pachalum'),

-- Baja Verapaz (15)
(15, 1501, 'Salamá'),
(15, 1502, 'San Miguel Chicaj'),
(15, 1503, 'Rabinal'),
(15, 1504, 'Cubulco'),
(15, 1505, 'Granados'),
(15, 1506, 'Santa Cruz El Chol'),
(15, 1507, 'San Jerónimo'),
(15, 1508, 'Purulhá'),

-- Alta Verapaz (16)
(16, 1601, 'Cobán'),
(16, 1602, 'Santa Cruz Verapaz'),
(16, 1603, 'San Cristóbal Verapaz'),
(16, 1604, 'Tactic'),
(16, 1605, 'Tamahú'),
(16, 1606, 'San Miguel Tucurú'),
(16, 1607, 'Panzós'),
(16, 1608, 'Senahú'),
(16, 1609, 'San Pedro Carchá'),
(16, 1610, 'San Juan Chamelco'),
(16, 1611, 'San Agustín Lanquín'),
(16, 1612, 'Santa María Cahabón'),
(16, 1613, 'Chisec'),
(16, 1614, 'Chahal'),
(16, 1615, 'Fray Bartolomé de Las Casas'),
(16, 1616, 'Santa Catalina La Tinta'),
(16, 1617, 'Raxruhá'),

-- Petén (17)
(17, 1701, 'Flores'),
(17, 1702, 'San José'),
(17, 1703, 'San Benito'),
(17, 1704, 'San Andrés'),
(17, 1705, 'La Libertad'),
(17, 1706, 'San Francisco'),
(17, 1707, 'Santa Ana'),
(17, 1708, 'Dolores'),
(17, 1709, 'San Luis'),
(17, 1710, 'Sayaxché'),
(17, 1711, 'Melchor de Mencos'),
(17, 1712, 'Poptún'),
(17, 1713, 'Las Cruces'),
(17, 1714, 'El Chal'),

-- Izabal (18)
(18, 1801, 'Puerto Barrios'),
(18, 1802, 'Livingston'),
(18, 1803, 'El Estor'),
(18, 1804, 'Morales'),
(18, 1805, 'Los Amates'),

-- Zacapa (19)
(19, 1901, 'Zacapa'),
(19, 1902, 'Estanzuela'),
(19, 1903, 'Río Hondo'),
(19, 1904, 'Gualán'),
(19, 1905, 'Teculután'),
(19, 1906, 'Usumatlán'),
(19, 1907, 'Cabañas'),
(19, 1908, 'San Diego'),
(19, 1909, 'La Unión'),
(19, 1910, 'Huité'),
(19, 1911, 'San Jorge'),

-- Chiquimula (20)
(20, 2001, 'Chiquimula'),
(20, 2002, 'San José La Arada'),
(20, 2003, 'San Juan Ermita'),
(20, 2004, 'Jocotán'),
(20, 2005, 'Camotán'),
(20, 2006, 'Olopa'),
(20, 2007, 'Esquipulas'),
(20, 2008, 'Concepción Las Minas'),
(20, 2009, 'Quezaltepeque'),
(20, 2010, 'San Jacinto'),
(20, 2011, 'Ipala'),

-- Jalapa (21)
(21, 2101, 'Jalapa'),
(21, 2102, 'San Pedro Pinula'),
(21, 2103, 'San Luis Jilotepeque'),
(21, 2104, 'San Manuel Chaparrón'),
(21, 2105, 'San Carlos Alzatate'),
(21, 2106, 'Monjas'),
(21, 2107, 'Mataquescuintla'),

-- Jutiapa (22)
(22, 2201, 'Jutiapa'),
(22, 2202, 'El Progreso'),
(22, 2203, 'Santa Catarina Mita'),
(22, 2204, 'Agua Blanca'),
(22, 2205, 'Asunción Mita'),
(22, 2206, 'Yupiltepeque'),
(22, 2207, 'Atescatempa'),
(22, 2208, 'Jerez'),
(22, 2209, 'El Adelanto'),
(22, 2210, 'Zapotitlán'),
(22, 2211, 'Comapa'),
(22, 2212, 'Jalpatagua'),
(22, 2213, 'Conguaco'),
(22, 2214, 'Moyuta'),
(22, 2215, 'Pasaco'),
(22, 2216, 'San José Acatempa'),
(22, 2217, 'Quesada');

-- ======================================
-- 6) Poblar Dimensiones desde Staging
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
-- Aseguramos que existan valores por defecto en las tablas de referencia
INSERT INTO ref_tipo_vehiculo (cod_tipo, descripcion) VALUES
(0, 'Desconocido')
ON CONFLICT (cod_tipo) DO NOTHING;

INSERT INTO ref_marca_vehiculo (cod_marca, descripcion) VALUES
(0, 'Desconocido')
ON CONFLICT (cod_marca) DO NOTHING;

INSERT INTO ref_color_vehiculo (cod_color, descripcion) VALUES
(0, 'Desconocido')
ON CONFLICT (cod_color) DO NOTHING;

-- Insertamos los valores predefinidos en las tablas de referencia
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
  (99, 'Otro')
ON CONFLICT (cod_tipo) DO NOTHING;


-- Insertamos todos los valores únicos de tipo_veh de los datos
INSERT INTO ref_tipo_vehiculo (cod_tipo, descripcion)
SELECT DISTINCT 
       CAST(tipo_veh AS INT), 
       'Tipo ' || tipo_veh
FROM stg_vehiculos
WHERE tipo_veh IS NOT NULL AND tipo_veh ~ '^[0-9]+$'
ON CONFLICT (cod_tipo) DO NOTHING;

-- Insertamos todos los valores únicos de marca_veh de los datos
INSERT INTO ref_marca_vehiculo (cod_marca, descripcion)
SELECT DISTINCT 
       CAST(marca_veh AS INT), 
       'Marca ' || marca_veh
FROM stg_vehiculos
WHERE marca_veh IS NOT NULL AND marca_veh ~ '^[0-9]+$'
ON CONFLICT (cod_marca) DO NOTHING;

-- Insertamos todos los valores únicos de color_veh de los datos
INSERT INTO ref_color_vehiculo (cod_color, descripcion)
SELECT DISTINCT 
       CAST(color_veh AS INT), 
       'Color ' || color_veh
FROM stg_vehiculos
WHERE color_veh IS NOT NULL AND color_veh ~ '^[0-9]+$'
ON CONFLICT (cod_color) DO NOTHING;

-- Luego insertamos en dim_vehiculo usando las referencias
INSERT INTO dim_vehiculo (tipo_vehiculo, marca, color, modelo)
SELECT DISTINCT
       CASE WHEN tipo_veh ~ '^[0-9]+$' THEN CAST(tipo_veh AS INT) ELSE 0 END,
       CASE WHEN marca_veh ~ '^[0-9]+$' THEN CAST(marca_veh AS INT) ELSE 0 END,
       CASE WHEN color_veh ~ '^[0-9]+$' THEN CAST(color_veh AS INT) ELSE 0 END,
       modelo_veh
FROM stg_vehiculos
WHERE tipo_veh IS NOT NULL OR marca_veh IS NOT NULL OR color_veh IS NOT NULL
ON CONFLICT DO NOTHING;


-- Dim Tipo de Accidente (de stg_fallecidos y stg_hechos)
-- Comentado porque ahora tenemos valores predefinidos en dim_tipo_accidente
-- INSERT INTO dim_tipo_accidente (descripcion)
-- SELECT DISTINCT tipo_eve::TEXT
-- FROM (
--   SELECT tipo_eve FROM stg_fallecidos
--   UNION
--   SELECT tipo_eve FROM stg_hechos
-- ) a
-- ON CONFLICT DO NOTHING;

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
  JOIN dim_vehiculo       dv  ON dv.tipo_vehiculo = CASE WHEN sf.tipo_veh ~ '^[0-9]+$' THEN CAST(sf.tipo_veh AS INT) ELSE 0 END
                           AND dv.marca        = CASE WHEN sf.marca_veh ~ '^[0-9]+$' THEN CAST(sf.marca_veh AS INT) ELSE 0 END
                           AND dv.color        = CASE WHEN sf.color_veh ~ '^[0-9]+$' THEN CAST(sf.color_veh AS INT) ELSE 0 END
                           AND dv.modelo       = sf.modelo_veh
  JOIN dim_tipo_accidente dta ON sf.tipo_eve = dta.tipo_accidente_id
ON CONFLICT DO NOTHING;