FROM ubuntu
 
RUN echo 'deb http://archive.ubuntu.com/ubuntu precise main universe' > /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu precise-updates universe' >> /etc/apt/sources.list && \
    apt-get update

#Runit
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo

#MongoDB
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' > /etc/apt/sources.list.d/mongodb.list && \
    apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mongodb-org
RUN mkdir -p /data/db

#Install Oracle Java 7
RUN apt-get install -y python-software-properties && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java7-installer
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

#graphchi
RUN curl http://download.prediction.io/graphchi-cpp-cf/graphchi-cpp-cf-linux-x86_64-0a6545ccb7.tar.gz | tar xz

#Hadoop
RUN curl http://archive.apache.org/dist/hadoop/common/hadoop-1.2.1/hadoop-1.2.1-bin.tar.gz | tar xz

#PredictionIO
RUN wget http://download.prediction.io/PredictionIO-0.7.0.zip && \
    unzip PredictionIO*.zip && \
    rm PredictionIO*.zip

RUN cp /PredictionIO-0.7.0/conf/hadoop/* /hadoop-1.2.1/conf/
RUN echo "io.prediction.commons.settings.hadoop.home=/hadoop-1.2.1" >> /PredictionIO-0.7.0/conf/predictionio.conf
RUN /hadoop-1.2.1/bin/hadoop namenode -format

#Configuration
ADD . /docker
RUN ln -sf /docker/etc/mongod.conf /etc/

#Runit Automatically setup all services in the sv directory
RUN for dir in /docker/sv/*; do echo $dir; chmod +x $dir/run $dir/log/run; ln -s $dir /etc/service/; done

#Initialize
RUN runsvdir-start & \
    while ! nc -vz localhost 27017;do sleep 1; done && \
    cat /var/log/mongodb/current && \
    cd /PredictionIO-0.7.0 && \
    ./bin/settingsinit conf/init.json
RUN rm /var/run/*.pid

ENV HOME /root
WORKDIR /root
EXPOSE 22
