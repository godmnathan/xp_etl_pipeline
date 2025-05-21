# Makefile for XP ETL Pipeline Automation

.PHONY: start stop status reset logs connect-status s3-list

start:        ## Starts the full pipeline and logs to pipeline.log
	@echo "🚀 Starting full pipeline..."
	@bash start_pipeline.sh | tee pipeline.log

status:       ## Shows status of all running containers
	docker compose ps

logs:         ## Shows Kafka Connect logs
	docker logs -f connect

connect-status:  ## Shows Kafka Connectors status via REST
	@for c in postg-connector-ipca postg-connector-pre s3-sink-ipca s3-sink-pre; do \
		echo "🔌 $$c"; \
		docker exec connect curl -s http://localhost:8083/connectors/$$c/status | jq || true; \
	done

reset:        ## Stops and removes containers + volumes
	docker compose down --volumes
	docker volume prune -f

stop:         ## Stops containers
	docker compose down
