FROM ubuntu:14.04
 
RUN apt-get update

#Runit
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd
RUN sed -i "s/session.*required.*pam_loginuid.so/#session    required     pam_loginuid.so/" /etc/pam.d/sshd
RUN sed -i "s/PermitRootLogin without-password/#PermitRootLogin without-password/" /etc/ssh/sshd_config

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

#Install Oracle Java 7
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java7-installer


#MongoDB
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' > /etc/apt/sources.list.d/mongodb.list && \
    apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mongodb-org
RUN mkdir -p /data/db


#graphchi
RUN curl http://download.prediction.io/graphchi-cpp-cf/graphchi-cpp-cf-linux-x86_64-0a6545ccb7.tar.gz | tar xz

#Hadoop
RUN curl http://archive.apache.org/dist/hadoop/common/hadoop-1.2.1/hadoop-1.2.1-bin.tar.gz | tar xz

#PredictionIO
RUN wget http://download.prediction.io/PredictionIO-0.7.1.zip && \
    unzip PredictionIO*.zip && \
    rm PredictionIO*.zip
RUN mv PredictionIO* PredictionIO

ENV JAVA_HOME /usr/lib/jvm/java-7-oracle
RUN cp /PredictionIO/conf/hadoop/* /hadoop-1.2.1/conf/
RUN echo "io.prediction.commons.settings.hadoop.home=/hadoop-1.2.1" >> /PredictionIO/conf/predictionio.conf
RUN /hadoop-1.2.1/bin/hadoop namenode -format

#Add runit services
ADD sv /etc/service 

#Configuration
ADD etc/mongod.conf /etc/

#Initialize
RUN runsvdir-start & \
    while ! nc -vz localhost 27017;do sleep 3; done && \
    cat /var/log/mongodb/current && \
    cd /PredictionIO && \
    ./bin/settingsinit conf/init.json
RUN rm /var/run/*.pid
