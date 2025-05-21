#!/bin/bash

set -e

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
docker exec -i postgres psql -U postgres -d postgres <<EOF
CREATE TABLE IF NOT EXISTS public.postg_ipca (
  id SERIAL PRIMARY KEY,
  nome TEXT,
  valor NUMERIC,
  dt_update TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.postg_pre (
  id SERIAL PRIMARY KEY,
  nome TEXT,
  valor NUMERIC,
  dt_update TIMESTAMP
);
EOF


echo "📦 [5/9] Copying configuration files into the container..."
docker cp connect_jdbc_postgres_ipca.config connect:/tmp/
docker cp connect_jdbc_postgres_pre.config connect:/tmp/
docker cp connect_s3_sink_ipca.config connect:/tmp/
docker cp connect_s3_sink_pre.config connect:/tmp/


echo "🔌 [6/9] Registering JDBC source connectors..."
docker exec connect curl -sf -X POST -H "Content-Type: application/json" \
  --data @/tmp/connect_jdbc_postgres_ipca.config \
  http://localhost:8083/connectors | jq

docker exec connect curl -sf -X POST -H "Content-Type: application/json" \
  --data @/tmp/connect_jdbc_postgres_pre.config \
  http://localhost:8083/connectors | jq


echo "☁️ [7/9] Registering S3 Sink connectors..."
docker exec connect curl -sf -X POST -H "Content-Type: application/json" \
  --data @/tmp/connect_s3_sink_ipca.config \
  http://localhost:8083/connectors | jq

docker exec connect curl -sf -X POST -H "Content-Type: application/json" \
  --data @/tmp/connect_s3_sink_pre.config \
  http://localhost:8083/connectors | jq


echo "📦 [8/9] (Optional) Listing current files in S3 bucket (xp-etl-pipeline)"
docker exec connect aws s3 ls s3://xp-etl-pipeline/raw/kafka/ipca/ --recursive || true
docker exec connect aws s3 ls s3://xp-etl-pipeline/raw/kafka/pre/ --recursive || true


echo "✅ [9/9] Pipeline started successfully. Connectors are active, topics are being monitored, and S3 is ready for ingestion."
