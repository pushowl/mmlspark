#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM openjdk:8-alpine

ARG spark_jars=jars
ARG img_path=kubernetes/dockerfiles
ARG k8s_tests=kubernetes/tests


# Get Spark from US Apache mirror.
ENV APACHE_SPARK_VERSION 2.4.5
ENV HADOOP_VERSION 3.2.1

ENV SPARK_HOME=/opt/spark

RUN cd /tmp && \
    echo "Downloading Spark" && \
    wget http://apache.claz.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-without-hadoop.tgz -O spark.tgz && \
    echo "Download Hadoop" && \
    wget http://apache.claz.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -O hadoop.tar.gz

RUN set -ex && \
    apk upgrade --no-cache && \
    apk add --no-cache bash tini libc6-compat linux-pam && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/work-dir && \
    mkdir -p /opt && \
    cd /tmp && \
    tar -xzf spark.tgz && \
    mkdir -p /opt/spark && \
    mv spark-${APACHE_SPARK_VERSION}-bin-without-hadoop /tmp/spark_bin && \
    echo Spark ${APACHE_SPARK_VERSION} installed in /opt/spark && \
    cp -r /tmp/spark_bin/${spark_jars} /opt/spark/jars && \
    cp -r /tmp/spark_bin/bin /opt/spark/bin && \
    cp -r /tmp/spark_bin/sbin /opt/spark/sbin && \
    cp -r /tmp/spark_bin/${img_path}/spark/entrypoint.sh /opt/ && \
    cp -r /tmp/spark_bin/examples /opt/spark/examples && \
    cp -r /tmp/spark_bin/${k8s_tests} /opt/spark/tests && \
    cp -r /tmp/spark_bin/data /opt/spark/data && \
    cp -r /tmp/spark_bin/python /opt/spark/python && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    ln -sv /lib64/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2 && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -r /tmp/spark_bin && \
    tar -xzf hadoop.tar.gz && \
    mv /tmp/hadoop-${HADOOP_VERSION} /opt/hadoop && \
    echo "export HADOOP_CLASSPATH=/opt/hadoop/share/hadoop/tools/lib/*" >> /opt/hadoop/etc/hadoop/hadoop-env.sh && \
    echo Hadoop ${HADOOP_VERSION} installed in /opt/hadoop && \
    rm -rf /opt/hadoop/share/doc && \
    rm -f /tmp/spark.tgz /tmp/hadoop.tar.gz

ENV HADOOP_HOME=/opt/hadoop
RUN mkdir -p /opt/spark/conf && \
    echo "SPARK_DIST_CLASSPATH=/jars:/jars/*:$(/opt/hadoop/bin/hadoop classpath)" >> /opt/spark/conf/spark-env.sh

RUN apk add --no-cache python3 && \
    pip3 install --upgrade pip setuptools && \
    ln -sv /usr/bin/python3 /usr/bin/python && \
    rm -r /root/.cache

ADD jars /jars
ADD log4j.properties /opt/spark/conf/log4j.properties
ADD start-common.sh start-worker start-master /
ADD core-site.xml /opt/spark/conf/core-site.xml
ADD spark-defaults.conf /opt/spark/conf/spark-defaults.conf
ENV PATH $PATH:/opt/spark/bin
