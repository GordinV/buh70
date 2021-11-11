const winston = require('winston');
winston.clear();

const logger = new (winston.Logger);


// can be much more flexible than that O_o
const getLogger = (message, level) => {

    const Logger = new winston.Logger({
        transports: [
            new winston.transports.Console({
                colorize: true,
                level: level ? level: 'info'
            }),
            new winston.transports.File({filename:'./app.log'})
        ]
    });

    Logger.info(message)
};

module.exports = getLogger;