FROM biggis/base:java8-jdk-alpine

MAINTAINER wipatrick

ARG HADOOP_VERSION=2.7.1
ARG BUILD_DATE
ARG VCS_REF

LABEL eu.biggis-project.build-date=$BUILD_DATE \
      eu.biggis-project.license="MIT" \
      eu.biggis-project.name="BigGIS" \
      eu.biggis-project.url="http://biggis-project.eu/" \
      eu.biggis-project.vcs-ref=$VCS_REF \
      eu.biggis-project.vcs-type="Git" \
      eu.biggis-project.vcs-url="https://github.com/biggis-project/biggis-hdfs" \
      eu.biggis-project.environment="dev" \
      eu.biggis-project.version=$HADOOP_VERSION

ENV HADOOP_HOME /opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR /etc/hadoop/conf
ENV PATH $HADOOP_HOME/bin:/sbin:$PATH
ENV HADOOP_COMMON_LIB_NATIVE_DIR $HADOOP_HOME/lib/native
ENV HADOOP_OPTS $HADOOP_OPTS -Djava.library.path=$HADOOP_HOME/lib/native
ENV LD_LIBRARY_PATH $HADOOP_HOME/lib/native

RUN set -x && \
    apk add --no-cache perl && \
    apk --update add --virtual build-dependencies curl && \
    curl -sS https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz | tar -xzf - -C /opt && \
    mkdir -p /etc/hadoop/conf && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/*

COPY ./files /
VOLUME ["/data/hdfs"]

CMD ["/sbin/start.sh"]
