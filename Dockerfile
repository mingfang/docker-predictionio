FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc

#Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#Spark
RUN wget -O - http://d3kbcqa49mib13.cloudfront.net/spark-1.4.1-bin-hadoop2.6.tgz | tar zx
RUN mv spark* spark

#ElasticSearch
RUN wget -O - https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.4.tar.gz | tar zx
RUN mv elasticsearch* elasticsearch

#HBase
RUN wget -O - http://archive.apache.org/dist/hbase/hbase-1.0.0/hbase-1.0.0-bin.tar.gz  | tar zx
RUN mv hbase* hbase
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> /hbase/conf/hbase-env.sh 
ADD hbase-site.xml /hbase/conf/


RUN apt-get update

#Python SDK
RUN apt-get install -y python-pip
RUN pip install pytz
RUN pip install predictionio

#For Spark MLlib
RUN apt-get install -y libgfortran3

#PredictionIO
RUN wget -O - http://download.prediction.io/PredictionIO-0.9.4.tar.gz | tar zx
RUN mv PredictionIO* PredictionIO
ENV PIO_HOME /PredictionIO
ENV PATH $PATH:$PIO_HOME/bin

RUN sed -i 's|SPARK_HOME=$PIO_HOME/vendors/spark-1.4.1-bin-hadoop2.6|SPARK_HOME=/spark|' /PredictionIO/conf/pio-env.sh

RUN sed -i "s|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=ELASTICSEARCH|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=LOCALFS|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=HBASE|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|PIO_STORAGE_SOURCES_PGSQL|# PIO_STORAGE_SOURCES_PGSQL|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|# PIO_STORAGE_SOURCES_LOCALFS|PIO_STORAGE_SOURCES_LOCALFS|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|# PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE|PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|# PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=.*|PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=/elasticsearch|" /PredictionIO/conf/pio-env.sh

RUN sed -i "s|# PIO_STORAGE_SOURCES_HBASE|PIO_STORAGE_SOURCES_HBASE|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|PIO_STORAGE_SOURCES_HBASE_HOME=.*|PIO_STORAGE_SOURCES_HBASE_HOME=/hbase|" /PredictionIO/conf/pio-env.sh
RUN sed -i "s|# HBASE_CONF_DIR=.*|HBASE_CONF_DIR=/hbase/conf|" /PredictionIO/conf/pio-env.sh

#Add runit services
ADD sv /etc/service 

ADD quickstartapp quickstartapp
