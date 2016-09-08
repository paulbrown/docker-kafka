#!/bin/bash

# Small hack to get id until PetSet index is made available through 
# Downward API (kubernetes issues #30427 #31218).
T_HOSTNAME=$(hostname)
T_ID=$( echo ${T_HOSTNAME} | cut -d "-" -f2 | cut -d "-" -f1 )

# PetSet index becomes the kafka broker id.
echo "broker.id="${T_ID} >> /etc/kafka/kafka.properties

# Not ideal to hard code the zookeeper service name but will work for now.
# TODO: update script to take a parameter that contains the zookeeper service name.
# Don't think it can be automated, as only the person deploying kafka 
# will know where the dependent zookeeper service is. 
echo "zookeeper.connect=zookeeper:2181" >> /etc/kafka/kafka.properties

# Lets use the provided log4j properties.
export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:/etc/kafka/log4j.properties"

# Start kafka container with our properties file.
exec /usr/bin/kafka-server-start /etc/kafka/kafka.properties
