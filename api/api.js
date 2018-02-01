// call the packages we need
var express    = require('express');
var basicAuth  = require('basic-auth-connect');
var multer     = require('multer');
var webhdfs    = require('webhdfs');
var fs         = require('fs');
var path       = require('path');
var http       = require('http');
var bodyParser = require('body-parser');

var hdfsHost = process.env.HADOOP_MASTER_ADDRESS || 'hdfs-name';
var port = process.env.PORT || 3000;
var authUser = process.env.USERNAME || 'hdfs'
var authPassword = process.env.PASSWORD || 'password'

var app = express();

app.use(bodyParser.json());
app.use(basicAuth(authUser, authPassword));

var router = express.Router();
var hdfs = webhdfs.createClient({ host: hdfsHost, port: '50070' });

var storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, '/tmp/')
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname)
  }
});

// ----------------------------------------------------------------------------
// Routes
// ----------------------------------------------------------------------------
router.get('/', function(req, res) {
    res.json({
      message: 'Hooray! welcome to our api!'
    });
});

// upload files
// curl -u hdfs:password \
//      -F 'file=@your_file.png' \
//      http://localhost:3000/api/v1/upload/files?hdfspath=/path/to/your/files
//
// curl -u hdfs:password \
//      -F 'file=@your_file1.png' \
//      -F 'file=@your_file2.png' \
//      http://localhost:3000/api/v1/upload/files?hdfspath=/path/to/your/files
router.post('/v1/upload/files', function(req, res) {

  if(!req.param('hdfspath')) {
    res.json({
      message: "Specify hdfspath: /v1/upload/files?hdfspath=/path"
    });
  }
  else {
    var upload = multer({
      storage: storage
    }).array('file');

    upload(req, res, function(err) {
      // get HDFS storage location
      var hdfsPath = req.param('hdfspath');

      var files = [].concat(req.files);
      for(var i = 0; i < files.length; i++){

        hdfsUpload(files[i].path, hdfsPath + '/' + files[i].filename, hdfsPath, res)

      }
    });
  }
});

// upload spark jobs
// curl -u hdfs:password \
//      -F 'job=@your_jar.jar' \
//      http://localhost:3000/api/v1/upload/jobs?hdfspath=/path/to/your/jobs
//
// curl -u biggis:biggis \
//      -F 'job=@your_jar1.jar' \
//      -F 'job=@your_jar2.jar' \
//      http://localhost:3000/api/v1/upload/jobs?hdfspath=/path/to/your/jobs
router.post('/v1/upload/jobs', function(req, res) {

  if(!req.param('hdfspath')) {
    res.json({
      message: "Specify hdfspath: /v1/upload/jobs/spark?hdfspath=/path"
    });
  }
  else {
    var upload = multer({
      storage: storage,
      // TODO: Support validation in case of multiple file uploads
      fileFilter: function (req, file, cb){
        var extension = path.extname(file.originalname);
        if(extension !== '.jar') {
          return cb(res.json({ message: 'Only jar-files are allowed' }), null)
        }
        cb(null, true)
      }
    }).array('job');

    upload(req, res, function(err) {
      // get HDFS storage location
      var hdfsPath = req.param('hdfspath');

      var files = [].concat(req.files);
      for(var i = 0; i < files.length; i++){

        hdfsUpload(files[i].path, hdfsPath + '/' + files[i].filename, hdfsPath, res)
      }
    });
  }
});

// Download remote files and Upload to HDFS
// curl -u hdfs:password \
//      -d '{"url": "your_url", "hdfspath": "/path/to/your/files"}' \
//      -H "Content-Type: application/json" \
//      -X POST http://localhost:3000/api/v1/upload/remote
router.post('/v1/upload/remote', function(req, res) {

  var url = req.body.url;
  var hdfsPath = req.body.hdfspath;
  var fileName = path.basename(url);

  downloadFile(url, hdfsPath, fileName, res);
});

