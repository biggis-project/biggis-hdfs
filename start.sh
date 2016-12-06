#!/bin/bash
set -eo pipefail

export CORE_CONF_fs_defaultFS=${CORE_CONF_fs_defaultFS:-hdfs://`hostname -f`:8020}

# Helper functions
# credits to https://github.com/ITrust/docker-images/blob/master/hadoop/entrypoint.sh

function addProperty() {
  local path=$1
  local name=$2
  local value=$3

  local entry="<property><name>$name</name><value>$value</value></property>"
  local escapedEntry=$(echo $entry | sed 's/\//\\\//g')
  sed -i "/<\/configuration>/ s/.*/${escapedEntry}\n&/" $path
}

function configure() {
  local path=$1
  local module=$2
  local envPrefix=$3

  local var
  local value
  echo "Configuring $module"
  for c in `printenv | perl -sne 'print "$1 " if m/^${envPrefix}_(.+?)=.*/' -- -envPrefix=$envPrefix`; do
    name=`echo ${c} | perl -pe 's/__/-/g; s/__/_/g; s/_/./g'`
    var="${envPrefix}_${c}"
    value=${!var}
    echo " - Setting $name=$value"
    addProperty /etc/hadoop/$module-site.xml $name "$value"
  done
}

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

      configure /etc/hadoop/core-site.xml core CORE_CONF
      configure /etc/hadoop/hdfs-site.xml hdfs HDFS_CONF
      configure /etc/hadoop/yarn-site.xml yarn YARN_CONF
      configure /etc/hadoop/httpfs-site.xml httpfs HTTPFS_CONF
      configure /etc/hadoop/kms-site.xml kms KMS_CONF

      if [ "$MULTIHOMED_NETWORK" = "1" ]; then
        echo "Configuring for multihomed network"

        #HDFS
        addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.rpc-bind-host 0.0.0.0
        addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.servicerpc-bind-host 0.0.0.0
        addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.http-bind-host 0.0.0.0
        addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.https-bind-host 0.0.0.0
        addProperty /etc/hadoop/hdfs-site.xml dfs.client.use.datanode.hostname true
        addProperty /etc/hadoop/hdfs-site.xml dfs.datanode.use.datanode.hostname true

        #YARN
        addProperty /etc/hadoop/yarn-site.xml yarn.resourcemanager.bind-host 0.0.0.0
        addProperty /etc/hadoop/yarn-site.xml yarn.nodemanager.bind-host 0.0.0.0
        addProperty /etc/hadoop/yarn-site.xml yarn.timeline-service.bind-host 0.0.0.0

        #MAPREDUCE
        addProperty /etc/hadoop/mapred-site.xml yarn.nodemanager.bind-host 0.0.0.0
      fi

      echo "Formatting namenode name directory: $namedir"
      $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR namenode -format $CLUSTER_NAME
    fi

    $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR namenode
  elif [ $1 = "datanode" ]; then
    datadir=`echo $HDFS_CONF_dfs_datanode_data_dir | perl -pe 's#file://##'`
    if [ ! -d $datadir ]; then
      echo "Datanode data directory not found: $datadir"
      exit 2
    fi

    configure /etc/hadoop/core-site.xml core CORE_CONF
    configure /etc/hadoop/hdfs-site.xml hdfs HDFS_CONF
    configure /etc/hadoop/yarn-site.xml yarn YARN_CONF
    configure /etc/hadoop/httpfs-site.xml httpfs HTTPFS_CONF
    configure /etc/hadoop/kms-site.xml kms KMS_CONF

    if [ "$MULTIHOMED_NETWORK" = "1" ]; then
      echo "Configuring for multihomed network"

      #HDFS
      addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.rpc-bind-host 0.0.0.0
      addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.servicerpc-bind-host 0.0.0.0
      addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.http-bind-host 0.0.0.0
      addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.https-bind-host 0.0.0.0
      addProperty /etc/hadoop/hdfs-site.xml dfs.client.use.datanode.hostname true
      addProperty /etc/hadoop/hdfs-site.xml dfs.datanode.use.datanode.hostname true

      #YARN
      addProperty /etc/hadoop/yarn-site.xml yarn.resourcemanager.bind-host 0.0.0.0
      addProperty /etc/hadoop/yarn-site.xml yarn.nodemanager.bind-host 0.0.0.0
      addProperty /etc/hadoop/yarn-site.xml yarn.timeline-service.bind-host 0.0.0.0

      #MAPREDUCE
      addProperty /etc/hadoop/mapred-site.xml yarn.nodemanager.bind-host 0.0.0.0
    fi

    $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR datanode
  else
    exec $@
  fi
fi
