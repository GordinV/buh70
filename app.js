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
    config = require('config'),
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


const log = require('./libs/log');
const HttpError = require('./error').HttpError;
const port = config.get('port');


global.__base = __dirname + '/';

require('babel-polyfill');

require('node-jsx').install({extension: '.jsx'});


app.set('port', port);

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');


http.createServer(app).listen(config.get('port'), function () {
    log('Express server listening on port ' + port, 'info');
});

let pathToSshKey = path.join(__dirname,'routes', 'ssh', 'server.key');
let pathToSshCert = path.join(__dirname,'routes', 'ssh', 'server.cert');

// will check if cert is available
if (fs.existsSync(pathToSshCert) && config.get('https')) {
    const options = {
        key: fs.readFileSync(pathToSshKey),
        cert: fs.readFileSync(pathToSshCert),
        ca: ''
    };

    https.createServer(options, app).listen(config.get('https'), ()=>{
        log('Express server listening on port ' + config.get('https'),'info');
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
app.use(cookieParser(config.get('session.secret')));
app.use(require('./middleware/sendHttpError'));

app.use(cors()); //Enable All CORS Requests
// log
app.use(session({
    store: new pgSession({
        pg: pg,                                  // Use global pg-module
        conString: config.get('pg.connection'), // Connect using something else than default DATABASE_URL env variable
        tableName: 'session'               // Use another table-name than the default "session" one
    }),
    secret: config.get('session.secret'),
    cookie: {maxAge: config.get('session.cookie.maxAge')}
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

