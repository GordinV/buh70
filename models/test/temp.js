
const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');

let modelForExport = 'raamatupidamine/journal';
let modelPath =  path.resolve(path.join('./models/', modelForExport));
let model = require(modelPath);
let keys = Object.keys(model);
const doc = require('../raamatupidamine/journal');

console. log(_.indexOf(keys, 'grid2'));
console. log(_.indexOf(keys, 'grid2') ? model.grid.sqlString : '');

