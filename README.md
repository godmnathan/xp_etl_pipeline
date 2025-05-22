# 🛠️ XP ETL Pipeline (Kafka + PostgreSQL + S3 + Spark + Docker)

[![Made with Docker](https://img.shields.io/badge/Made%20with-Docker-blue?logo=docker)](https://www.docker.com/)
[![Kafka](https://img.shields.io/badge/Kafka-Streaming-black?logo=apachekafka)](https://kafka.apache.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue?logo=postgresql)](https://www.postgresql.org/)
[![AWS S3](https://img.shields.io/badge/AWS-S3-orange?logo=amazon-aws)](https://aws.amazon.com/s3/)
[![Apache Spark](https://img.shields.io/badge/Apache%20Spark-Processing-orange?logo=apache-spark)](https://spark.apache.org/)
[![License](https://img.shields.io/github/license/godmnathan/xp_etl_pipeline?color=green)](LICENSE)

This project implements a complete **data pipeline** using:

    - Apache Kafka
    - Kafka Connect (JDBC & S3)
    - PostgreSQL
    - Amazon S3
    - Docker Compose
    - Bash automation
    - Spark
    - Optional: Airflow integrations

All components are fully automated via shell scripts and environment configuration. This pipeline is built for the final challenge of the Data Engineering Bootcamp.

## 📐 Architecture

PostgreSQL → Kafka (JDBC Source Connector) → Kafka Topics → S3 (S3 Sink Connector) → Spark Processing

    - Two source tables: `postg_ipca` and `postg_pre`
    - Each table is streamed into Kafka topics
    - Topics are exported to S3 in JSON format
    - Spark jobs process the data from S3 for analytics and transformations

## 🚀 Getting Started

### 🔧 Requirements

    - Docker & Docker Compose
    - Bash 4+
    - AWS account (free tier is enough)
    - `.env` file with credentials and config
    - Apache Spark (included in Docker setup)

### 📁 `.env` Example

Create a `.env` file based on the template:

    # PostgreSQL
    POSTGRES_HOST=postgres
    POSTGRES_PORT=5432
    POSTGRES_DB=postgres
    POSTGRES_USER=postgres
    POSTGRES_PASSWORD=your_password

    # AWS S3
    S3_BUCKET=xp-etl-pipeline
    S3_REGION=us-east-1
    AWS_ACCESS_KEY_ID=your_access_key
    AWS_SECRET_ACCESS_KEY=your_secret_key

## ⚙️ Project Structure

    xp_etl_pipeline/
    ├── config/                  # Kafka Connect configuration templates
    ├── connect/                 # Custom Kafka Connect Dockerfile
    ├── postgres/                # SQL for initial table creation
    ├── scripts/                 # Optional helper scripts
    ├── spark/                   # Spark transformation jobs
    │   ├── jobs/                # Spark job definitions
    │   ├── dependencies/        # External dependencies for Spark
    │   └── config/              # Spark configuration files
    ├── start_pipeline.sh        # Main automation script
    ├── docker-compose.yml       # All services
    ├── .env.example             # Environment template
    ├── Makefile                 # Shortcut commands
    └── README.md

## 🧪 Usage

To launch everything automatically:


    make start


This will:

    - Delete old connectors
    - Start all containers
    - Wait for Kafka Connect
    - Create tables (via `init.sql`)
    - Generate connector configs from `.env`
    - Register connectors (JDBC source and S3 sink)
    - Prepare Spark environment for data processing

## 📊 Monitoring

To check connector status:

    make status

Or view logs in `pipeline.log`.

## 🔥 Spark Processing

The pipeline includes Apache Spark for data processing and transformation. Spark jobs are defined in the `spark/jobs/` directory and can be executed as part of the pipeline or independently.

To run Spark jobs manually:

    make spark-process

This will:
    - Read data from S3 buckets
    - Apply transformations defined in the Spark jobs
    - Output processed data to designated locations

Spark is configured to work seamlessly with the S3 data sources, providing powerful data processing capabilities for the pipeline.

## 📁 Output Example (S3)

Data is stored in:

    s3://xp-etl-pipeline/raw/kafka/ipca/
    s3://xp-etl-pipeline/raw/kafka/pre/
    s3://xp-etl-pipeline/processed/spark/ipca/
    s3://xp-etl-pipeline/processed/spark/pre/

## 📈 Future Enhancements

    - 🧠 Advanced Spark transformations and ML pipelines
    - 🕓 Airflow orchestration
    - 🧪 CI/CD with GitHub Actions
    - 📦 Support for Avro or Parquet format
    - 📊 Real-time dashboards with Spark Streaming

## 👨‍💻 Author

Made with ❤️

> Contributions welcome! Open issues, suggest improvements or fork this project.
