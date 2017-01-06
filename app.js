var express = require('express')
,   fs = require('fs')
,   http = require('http')
,   path = require('path')
,   async = require('async')
,   mime = require('mime')
,   exec = require('child_process').exec
,   isWin = /^win/.test(process.platform)
,   config = require('./config')
;

var uploadImage = express.bodyParser({
    uploadDir: './public/img',
    keepExtensions: true
});



var app = express();

// all environments
app.set('port', process.env.PORT || 3000);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
/*
app.use(function(req, res, next) {
    req.rawBody = '';
    req.on('data', function(chunk) {
        req.rawBody += chunk;
    });
    req.on('end', function() {
        console.log('[Debug] Raw Request!');
        var label = '5';
        var ts = +new Date();
        var path = './public/img/'+ts+'-'+label+'.png';
        fs.writeFile(path, req.rawBody, function (err) {
            if (err) throw err;
            console.log('[Debug] Image saved to '+path);

            next();
            //res.send({ageGroup: label});
        });
    });
});
*/
//app.use(express.bodyParser());
app.use(uploadImage);
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));


var AGE_GROUP = {
    0: '20-29',
    1: '30-39',
    2: '40-49',
    3: '50-59',
    4: '60+',
    5: '15-19'
};

var getLabelFromImagePath = function(fpath) {
    var name = fpath.split('.')[0];

    var label = '-5';
    // ex: xxxxx-xxx-[0-5].jpg
    if (name.indexOf('-') > -1) {
        label = name.split('-').slice(-1)[0];
    }
    else if (name.indexOf('_') > -1) {
        label = name.split('_').slice(-1)[0];
    }
    return label;
}

var getIdFromImagePath = function(fpath) {
    var name = fpath.split('/').slice(-1);
    name = name[0].split('.')[0];

    var id = '';
    // ex: xxxxx-xxx-[0-5].jpg
    if (name.indexOf('-') > -1) {
        id = name.split('-')[0];
    }
    else if (name.indexOf('_') > -1) {
        id = name.split('_')[0];
    }
    return id;
}

app.get('/', function(req, res) {
    var files = fs.readdirSync('./public/img/');
    var images = [];
    //files.map(function(v) { return 'img/'+v; });
    for (var i = 0; i < files.length; i++) {
        if (mime.lookup(files[i]).split('/')[0] != 'image')
            continue;

        var label = getLabelFromImagePath(files[i]);
        if (parseInt(label, 10) < 0) continue;
        var group = AGE_GROUP[label];
        images.push({
            path: 'img/'+files[i],
            group: group
        });
    }
    console.log(images);
    res.render('index', {images: images});
});

var ageEstimation = function (ts, imagePath, cb) {
    var featuresPath;
    extractFeature(ts, imagePath, function (e1, _featuresPath) {
        if (e1) throw e1;
        featuresPath = _featuresPath;
    });

    var label = '-2';
    setTimeout( function () {
        estimateAge(featuresPath, function (e2, _label) {
            if (e2) throw e2;
            label = _label;
            // return
            cb(null, label);
        })
    }, 30000); // 5 seconds mb 20?
};


var extractFeature = function(ts, imagePath, callback) {
    // launch image preproccessor
    var featuresPath = config.feature_dir + '/' + ts + '.txt';
    var matlabCmd = "start matlab -minimize -nodisplay -nosplash -nodesktop -r age_estimation('../"+ imagePath + "\','../" + featuresPath + "\')";
/* 	var matlabCmd = "matlab " + (isWin ? "-minimize" : "") + " -nodisplay -nosplash -nodesktop -r \"try, cd(\'" + 
                    config.img_proc_dir +"\'), " + config.img_proc + 
                    "(\'..\/" + imagePath + "\', \'..\/" + featuresPath + "\')" +
                    ", catch, exit(1), end, exit(0)\""
    ;
    if (isWin) matlabCmd = 'start ' + matlabCmd + ' -logfile log_matlab.txt'; */
	
    console.log('[DEBUG] Now running \"' + matlabCmd + '\" ...');
    var childImagePreproccessor = exec(matlabCmd, function(e, stdout, stderr) {
        if (e != null) {
            console.log('[Error] matlab error: ' + e);
            callback(e);
        }
        if (stdout)
            console.log('[Debug] stdout: ' + stdout);
        if (stderr)
            console.log('[Debug] stderr: ' + stderr);

    });

    childImagePreproccessor.on('exit', function(code, signal) {
        if (code == null) throw new Error('matlab was aborted: ' + code);
        console.log('[DEBUG] leave matlab: ' + code);
        // return result
        callback(null, featuresPath);
    });
}

