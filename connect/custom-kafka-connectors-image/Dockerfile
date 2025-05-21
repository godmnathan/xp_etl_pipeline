FROM confluentinc/cp-kafka-connect:7.4.0

# Install JDBC and S3 connectors
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.7.4 && \
    confluent-hub install --no-prompt confluentinc/kafka-connect-s3:10.5.1