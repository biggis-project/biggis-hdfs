# BigGIS HDFS
[![Build Status](https://api.travis-ci.org/biggis-project/biggis-hdfs.svg)](https://travis-ci.org/biggis-project/biggis-hdfs)
Docker container for Apache Hadoop


## Prerequisites
Docker Compose >= 1.9.0

## Deployment
Spinning up HDFS namenode, secondary namenode, datanode and hdfs-api
```sh
docker-compose up -d
```

## Upload Files to HDFS
To upload files (local or remote) simply use the API-service provided in this project.
The following endpoints are available:
* `/api/v1/upload/files` (POST)
* `/api/v1/upload/remote` (POST)
* `/api/v1/upload/jobs` (POST)

## Example: Upload `hamlet.txt` to HDFS
Once all containers are up and running, execute the following curl command:
```sh
curl -u hdfs:password \
     -F 'file=@data/hamlet.txt' \
     -X POST http://localhost:3000/api/v1/upload/files?hdfspath=/demo/hamlet.txt
     
{"message":"File(s) uploaded to HDFS. See: hdfs:///demo/hamlet.txt"}
```

## Ports
- HDFS WebUI is running on port `50070`
- HDFS API is running on port `3000`

## Using the API
#### Upload arbitrary local files to HDFS
For a single file:
```sh
curl -u hdfs:password \
     -F 'file=@your_file.png' \
     -X POST http://localhost:3000/api/v1/upload/files?hdfspath=/path/to/your/files
```
For multiple files:
```sh
curl -u hdfs:password \
     -F 'file=@your_file1.png' \
     -F 'file=@your_file2.png' \
     -X POST http://localhost:3000/api/v1/upload/files?hdfspath=/path/to/your/files
```

#### Upload local Spark Jobs to HDFS
For a single job:
```sh
curl -u hdfs:password \
     -F 'job=@your_jar.jar' \
     -X POST http://localhost:3000/api/v1/upload/jobs?hdfspath=/path/to/your/jobs
```
For multiple jobs:
```sh
curl -u hdfs:password \
     -F 'job=@your_jar1.jar' \
     -F 'job=@your_jar2.jar' \
     -X POST http://localhost:3000/api/v1/upload/jobs?hdfspath=/path/to/your/jobs
```

#### Upload remote files to HDFS
```sh
curl -u hdfs:password \
     -d '{"url": "your_url", "hdfspath": "/path/to/your/files"}' \
     -H "Content-Type: application/json" \
     -X POST http://localhost:3000/api/v1/upload/remote
```
