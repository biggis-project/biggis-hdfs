#!/usr/bin/env bash
#Credit: https://github.com/geodocker/geodocker-hdfs
set -eo pipefail

source /sbin/hdfs-lib.sh

template $HADOOP_CONF_DIR/core-site.xml
template $HADOOP_CONF_DIR/hdfs-site.xml

# The first argument determines wether this container runs as data, namenode or secondary namenode
if [ -z "$1" ]; then
  echo "[ $(date) ] Select the role for this container with the docker cmd 'name', 'sname', 'data'"
  exit 1
else
  if [ $1 = "name" ]; then
    if  [[ ! -f /data/hdfs/name/current/VERSION ]]; then
      echo "[ $(date) ] Formatting namenode root fs in /data/hdfs/name..."
      hdfs namenode -format
    fi
    exec hdfs namenode
  elif [ $1 = "sname" ]; then
    wait_until_hdfs_is_available
    exec hdfs secondarynamenode
  elif [ $1 = "data" ]; then
    exec hdfs datanode
  else
    exec "$@"
  fi
fi
