var nconf = require('nconf'),
    path = require('path');

console.log('called my config');

nconf.argv()
    .env()
    .file({ file: path.join(__dirname, 'default.json.json') })
    .port({ file: path.join(__dirname, 'default.json.json') });

module.exports = nconf;