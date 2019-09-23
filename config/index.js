var nconf = require('nconf'),
    path = require('path');

nconf.argv()
    .env()
    .file({ file: path.join(__dirname, 'default.json.json') })
    .port({ file: path.join(__dirname, 'default.json.json') });

module.exports = nconf;