FROM python:3.9-slim

WORKDIR /app

# 1) Instalar el cliente psql (postgresql-client) y dependencias para psycopg2
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       postgresql-client \
       gcc \
       libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 2) Copiamos el requirements y lo instalamos
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# 3) Copiamos todos los scripts y carpetas ETL a /app
COPY . /app

# 4) Fijar permisos ejecutables (opcional)
RUN chmod +x /app/etl_scripts/*.py

# 5) El comando por defecto lo manejará docker-compose (se ignora este CMD)
CMD ["bash"]