-- 1. Crear la tabla de hechos
CREATE TABLE fact_accidentes (
    id_accidente SERIAL PRIMARY KEY,

    -- Claves foráneas a dimensiones
    fecha_id INTEGER REFERENCES dim_fecha(fecha_id),
    ubicacion_id INTEGER REFERENCES dim_ubicacion(ubicacion_id),
    tipo_accidente_id INTEGER REFERENCES dim_tipo_accidente(tipo_accidente_id),

    -- Medidas
    num_vehiculos INTEGER NOT NULL,
    num_victimas INTEGER NOT NULL,
    num_fallecidos INTEGER NOT NULL,
    num_lesionados INTEGER NOT NULL,
    duracion_intervencion NUMERIC(7,2),

    -- Campos adicionales
    condicion_climatica VARCHAR(50),
    tipo_via VARCHAR(50)
);

-- Índices
CREATE INDEX idx_fact_fecha ON fact_accidentes(fecha_id);
CREATE INDEX idx_fact_ubicacion ON fact_accidentes(ubicacion_id);
CREATE INDEX idx_fact_tipo_accidente ON fact_accidentes(tipo_accidente_id);

-- 2. Insertar datos
INSERT INTO fact_accidentes (
    fecha_id,
    ubicacion_id,
    tipo_accidente_id,
    num_vehiculos,
    num_victimas,
    num_fallecidos,
    num_lesionados,
    duracion_intervencion,
    condicion_climatica,
    tipo_via
)
SELECT DISTINCT
    df.fecha_id,
    du.ubicacion_id,
    dta.tipo_accidente_id,
    h.num_total_vehiculos,
    h.num_total_victimas,
    COUNT(CASE WHEN v.tipo_lesion_id = 1 THEN 1 END),
    COUNT(CASE WHEN v.tipo_lesion_id = 2 THEN 1 END),
    h.duracion_intervencion,
    h.condicion_climatica,
    h.tipo_via
FROM HECHOS h
JOIN dim_fecha df ON df.fecha = h.fecha_incidente
JOIN dim_ubicacion du ON du.cod_depto = h.cod_depto AND du.cod_mupio = h.cod_mupio
JOIN dim_tipo_accidente dta ON dta.tipo_accidente_id = h.tipo_accidente_id
LEFT JOIN VICTIMAS v ON v.id_hecho = h.id_hecho
GROUP BY 
    df.fecha_id,
    du.ubicacion_id,
    dta.tipo_accidente_id,
    h.num_total_vehiculos,
    h.num_total_victimas,
    h.duracion_intervencion,
    h.condicion_climatica,
    h.tipo_via;

-- 3. Vista para Metabase
CREATE OR REPLACE VIEW vw_fact_accidentes AS
SELECT 
    fa.id_accidente,
    df.fecha,
    df.anio,
    df.mes,
    df.dia,
    df.dia_semana,
    du.cod_depto,
    du.cod_mupio,
    du.zona,
    dta.descripcion as tipo_accidente,
    fa.num_vehiculos,
    fa.num_victimas,
    fa.num_fallecidos,
    fa.num_lesionados,
    fa.duracion_intervencion,
    fa.condicion_climatica,
    fa.tipo_via
FROM fact_accidentes fa
JOIN dim_fecha df ON df.fecha_id = fa.fecha_id
JOIN dim_ubicacion du ON du.ubicacion_id = fa.ubicacion_id
JOIN dim_tipo_accidente dta ON dta.tipo_accidente_id = fa.tipo_accidente_id;

--4. Vista para análisis de víctimas por año, mes y sexo
-- Proporciona un resumen del número total de víctimas agrupadas por año, mes y sexo
-- Útil para análisis de tendencias temporales y distribución por género
CREATE OR REPLACE VIEW vw_victimas_por_mes_y_sexo AS
SELECT 
    df.anio,
    df.mes,
    v.sexo,
    COUNT(*) AS total_victimas
FROM HECHOS h
JOIN VICTIMAS v ON h.id_hecho = v.id_hecho
JOIN dim_fecha df ON df.fecha = h.fecha_incidente
GROUP BY df.anio, df.mes, v.sexo
ORDER BY df.anio, df.mes, v.sexo;