'use strict';

// Для того, чтобы предотвратить подобные глупости, прямо в начале приложения для Node.js можно поместить такую конструкцию, выводящую необработанные исключения в консоль:
//process.on(`uncaughtException`, console.error);

const express = require('express');

const app = express(),
    compression = require('compression'),
    http = require('http'),
    https = require('https'),
    path = require('path'),
    routes = require('./routes/index'),
    errorHandle = require('errorhandler'),
//    config = require('config'),
    cookieParser = require('cookie-parser'),
    bodyParser = require('body-parser'),
    logger = require('morgan'),
    pg = require('pg'),
    session = require('express-session'),
    pgSession = require('connect-pg-simple')(session),
    RateLimit = require('express-rate-limit'),
    helmet = require('helmet'),
    cors = require('cors'),
    fs = require('fs'),
    csrf = require('csurf');

const config = require('./config/default.json');

const log = require('./libs/log');
const HttpError = require('./error').HttpError;
const port = config.port;
const https_port = config.https;


global.__base = __dirname + '/';

require('babel-polyfill');

require('node-jsx').install({extension: '.jsx'});


app.set('port', port);

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');


http.createServer(app).listen(port, function () {
    log('Express server listening on port ' + port, 'info');
});

let pathToSshKey = path.join(__dirname,'routes', 'ssh', 'server.key');
let pathToSshCert = path.join(__dirname,'routes', 'ssh', 'server.cert');

// will check if cert is available
if (fs.existsSync(pathToSshCert) && https_port) {
    const options = {
        key: fs.readFileSync(pathToSshKey),
        cert: fs.readFileSync(pathToSshCert),
        ca: ''
    };

    https.createServer(options, app).listen(https_port, ()=>{
        log('Express server listening on port ' + https_port,'info');
    });
}


// middleware


//Helmet помогает защитить приложение от некоторых широко известных веб-уязвимостей путем соответствующей настройки заголовков HTTP.
app.use(helmet());

app.use(compression());
//app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: false}));
app.use(cookieParser(config.session.secret));
app.use(require('./middleware/sendHttpError'));

app.use(cors()); //Enable All CORS Requests
// log

app.use(session({
    store: new pgSession({
        pg: pg,                                  // Use global pg-module
        conString:   config.pg.session_connection,
        tableName: 'session'               // Use another table-name than the default "session" one
    }),
    secret: config.session.secret,
    cookie: {maxAge: config.session.cookie.maxAge}

}));

/*
app.use(csrf());
*/

require('./routes')(app);
app.use(express.static(path.join(__dirname, 'public')));

app.use(function (err, req, res, next) {
    if (typeof err == 'number') { // next(404);
        err = new HttpError(err);
    }

    if (err instanceof HttpError) {
        res.render('error', {"message": err.message});

//        res.sendHttpError(err);
    } else {

        if (app.get('env') == 'development') {
//            errorhandler()(err, req, res, next);
            res.render('error', {"message": err.message});

        } else {
            log.error(err);
            err = new HttpError(500);
//            res.sendHttpError(err);
        }
    }
});

