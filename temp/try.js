'use strict';
const _ = require('lodash');

// _.find(doc.select, {alias: 'details'}).sql;
debugger;
let Obj = {select: [{sql: `select 1`, alias:'test'}]};
let sql = _.find(Obj.select,{alias:'test'}).sql;
console.log('sql',sql);