var estimateAge = function (featuresPath, callback) {
    // launch svm-predict
    var labelPath = config.label_dir + '/' + featuresPath.split('/').slice(-1);
    var svmPredictCmd = 'svm-predict ' + featuresPath + ' ' + config.model + ' ' + labelPath;
	
	console.log('[DEBUG] Now running \"' + svmPredictCmd + '\" ...');
    var childAgeEstimation = exec(svmPredictCmd, function(e, stdout, stderr) {
        if (e != null) {
            console.log('[Error] svm-predict error: ' + e);
            callback(e);
        }
        if (stdout)
            console.log('[Debug] stdout: ' + stdout);
        if (stderr)
            console.log('[Debug] stderr: ' + stderr);
    });

    childAgeEstimation.on('exit', function(code, signal) {
        if (code == null) throw new Error('svm-predict was aborted: ' + code);
        console.log('[DEBUG] leave svm-predict: ' + code);
        setTimeout( function () {
            // fetch result and return
            var label = fs.readFileSync(labelPath, config.encoding).trim();
            callback(null, label);
        }, 3000);
    });
}

app.get('/age/:id', function(req, res) {
    var imageId = req.params.id;
    if (imageId == null) return res.status(404);

    console.log('[DEBUG] Looking for image: ' + imageId);

    var files = fs.readdirSync('./public/img/');
    var label = '-3';
    //files.map(function(v) { return 'img/'+v; });
    for (var i = 0; i < files.length; i++) {
        if (mime.lookup(files[i]).split('/')[0] != 'image')
            continue;

        var name = files[i].split('/').slice(-1);
        var id = getIdFromImagePath(files[i]);
        console.log('[DEBUG] Image: ' + id + ' @ ' + files[i]);
        if (id != null && id === imageId) {
            label = getLabelFromImagePath(files[i]);
            break;
        }

    }
    if (parseInt(label, 10) < 0) return res.status(404);

    // send predicted age
    res.send({ageGroup: label});
});

app.post('/age', function(req, res) {

    /*
    req.form.on('progress', function(bytesReceived, bytesExpected) {
        console.log(((bytesReceived / bytesExpected)*100) + "% uploaded");
    });
    */
    //console.log('[Debug] files: ' + JSON.stringify(req.files));
    if (req.files && req.files.image) {
        var ts = +new Date();
        var tmpPath = req.files.image.path;
        var ext = tmpPath.split('.').slice(-1);

        // (1) send back image id
        res.send({imageId: ts});

        // (2) do age estimation
        var label = '-4';
        ageEstimation(ts, tmpPath, function (e, _label) {
            if (e) throw e;
            console.log('[DEBUG] Age Estimation completed! ' + _label);
            label = _label;
        });
		
        setTimeout(function () {
            if (parseInt(label, 10) < 0) {
                return console.log('[Error] No label: ' + label);
            }

            var group = AGE_GROUP[label];
            console.log('[DEBUG] classified label: ' + label);
            console.log('[DEBUG] Estimated age: ' + group);

            var path = './public/img/' + ts + '-' + label + '.' + ext;
            console.log('[DEBUG] Image is saved to ' + path);
            fs.renameSync(tmpPath, path);

        }, 50000); // wait for 10 seconds but mb 30?
    }
    else 
        res.status(400);
});


// catch 404 and forwarding to error handler
app.use(function(req, res, next) {
    var err= new Error('Not found');
    err.status = 404;
    next(err);
});

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
    res.render('error', {
        message: err.message,
        error: {}
    });
});



http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});
