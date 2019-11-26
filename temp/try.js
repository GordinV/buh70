//const obj = [{id:1, summa: 0, interval: true, start: 1, end: 2}, {id:2, summa1: 0}];
let fieldNameStart = 'field_start';
let fieldNameEnd = 'field_end';
//x.replace(/|/i, ""));
let isEnd = !!fieldNameEnd.match(/_end1/);
console.log(isEnd, fieldNameStart.replace(/_start/i,''), fieldNameEnd.replace(/_end/i,''), );