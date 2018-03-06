# BigGIS HDFS
[![Build Status](https://api.travis-ci.org/biggis-project/biggis-hdfs.svg)](https://travis-ci.org/biggis-project/biggis-hdfs)
Docker container for Apache Hadoop


## Prerequisites
Docker Compose >= 1.9.0

## Deployment

**On local setup**:
```sh
docker-compose up -d
```

**On Rancher**:
* NFS server and Rancher NFS service need to be configured in the cluster. The NFS volumes `hdfs-namenode`, `hdfs-snamenode` and `hadoop-conf` need to be created via the Rancher WebUI.
* Add host labels `hdfs-name=true` & `hdfs-api=true` to any of your hosts.
* Create new HDFS stack `hdfs` via Rancher WebUI and deploy `docker-compose.rancher.yml`.

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

## Download Files from HDFS
The API will forward requests to the underlying HDFS WebAPI regarding file listing, description and download. In analogy to the upload functions we will use and pass on the *hdfspath* parameter for interaction with the files stored in the Hadoop cluster. The client needs to know beforehand how the data is organized on the backend, e.g. data is stored in a folder "data", results are under "results", etc. The user / client will be in controll to organize the filesystem structure on their own.

The following API is defined for lookup and download:
* `/api/v1/download?hdfspath=<path>` (GET)
* `/api/v1/data/list?hdfspath=<path>` (GET)
* `/api/v1/data/describe?hdfspath=<path>` (GET)

### General file download
In general the data can be downloaded by setting a valid hdfs path to the respective file. The response will contain in each case a single file as content disposition. Errors are returned as `application/json` with the status in the HTTP response and a message.

```sh
curl -u hdfs:password \
    http://localhost:3000/api/v1/download?hdfspath=/hdfspath/to/your/file.tif
```

### File lookup and listing
There are two additional API endpoints `describe` will use a *readdir* (read directory) call that lists information about a directory or a file as a JSON object. In principal this is equal to the object send from Hadoop WebAPI. 

```json
[
    {
        "accessTime": 1517482423444,
        "blockSize": 134217728,
        "childrenNum": 0,
        "fileId": 16389,
        "group": "supergroup",
        "length": 65958,
        "modificationTime": 1517472398925,
        "owner": "webuser",
        "pathSuffix": "utm_1.tif",
        "permission": "755",
        "replication": 3,
        "storagePolicy": 0,
        "type": "FILE"
    },
    {
        "accessTime": 1517498610919,
        "blockSize": 134217728,
        "childrenNum": 0,
        "fileId": 16391,
        "group": "supergroup",
        "length": 65958,
        "modificationTime": 1517472398934,
        "owner": "webuser",
        "pathSuffix": "utm_2.tif",
        "permission": "755",
        "replication": 3,
        "storagePolicy": 0,
        "type": "FILE"
    }
]
```

`list` on the other hand will only list downloadable files as a plain text list, e.g.

```
http://localhost:3000/api/v1/download?hdfspath=/test/test_1.tif
http://localhost:3000/api/v1/download?hdfspath=/test/test_2.tif
http://localhost:3000/api/v1/download?hdfspath=/test/test_3.tif
http://localhost:3000/api/v1/download?hdfspath=/test/test_4.tif
```

The latter function is intended to be used in combination with GDAL on the client. `gdalbuildvrt` is a handy tool to create a remote representation of a tiled data set. There is a parameter to import the tiles as a text file. At this point the `list` operation comes into play, which will provide exactly this.

Imagine the following scenario, where the process result is multi-band tiled raster data set. Then one can create a VRT like the following:

```sh
curl -u hdfs:password http://localhost:3000/api/v1/data/list?hdfspath=/test > tiles.txt
gdalbuildvrt --config GDAL_PROXY_AUTH=hdfs:password -input_file_list tiles.txt test.vrt
```

Note: depending on the URLs or files stated in the list, each entry will be opened by GDAL to extract metadata information. This means every file listed will be downloaded temporarily, but not stored on the clients computer. This is currently a drawback.

With the vrt file the user can download a subset using `gdal_translate` with the *GDAL_PROXY_AUTH* configuration. Here only those tiles affected are downloaded, e.g. tiles/urls are neglected that are not within a specified BBOX.

```sh
gdal_translate --config GDAL_PROXY_AUTH=hdfs:password -of GTiff test.vrt test.tif
```

See [gdal_translate](http://www.gdal.org/gdal_translate.html) for more information.


