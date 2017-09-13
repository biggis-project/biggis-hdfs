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
      - ../data/hamlet.txt:/data/hdfs/hamlet.txt
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
    #   - ../data/hamlet.txt:/data/hdfs/hamlet.txt
```
Then run the ```docker-compose.client.yml``` file as following.
```sh
docker-compose -f docker-compose.client.yml run --rm hdfs-client
```

## Upload Data To Hadoop (webhdfs client)
Edit the node script in `webhdfs/webhdfs-test.js` and build the image. Run the container to upload the Hadoop image in webhdfs folder.
```yaml
version: '2.1'

services:
  hdfs-client:
    image: biggis/hdfs-client-webhdfs:2.7.1
```
Then run the `docker-compose.webhdfs.yml` file as following.
```sh
docker-compose -f docker-compose.webhdfs.yml run --rm hdfs-client-webhdfs
```