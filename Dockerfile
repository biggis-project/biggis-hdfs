FROM biggis/base:java8-jre-alpine

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
      eu.biggis-project.vcs-url="https://github.com/biggis-project/biggis-flink" \
      eu.biggis-project.environment="dev" \
      eu.biggis-project.version=$HADOOP_VERSION

ENV HADOOP_PREFIX=/opt/hadoop-$HADOOP_VERSION \
    HADOOP_CONF_DIR=/etc/hadoop \
    MULTIHOMED_NETWORK=1 \
    HDFS_CONF_dfs_namenode_name_dir=file:///hadoop/dfs/name \
    HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/data

RUN set -x && \
    apk add --no-cache perl && \
    apk --update add --virtual build-dependencies curl && \
    curl -sS http://apache.mirrors.pair.com/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz | tar -xzf - -C /opt && \
    ln -s /opt/hadoop-$HADOOP_VERSION/etc/hadoop /etc/hadoop && \
    cp /etc/hadoop/mapred-site.xml.template /etc/hadoop/mapred-site.xml && \
    mkdir -p /opt/hadoop-$HADOOP_VERSION/logs /hadoop/dfs/name /hadoop/dfs/data && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/*

ENV PATH $HADOOP_PREFIX/bin:$PATH

ADD entrypoint.sh /opt/hadoop-$HADOOP_VERSION/bin/
ADD start.sh /opt/hadoop-$HADOOP_VERSION/bin/

VOLUME /hadoop/dfs/name
VOLUME /hadoop/dfs/data

WORKDIR /opt/hadoop-$HADOOP_VERSION

ENTRYPOINT ["entrypoint.sh"]
CMD ["start.sh", "sh", "-c"]
