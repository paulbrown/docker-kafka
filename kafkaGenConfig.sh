#!/usr/bin/env bash

# Environment variables used during docker image build 
KAFKA_USER=${KAFKA_USER:-"kafka"}
KAFKA_HOME=${KAFKA_HOME:-"/kafka"}
KAFKA_DATA_DIR=${KAFKA_DATA_DIR:-"/kafka_data"}
KAFKA_LOG_DIR=${KAFKA_LOG_DIR:-"/kafka_log"}


# Environment variables used to inject configuration from k8s
KAFKA_REPLICAS=${KAFKA_REPLICAS:-"1"}
KAFKA_CONF_DIR=${KAFKA_CONF_DIR:-"$KAFKA_HOME/config"}
KAFKA_CONFIG=${KAFKA_CONFIG:-"$KAFKA_CONF_DIR/kafka.properties"}
KAFKA_HEAP_SIZE=${KAFKA_HEAP_SIZE:-128M}
LOG4J_PROPS="$KAFKA_CONF_DIR/log4j.properties"
HOST=$(hostname -s)
DOMAIN=$(hostname -d)

# Environment variables used as part of application startup script
KAFKA_HEAP_OPTS="-Xmx$KAFKA_HEAP_SIZE -Xms$KAFKA_HEAP_SIZE"
KAFKA_LOG4J_OPTS=$LOG4J_PROPS
# $KAFKA_JVM_PERFORMANCE_OPTS 
# $KAFKA_GC_LOG_OPTS 
# $KAFKA_JMX_OPTS 
LOG_DIR=$KAFKA_LOG_DIR

function validate_env() {
    echo "Validating environment"
    if [ -z $KAFKA_REPLICAS ]; then
        echo "KAFKA_REPLICAS is a mandatory environment variable"
        exit 1
    fi

    if [[ $HOST =~ ^([A-Za-z0-9]*)(-)([0-9]+)((-.*)?)$ ]]; then
        NAME=$(echo $HOST | cut -d '-' -f 1)
        ORD=$(echo $HOST | cut -d '-' -f 2)
    else
        echo "Failed to match valid hostname '[name]-[ordinal]' $HOST"
        exit 1
    fi

    MY_ID=$ORD
    env
    echo "Environment validation successful"
}


function create_config() {
    rm -f $KAFKA_CONFIG
    echo "Creating Kafka configuration"
    
    echo "# This file was autogenerated by kafkaGenConfig.sh" >> $KAFKA_CONFIG
    echo "# DO NOT EDIT DIRECTLY" >> $KAFKA_CONFIG
    echo "# Server Basics" >> $KAFKA_CONFIG
    echo "broker.id=$MY_ID" >> $KAFKA_CONFIG

    echo "# Log Basics" >> $KAFKA_CONFIG
    echo "log.dir=$KAFKA_DATA_DIR" >> $KAFKA_CONFIG

    echo "# Zookeeper" >> $KAFKA_CONFIG
    echo "zookeeper.connect=zk-0.zk.default.svc.cluster.local:2181,zk-1.zk.default.svc.cluster.local:2181,zk-2.zk.default.svc.cluster.local:2181" >> $KAFKA_CONFIG

    echo "Wrote Kafka configuration file to $KAFKA_CONFIG"
}


