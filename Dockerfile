FROM ubuntu:16.04 as base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD bash -c 'export > /etc/envvars && /usr/sbin/runsvdir-start'

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh rsync gettext-base

#Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt install oracle-java8-unlimited-jce-policy && \
    rm -r /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle


#Spark
RUN wget -O - http://archive.apache.org/dist/spark/spark-2.2.2/spark-2.2.2-bin-hadoop2.7.tgz | tar zx
RUN mv /spark* /spark

#ElasticSearch
RUN wget -O - https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.2.tar.gz | tar zx
RUN mv /elasticsearch* /elasticsearch

#HBase
RUN wget -O - http://archive.apache.org/dist/hbase/1.2.7/hbase-1.2.7-bin.tar.gz | tar zx
RUN mv /hbase* /hbase
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> /hbase/conf/hbase-env.sh 

#Python SDK
RUN apt-get install -y python-pip
RUN pip install pytz
RUN pip install predictionio

#For Spark MLlib
RUN apt-get install -y libgfortran3 libatlas3-base libopenblas-base

#PredictionIO

RUN wget -O - http://archive.apache.org/dist/predictionio/0.12.1/apache-predictionio-0.12.1-bin.tar.gz | tar zx
RUN mv PredictionIO* /PredictionIO

RUN useradd elasticsearch
RUN chown -R elasticsearch /elasticsearch

ENV PIO_HOME /PredictionIO
ENV PATH $PATH:$PIO_HOME/bin

#Download SBT
#RUN /PredictionIO/sbt/sbt package 

#Configuration
RUN sed -i 's|SPARK_HOME=.*|SPARK_HOME=/spark|' /PredictionIO/conf/pio-env.sh
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

COPY hbase-site.xml /hbase/conf/
COPY hbase-env.sh /hbase/conf/
COPY quickstartapp quickstartapp

#Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
