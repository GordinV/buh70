'use strict';

const getXMLFileModule = require('./getXMLFile');
const xmlToJsonModule = require('./xml_to_json');

module.exports = Object.assign({}, getXMLFileModule, xmlToJsonModule);

