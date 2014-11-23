FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

#Runit
RUN apt-get install -y runit
CMD /usr/sbin/runsvdir-start

#SSHD
RUN apt-get install -y openssh-server && \
    mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd
RUN sed -i "s/session.*required.*pam_loginuid.so/#session    required     pam_loginuid.so/" /etc/pam.d/sshd
RUN sed -i "s/PermitRootLogin without-password/#PermitRootLogin without-password/" /etc/ssh/sshd_config

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

#Install Oracle Java 7
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java7-installer
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

#PredictionIO
RUN curl http://download.prediction.io/PredictionIO-0.8.2.tar.gz | tar zx
RUN mv PredictionIO* PredictionIO
ENV PIO_HOME /PredictionIO
ENV PATH $PATH:$PIO_HOME/bin

#cache libraries
RUN cp -r $PIO_HOME/templates/scala-parallel-recommendation Dummy && \
    cd Dummy && \
    $PIO_HOME/sbt/sbt package && \
    cd .. && \
    rm -rf Dummy

#Spark
RUN curl http://d3kbcqa49mib13.cloudfront.net/spark-1.1.0-bin-hadoop2.4.tgz | tar zx
RUN mv spark* spark
RUN sed -i 's|SPARK_HOME=/path_to_apache_spark|SPARK_HOME=/spark|' /PredictionIO/conf/pio-env.sh

#ElasticSearch
RUN curl https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.tar.gz | tar zx
RUN mv elasticsearch* elasticsearch

#HBase
RUN curl http://archive.apache.org/dist/hbase/hbase-0.98.6/hbase-0.98.6-hadoop2-bin.tar.gz | tar zx
RUN mv hbase* hbase
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-7-oracle" >> /hbase/conf/hbase-env.sh

RUN apt-get update

#Python SDK
RUN apt-get install -y python-pip
RUN pip install pytz
RUN pip install predictionio

#For Spark MLlib
RUN apt-get install -y libgfortran3

#Add runit services
ADD sv /etc/service 

#Quickstart App, http://docs.prediction.io/0.8.2/recommendation/quickstart.html
ADD quickstartapp quickstartapp
