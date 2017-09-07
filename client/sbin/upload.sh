#!/usr/bin/env bash
set -eo pipefail

function bootstrap {
  # Run in all cases
  if [ ! -v ${HADOOP_MASTER_ADDRESS} ]; then
    source /sbin/hdfs-lib.sh

    template $HADOOP_CONF_DIR/core-site.xml
    template $HADOOP_CONF_DIR/hdfs-site.xml

    sed -i.bak "s/{HADOOP_MASTER_ADDRESS}/${HADOOP_MASTER_ADDRESS}/g" ${HADOOP_CONF_DIR}/core-site.xml
  fi

  if [ -z ${REMOTE_URL} ]; then
    wget $REMOTE_URL -P /data/hdfs
  fi
}

function usage {
  echo "Usage: docker-compose -f docker-compose.client.yml run --rm hdfs-client execute.sh [ command ]"
}

if [ $# -eq 0 ]; then
  echo "[ $(date) ] Specify hdfs dfs command arguments"
  usage
else
  bootstrap
  echo "[ $(date) ] hdfs dfs "$@" will be executed"
  exec hdfs dfs "$@"
fi
