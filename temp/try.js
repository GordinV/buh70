const path = require('path');
const config = require('./../config/lapsed');
const kataloog = './../models/';
const docConfig = [];


Object.keys(config).forEach(key => {
    let modelPath = config[key];
    let folder = path.join(kataloog,config[key]);
    const grid = require(folder).grid.gridConfiguration;
    docConfig.push({docTypeId: key.toUpperCase(), grid: grid})
});
console.log(docConfig);
