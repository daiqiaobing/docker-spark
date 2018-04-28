FROM daocloud.io/library/ubuntu:14.04.1
MAINTAINER Getty Images "https://github.com/gettyimages"

RUN apt-get update 


RUN apt-get install -y curl unzip \
    python3 python3-setuptools openssh-server openssh-client openssl 



# 2. 同时配置SSH免密钥登陆
RUN    ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    
ADD conf/ssh/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config && \
    chown root:root /root/.ssh/config
 
 
# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

RUN apt-get install -y python-software-properties software-properties-common
 
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/*
  
 
# HADOOP
ENV HADOOP_VERSION 2.8.3
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
RUN  wget "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz"
RUN tar -zxvf hadoop-$HADOOP_VERSION.tar.gz  -C  /usr/
RUN rm -rf $HADOOP_HOME/share/doc && chown -R root:root $HADOOP_HOME

# SPARK
ENV SPARK_VERSION 2.3.0
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN wget "http://mirrors.hust.edu.cn/apache/spark/spark-2.3.0/spark-2.3.0-bin-without-hadoop.tgz"  
RUN tar -zxvf  spark-2.3.0-bin-without-hadoop.tgz -C /usr/
RUN mv /usr/$SPARK_PACKAGE $SPARK_HOME  && chown -R root:root $SPARK_HOME

WORKDIR $SPARK_HOME
CMD ["bin/spark-class", "org.apache.spark.deploy.master.Master"]
