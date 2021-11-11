const winston = require('winston');
winston.clear();

var path = module.filename.split('/').slice(-2).join('/');

const Logger = new winston.Logger({
    transports: [
        new winston.transports.Console({
            colorize: true,
            level: 'info'
        }),
        new winston.transports.File({filename:'temp.log'})
    ]
});

Logger.info('test info');