function create_log4j_props() {
    rm -f $LOG4J_PROPS
    echo "Creating Kafka log4j properties"
    
    echo "# This file was autogenerated by kafkaGenConfig.sh" >> $LOG4J_PROPS
    echo "# DO NOT EDIT DIRECTLY" >> $LOG4J_PROPS
    echo "log4j.rootLogger=INFO, stdout, kafkaAppender" >> $LOG4J_PROPS
    echo "log4j.appender.stdout=org.apache.log4j.ConsoleAppender" >> $LOG4J_PROPS
    echo "log4j.appender.stdout.layout=org.apache.log4j.PatternLayout" >> $LOG4J_PROPS
    echo "log4j.appender.stdout.layout.ConversionPattern=[%d] %p %m (%c)%n" >> $LOG4J_PROPS

    echo "log4j.appender.kafkaAppender=org.apache.log4j.DailyRollingFileAppender" >> $LOG4J_PROPS
    echo "log4j.appender.kafkaAppender.DatePattern='.'yyyy-MM-dd-HH" >> $LOG4J_PROPS
    echo "log4j.appender.kafkaAppender.File=$KAFKA_LOG_DIR/server.log" >> $LOG4J_PROPS
    echo "log4j.appender.kafkaAppender.layout=org.apache.log4j.PatternLayout" >> $LOG4J_PROPS
    echo "log4j.appender.kafkaAppender.layout.ConversionPattern=[%d] %p %m (%c)%n" >> $LOG4J_PROPS

    echo "log4j.appender.stateChangeAppender=org.apache.log4j.DailyRollingFileAppender" >> $LOG4J_PROPS
    echo "log4j.appender.stateChangeAppender.DatePattern='.'yyyy-MM-dd-HH" >> $LOG4J_PROPS
    echo "log4j.appender.stateChangeAppender.File=$KAFKA_LOG_DIR/state-change.log" >> $LOG4J_PROPS
    echo "log4j.appender.stateChangeAppender.layout=org.apache.log4j.PatternLayout" >> $LOG4J_PROPS
    echo "log4j.appender.stateChangeAppender.layout.ConversionPattern=[%d] %p %m (%c)%n" >> $LOG4J_PROPS

    echo "log4j.appender.requestAppender=org.apache.log4j.DailyRollingFileAppender" >> $LOG4J_PROPS
    echo "log4j.appender.requestAppender.DatePattern='.'yyyy-MM-dd-HH" >> $LOG4J_PROPS
    echo "log4j.appender.requestAppender.File=$KAFKA_LOG_DIR/kafka-request.log" >> $LOG4J_PROPS
    echo "log4j.appender.requestAppender.layout=org.apache.log4j.PatternLayout" >> $LOG4J_PROPS
    echo "log4j.appender.requestAppender.layout.ConversionPattern=[%d] %p %m (%c)%n" >> $LOG4J_PROPS

    echo "log4j.appender.cleanerAppender=org.apache.log4j.DailyRollingFileAppender" >> $LOG4J_PROPS
    echo "log4j.appender.cleanerAppender.DatePattern='.'yyyy-MM-dd-HH" >> $LOG4J_PROPS
    echo "log4j.appender.cleanerAppender.File=$KAFKA_LOG_DIR/log-cleaner.log" >> $LOG4J_PROPS
    echo "log4j.appender.cleanerAppender.layout=org.apache.log4j.PatternLayout" >> $LOG4J_PROPS
    echo "log4j.appender.cleanerAppender.layout.ConversionPattern=[%d] %p %m (%c)%n" >> $LOG4J_PROPS

    echo "log4j.appender.controllerAppender=org.apache.log4j.DailyRollingFileAppender" >> $LOG4J_PROPS
    echo "log4j.appender.controllerAppender.DatePattern='.'yyyy-MM-dd-HH" >> $LOG4J_PROPS
    echo "log4j.appender.controllerAppender.File=$KAFKA_LOG_DIR/controller.log" >> $LOG4J_PROPS
    echo "log4j.appender.controllerAppender.layout=org.apache.log4j.PatternLayout" >> $LOG4J_PROPS
    echo "log4j.appender.controllerAppender.layout.ConversionPattern=[%d] %p %m (%c)%n" >> $LOG4J_PROPS

    echo "log4j.appender.authorizerAppender=org.apache.log4j.DailyRollingFileAppender" >> $LOG4J_PROPS
    echo "log4j.appender.authorizerAppender.DatePattern='.'yyyy-MM-dd-HH" >> $LOG4J_PROPS
    echo "log4j.appender.authorizerAppender.File=$KAFKA_LOG_DIR/kafka-authorizer.log" >> $LOG4J_PROPS
    echo "log4j.appender.authorizerAppender.layout=org.apache.log4j.PatternLayout" >> $LOG4J_PROPS
    echo "log4j.appender.authorizerAppender.layout.ConversionPattern=[%d] %p %m (%c)%n" >> $LOG4J_PROPS

    echo "# Change the two lines below to adjust ZK client logging" >> $LOG4J_PROPS
    echo "log4j.logger.org.I0Itec.zkclient.ZkClient=INFO" >> $LOG4J_PROPS
    echo "log4j.logger.org.apache.zookeeper=INFO" >> $LOG4J_PROPS

    echo "# Change the two lines below to adjust the general broker logging level" >> $LOG4J_PROPS 
    echo "# (output to server.log and stdout)" >> $LOG4J_PROPS
    echo "log4j.logger.kafka=INFO" >> $LOG4J_PROPS
    echo "log4j.logger.org.apache.kafka=INFO" >> $LOG4J_PROPS

    echo "# Change to DEBUG or TRACE to enable request logging" >> $LOG4J_PROPS
    echo "log4j.logger.kafka.request.logger=WARN, requestAppender" >> $LOG4J_PROPS
    echo "log4j.additivity.kafka.request.logger=false" >> $LOG4J_PROPS

    echo "# Uncomment the lines below and change log4j.logger.kafka.network.RequestChannel$" >> $LOG4J_PROPS 
    echo "# to TRACE for additional output related to the handling of requests" >> $LOG4J_PROPS
    echo "#log4j.logger.kafka.network.Processor=TRACE, requestAppender" >> $LOG4J_PROPS
    echo "#log4j.logger.kafka.server.KafkaApis=TRACE, requestAppender" >> $LOG4J_PROPS
    echo "#log4j.additivity.kafka.server.KafkaApis=false" >> $LOG4J_PROPS
    echo "log4j.logger.kafka.network.RequestChannel$=WARN, requestAppender" >> $LOG4J_PROPS
    echo "log4j.additivity.kafka.network.RequestChannel$=false" >> $LOG4J_PROPS

    echo "log4j.logger.kafka.controller=TRACE, controllerAppender" >> $LOG4J_PROPS
    echo "log4j.additivity.kafka.controller=false" >> $LOG4J_PROPS

    echo "log4j.logger.kafka.log.LogCleaner=INFO, cleanerAppender" >> $LOG4J_PROPS
    echo "log4j.additivity.kafka.log.LogCleaner=false" >> $LOG4J_PROPS

    echo "log4j.logger.state.change.logger=TRACE, stateChangeAppender" >> $LOG4J_PROPS
    echo "log4j.additivity.state.change.logger=false" >> $LOG4J_PROPS

    echo "# Change to DEBUG to enable audit log for the authorizer" >> $LOG4J_PROPS
    echo "log4j.logger.kafka.authorizer.logger=WARN, authorizerAppender" >> $LOG4J_PROPS
    echo "log4j.additivity.kafka.authorizer.logger=false" >> $LOG4J_PROPS
    
    echo "Wrote log4j configuration to $LOG4J_PROPS"
}


validate_env && create_config && create_log4j_props



