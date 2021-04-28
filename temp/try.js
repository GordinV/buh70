
let now = new Date();
let kuu = now.getMonth();
let aasta = now.getFullYear();
let period =  (kuu < 9 ? '0': '') + kuu.toString() + '.' + aasta;
console.log(period);