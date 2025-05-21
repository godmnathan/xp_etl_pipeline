FROM confluentinc/cp-kafka-connect:7.4.0

# JDBC Connector
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.7.4

# S3 Connector
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-s3:10.5.1