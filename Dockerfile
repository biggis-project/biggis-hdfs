FROM biggis/base:oraclejava8-jre

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

ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION \
    HADOOP_CONF_DIR=/etc/hadoop \
    MULTIHOMED_NETWORK=1 \
    HDFS_CONF_dfs_namenode_name_dir=file:///opt/hadoop/dfs/name \
    HDFS_CONF_dfs_datanode_data_dir=file:////opt/hadoop/dfs/data

RUN set -x && \
    apk add --no-cache perl && \
    apk --update add --virtual build-dependencies curl && \
    curl -sS http://apache.mirrors.pair.com/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz | tar -xzf - -C /opt && \
    ln -s /opt/hadoop-$HADOOP_VERSION/etc/hadoop /etc/hadoop && \
    cp /etc/hadoop/mapred-site.xml.template /etc/hadoop/mapred-site.xml && \
    mkdir -p /opt/hadoop-$HADOOP_VERSION/logs /opt/hadoop/dfs/name /opt/hadoop/dfs/data && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/*

ENV PATH $HADOOP_HOME/bin:$PATH
ENV HADOOP_COMMON_LIB_NATIVE_DIR $HADOOP_HOME/lib/native/
ENV HADOOP_OPTS="$HADOOP_OPTS -Djava.library.path=$HADOOP_HOME/lib/native"

ADD start.sh $HADOOP_HOME/bin/

VOLUME /opt/hadoop/dfs/name
VOLUME /opt/hadoop/dfs/data

WORKDIR $HADOOP_HOME

CMD ["start.sh", "sh", "-c"]
