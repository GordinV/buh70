'use strict';
/*
const soap = require('libs/callSoapService');

// _.find(doc.select, {alias: 'details'}).sql;
debugger;
//let Obj = {select: [{sql: `select 1`, alias:'test'}]};
//let sql = _.find(Obj.select,{alias:'test'}).sql;
console.log('sql',sql);

//curl -X; GET; "https://graph.facebook.com/<PSID>?fields='Nina','Martonenko'";
*/

const _ = require('underscore');

const useridModel = require('../models/ou/userid');
const sql = _.findWhere(useridModel.select, {alias: 'com_user_rekv'});

let paring = sql.sql;
console.log(paring,sql);