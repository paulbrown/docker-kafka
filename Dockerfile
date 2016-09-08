FROM paulbrown/base:latest

ENV SCALA_VERSION 2.11

COPY confluent.repo /etc/yum.repos.d/confluent.repo

RUN yum upgrade --quiet --assumeyes && yum clean all

RUN yum install --quiet --assumeyes java-headless confluent-kafka-${SCALA_VERSION} && yum clean all

EXPOSE 9092

VOLUME /data

COPY kafka.properties /etc/kafka/kafka.properties

COPY onStart.sh /onStart.sh

ENTRYPOINT ["/onStart.sh"]
