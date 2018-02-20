'use strict';

console.log('start');
const moment = require('moment');


setInterval(()=>{
    let now = new Date();
    console.log('timer', moment('20180714','YYYYMMDD').fromNow('dd'));
    let marrageDay = moment([2018, 7, 14]);
    console.log('diff',   marrageDay.diff(now,'days'));
},1000);

