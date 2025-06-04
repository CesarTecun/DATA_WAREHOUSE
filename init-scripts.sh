#!/bin/bash
set -e

echo "⏳ Verificando si ya existen las tablas..."

# Función para verificar si una tabla existe
table_exists() {
    local table_name=$1
    local query="SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$table_name'"
    psql -U "$POSTGRES_USER" -h "$PGHOST" -d "$POSTGRES_DB" -tAc "$query" | grep -q 1
    return $?
}

# Verificar si ya se han creado las tablas
if ! table_exists "fact_accidentes"; then
    echo "🚀 Ejecutando scripts de inicialización..."
    
    # Ejecutar los scripts en orden
    echo "📋 Ejecutando repoblar_dimensiones.sql..."
    psql -U "$POSTGRES_USER" -h "$PGHOST" -d "$POSTGRES_DB" -f /scripts/repoblar_dimensiones.sql
    
    echo "📋 Ejecutando create_fact_accidentes.sql..."
    psql -U "$POSTGRES_USER" -h "$PGHOST" -d "$POSTGRES_DB" -f /scripts/create_fact_accidentes.sql
    
    echo "📋 Ejecutando poblar_hechos_accidentes.sql..."
    psql -U "$POSTGRES_USER" -h "$PGHOST" -d "$POSTGRES_DB" -f /scripts/poblar_hechos_accidentes.sql
    
    echo "✅ Scripts de inicialización ejecutados correctamente"
else
    echo "ℹ️ Las tablas ya existen, omitiendo la ejecución de los scripts"
fi
