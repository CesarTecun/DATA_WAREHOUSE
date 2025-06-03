FROM python:3.9-slim

WORKDIR /app

# 1) Copiamos el requirements y lo instalamos
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# 2) Copiamos el resto de los scripts de ETL a /app/etl_scripts
COPY . /app

# El comando final se definirá en el `docker-compose.yml`
CMD ["python3", "actualizar_contadores.py"]
