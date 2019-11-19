const Moment = require('moment');
const getNow = require('./../libs/getNow');
let kpv = Moment().format('YYYY-MM-DD');
let d = new Date(2019,12,31);
let simple = getNow(new Date(2019,12,31));

console.log(kpv, simple, d);