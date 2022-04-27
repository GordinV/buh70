const Moment = require('moment');
let kpv = Moment(2022 + '-' + '12'.toString() + '-' + '05', "YYYY-MM-DD").add(1, 'month') .format("YYYY-MM-DD");

console.log(kpv);