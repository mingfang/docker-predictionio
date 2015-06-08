FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

#Runit
RUN apt-get install -y runit
CMD /usr/sbin/runsvdir-start

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq

#Install Oracle Java 7
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java7-installer
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

#Spark
RUN wget -O - http://d3kbcqa49mib13.cloudfront.net/spark-1.3.1-bin-hadoop2.6.tgz | tar zx
RUN mv spark* spark

#ElasticSearch
RUN wget -O - https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.4.tar.gz | tar zx
RUN mv elasticsearch* elasticsearch

#HBase
RUN wget -O - http://archive.apache.org/dist/hbase/hbase-1.0.0/hbase-1.0.0-bin.tar.gz  | tar zx
RUN mv hbase* hbase
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-7-oracle" >> /hbase/conf/hbase-env.sh

RUN apt-get update

#Python SDK
RUN apt-get install -y python-pip
RUN pip install pytz
RUN pip install predictionio

#For Spark MLlib
RUN apt-get install -y libgfortran3

#PredictionIO
RUN wget -O - http://download.prediction.io/PredictionIO-0.9.3.tar.gz | tar zx
RUN mv PredictionIO* PredictionIO
ENV PIO_HOME /PredictionIO
ENV PATH $PATH:$PIO_HOME/bin
RUN sed -i 's|SPARK_HOME=$PIO_HOME/vendors/spark-1.3.1-bin-hadoop2.6|SPARK_HOME=/spark|' /PredictionIO/conf/pio-env.sh

#cache libraries
#RUN cp -r $PIO_HOME/templates/scala-parallel-recommendation Dummy && \
#    cd Dummy && \
#    $PIO_HOME/sbt/sbt package && \
#    cd .. && \
#    rm -rf Dummy

#Add runit services
ADD sv /etc/service 

#Test
RUN runsvdir-start & \
    while ! nc -vz localhost 7070;do sleep 3; done && \
    pio status

#Quickstart App, http://docs.prediction.io/0.8.2/recommendation/quickstart.html
#ADD quickstartapp quickstartapp
