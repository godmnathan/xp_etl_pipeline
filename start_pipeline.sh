#!/bin/bash

set -e

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

MAX_WAIT=60
WAITED=0

# === CONFIG ===
TOPICS=("postgres-postg_ipca" "postgres-postg_pre")
CONNECTORS=("postg-connector-ipca" "postg-connector-pre" "s3-sink-ipca" "s3-sink-pre")

echo "🧼 [1/9] Removing existing connectors (if any)"
for connector in "${CONNECTORS[@]}"; do
  echo "➡️ Deleting $connector..."
  docker exec connect curl -sf -X DELETE http://localhost:8083/connectors/$connector || true
done


echo "🚀 [2/9] Starting containers with Docker Compose..."
docker compose up -d


echo "⏳ [3/9] Waiting for Kafka Connect to become available (timeout: ${MAX_WAIT}s)"
until docker exec connect curl -sf http://localhost:8083/connectors >/dev/null; do
  sleep 3
  WAITED=$((WAITED+3))
  echo "⌛ Waiting for Kafka Connect... ($WAITED s)"
  if [ "$WAITED" -ge "$MAX_WAIT" ]; then
    echo "❌ Kafka Connect did not respond within $MAX_WAIT seconds. Aborting."
    exit 1
  fi
done


echo "🛠️ [4/9] Creating PostgreSQL tables if needed..."
docker exec -i postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < postgres/init.sql


echo "📄 [5/9] Generating connector config files from templates..."
envsubst < config/connect_jdbc_postgres_ipca.template > /tmp/connect_jdbc_postgres_ipca.config
envsubst < config/connect_jdbc_postgres_pre.template  > /tmp/connect_jdbc_postgres_pre.config
envsubst < config/connect_s3_sink_ipca.template       > /tmp/connect_s3_sink_ipca.config
envsubst < config/connect_s3_sink_pre.template        > /tmp/connect_s3_sink_pre.config


echo "📦 [6/9] Copying configuration files into the container..."
docker cp /tmp/connect_jdbc_postgres_ipca.config connect:/tmp/
docker cp /tmp/connect_jdbc_postgres_pre.config  connect:/tmp/
docker cp /tmp/connect_s3_sink_ipca.config       connect:/tmp/
docker cp /tmp/connect_s3_sink_pre.config        connect:/tmp/


echo "🔌 [7/9] Registering JDBC source connectors..."
docker exec connect curl -sf -X POST -H "Content-Type: application/json" \
  --data @/tmp/connect_jdbc_postgres_ipca.config \
  http://localhost:8083/connectors | jq

docker exec connect curl -sf -X POST -H "Content-Type: application/json" \
  --data @/tmp/connect_jdbc_postgres_pre.config \
  http://localhost:8083/connectors | jq


echo "☁️ [8/9] Registering S3 Sink connectors..."
docker exec connect curl -sf -X POST -H "Content-Type: application/json" \
  --data @/tmp/connect_s3_sink_ipca.config \
  http://localhost:8083/connectors | jq

docker exec connect curl -sf -X POST -H "Content-Type: application/json" \
  --data @/tmp/connect_s3_sink_pre.config \
  http://localhost:8083/connectors | jq


echo "✅ [9/9] Pipeline started successfully. Connectors are active, topics are being monitored, and S3 is ready for ingestion."

echo "🧾 Logging status of all connectors..." | tee -a pipeline.log
for connector in "${CONNECTORS[@]}"; do
  echo "🔍 Status for $connector:" | tee -a pipeline.log
  docker exec connect curl -s http://localhost:8083/connectors/$connector/status | jq | tee -a pipeline.log
done