const compareDates = require('./../libs/compareDates');

let now = new Date().toISOString().substring(0, 10);
let tomorrow = new Date(2021,5,27);
console.log(now);
if (compareDates(tomorrow, now) ) {
    console.log('tootab', )
} else {
    console.log('fuflo')
}