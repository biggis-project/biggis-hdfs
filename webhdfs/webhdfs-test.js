// this is the content of file: webhdfs-test.js
const WebHDFS = require('webhdfs');

const hdfs = WebHDFS.createClient({
  host: 'hdfs-name',
  port: '50070'
});

const fs = require('fs');

const local = fs.createReadStream('hadoop.jpg');
const remote = hdfs.createWriteStream('/hadoop.jpg');

local.pipe(remote);

remote.on('error', (err) => {
  console.error(err)
});

remote.on('finish', () => {
  console.log("on finish")
});
