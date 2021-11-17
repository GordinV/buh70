const modelCreator = require('./../libs/createXMLmodel');
const fs = require('fs');
modelForExport = 'ou/aasta';


fs.readFile('try.js', function (err, data) {
    if (err) throw err;

    console.log('data',data);
});