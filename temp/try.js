let kpv = '30.10.2019'.split('.');
console.log(kpv);
var mydate = new Date(kpv[2], kpv[1], kpv[0]).toLocaleDateString();
console.log(mydate);