router.get("/v1/download", function(req, res) {
  var qpath = req.param('hdfspath');
  
  if(!qpath) {
    res.json({
      message: "Specify hdfspath: /v1/download/files?hdfspath=/path"
    });
  }
  
  var remoteFileStream = hdfs.createReadStream(qpath);
  var data = [];
  var error = false;

  remoteFileStream.once("error", function onError(err) {
    res.writeHead(500, {
      "Content-Type": "application/json"
    });

    res.end(JSON.stringify(err));
    error = true;
    
  });


  remoteFileStream.on("data", function(chunk) {
    data.push(chunk)
  })

  remoteFileStream.once("finish", function onFinish() {
    if (!error) {
      filename = qpath.substr(qpath.lastIndexOf("/")+1, qpath.length)
      res.writeHead(200, {
        "Content-Disposition": "attachment; filename="+filename
      });
      res.write(Buffer.concat(data));
      res.end();
    }
  })
});


router.get("/v1/data/list", function(req, res) {
  var qpath = req.param('hdfspath');

  hdfs.readdir(qpath,function(err,files) {
    if (err) {
      res.writeHead(500,{
        "Content-Type": "application/json"
      });
      res.write(JSON.stringify({
        message: "Cannot read given file path or directory"
      }));
    } else {
      res.writeHead(200,{
        "Content-Type": "text/plain"
      });
      for (var index in files) {
        var file = files[index]
        qpath = qpath.replace(/\/$/,"");

        if (file.type == "FILE") {
          res.write("http://"+req.headers.host+"/api/v1/download?hdfspath="+qpath+"/"+file.pathSuffix+"\n");
        }
      }
    }
    
    res.end();
  });
});

router.get("/v1/data/describe", function(req, res) {
  var qpath = req.param('hdfspath');
  hdfs.readdir(qpath,function(err,files) {
    if (err) {
      res.writeHead(500,{
        "Content-Type": "application/json"
      });
      res.write(JSON.stringify({
        message: "Cannot read given file path or directory"
      }));
    } else {
      res.writeHead(200,{
        "Content-Type": "application/json"
      });
      res.write(JSON.stringify(files));
    }
    res.end();
  });
});
// ----------------------------------------------------------------------------
// Helper functions
// ----------------------------------------------------------------------------
function hdfsUpload(filePath, hdfsFilePath, hdfsPath, res){
  var failure=false;
  // var filePath = file.path;
  // var hdfsFilePath = hdfsPath + "/" + file.filename;

  var local = fs.createReadStream(filePath);
  var remote = hdfs.createWriteStream(hdfsFilePath);

  local.pipe(remote);

  remote.on('error', (err) => {
    console.error(err)
    failure = true;
  });

  remote.on('finish', () => {
    if (!failure) {
      res.json({
        message: "File(s) uploaded to HDFS. See: hdfs://" + hdfsPath
      });
      console.log("File uploaded complete. Local: " + filePath + " -> HDFS: hdfs://" + hdfsFilePath)
      console.log('Delete local file ' + filePath);
      //Delete intermediate files in container
      fs.unlink(filePath, function(error) {
        if (error) {
            throw error;
        }
      });
    } else {
      res.writeHead(500, {
        "Content-Type": "application/json"
      });
      res.end({
        message: "File upload canceled due to an internal error."
      });
      
    }
  });

}

function downloadFile(url, hdfsPath, fileName, res, cb) {
  var filePath = '/tmp/' + fileName;
  var hdfsFilePath = hdfsPath + '/' + fileName;
  var file = fs.createWriteStream(filePath);
  var request = http.get(url, function(response) {
    response.pipe(file);
    file.on('finish', function() {
      file.close(cb);
      console.log("File downloaded. See: " + filePath)
      hdfsUpload(filePath, hdfsFilePath, hdfsPath, res);
    });
  });
}

app.use('/api', router);

app.listen(port);
console.log('Magic happens on port ' + port);
