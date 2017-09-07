# BigGIS HDFS
[![Build Status](https://api.travis-ci.org/biggis-project/biggis-hdfs.svg)](https://travis-ci.org/biggis-project/biggis-hdfs)
Docker container for Apache Hadoop


## Prerequisites
Docker Compose >= 1.9.0

## Deployment
Spinning up HDFS namenode, secondary namenode and datanode
```sh
docker-compose up -d
```
## Upload Data to Hadoop (hdfs client)
The image ```biggis/hdfs-client:2.7.1``` can be used in order to interact with HDFS. Edit the ```HADOOP_MASTER_ADDRESS``` in the ```docker-compose.client.yml``` according to your setup and specify what ```hdfs dfs``` command you want to execute, e.g. copying a file (```hamlet.txt```) from you local host to the HDFS container cluster.

Upload local files:
```yaml
version: '2.1'

services:
  hdfs-client:
    image: biggis/hdfs-client:2.7.1
    command: upload.sh -copyFromLocal /data/hdfs/hamlet.txt /
    environment:
      USER_ID: ${USER_ID-1000}
      USER_NAME: hdfs
      #REMOTE_URL: http://landsat-pds.s3.amazonaws.com/L8/107/035/LC81070352015218LGN00/LC81070352015218LGN00_B3.TIF
      HADOOP_MASTER_ADDRESS: hdfs-name
      TIMEZONE: Europe/Berlin
    volumes:
      - ./data/hamlet.txt:/data/hdfs/hamlet.txt
```

Upload remote files:
```yaml
version: '2.1'

services:
  hdfs-client:
    image: biggis/hdfs-client:2.7.1
    command: upload.sh -copyFromLocal /data/hdfs /
    environment:
      USER_ID: ${USER_ID-1000}
      USER_NAME: hdfs
      REMOTE_URL: http://landsat-pds.s3.amazonaws.com/L8/107/035/LC81070352015218LGN00/LC81070352015218LGN00_B3.TIF
      HADOOP_MASTER_ADDRESS: hdfs-name
      TIMEZONE: Europe/Berlin
    # volumes:
    #   - ./data/hamlet.txt:/data/hdfs/hamlet.txt
```
Then run the ```docker-compose.client.yml``` file as following.
```sh
docker-compose -f docker-compose.client.yml run --rm hdfs-client
```

## Upload Data To Hadoop (webhdfs client)
Build the webhdfs Docker container.
```
docker build -t webdfs -f Dockerfile.webhdfs .
```
Run the container to upload the Hadoop image in webhdfs folder.
```
docker run -ti --rm --net=biggishdfs_default webhdfs
```

## Ports
- HDFS WebUI is running on port `50070`
