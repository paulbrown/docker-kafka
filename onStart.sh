#!/bin/bash

# Small hack to get id until PetSet index is made available through 
# Downward API (kubernetes issues #30427 #31218).
T_HOSTNAME=$(hostname)
T_ID=$( echo ${T_HOSTNAME} | cut -d "-" -f2 | cut -d "-" -f1 )

echo "broker.id="${T_ID} >> /etc/kafka/kafka.properties
echo "zookeeper.connect=zookeeper:2181" >> /etc/kafka/kafka.properties

export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:/etc/kafka/log4j.properties"

exec /usr/bin/kafka-server-start /etc/kafka/kafka.properties
