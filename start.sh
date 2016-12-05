#!/bin/bash
set -eo pipefail


if [ -z "$1" ]; then
  echo "Select the role for this container in docker cmd 'namenode', 'datanode'"
  exit 1
else
  if [ $1 = "namenode" ]; then
    namedir=`echo $HDFS_CONF_dfs_namenode_name_dir | perl -pe 's#file://##'`
    if [ ! -d $namedir ]; then
      echo "Namenode name directory not found: $namedir"
      exit 2
    fi

    if [ -z "$CLUSTER_NAME" ]; then
      echo "Cluster name not specified"
      exit 2
    fi

    if [ "`ls -A $namedir`" == "" ]; then
      echo "Formatting namenode name directory: $namedir"
      $HADOOP_PREFIX/bin/hdfs --config $HADOOP_CONF_DIR namenode -format $CLUSTER_NAME
    fi

    $HADOOP_PREFIX/bin/hdfs --config $HADOOP_CONF_DIR namenode
  elif [ $1 = "datanode" ]; then
    datadir=`echo $HDFS_CONF_dfs_datanode_data_dir | perl -pe 's#file://##'`
    if [ ! -d $datadir ]; then
      echo "Datanode data directory not found: $dataedir"
      exit 2
    fi

    $HADOOP_PREFIX/bin/hdfs --config $HADOOP_CONF_DIR datanode
  else
    exec $@
  fi
fi
