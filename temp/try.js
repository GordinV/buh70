let kuu = '04';
let aasta = '2021';
let paev = '05';

let kpv = new Date(`${aasta + '-' + kuu + '-' + paev}`);

console.log(kpv.toISOString().substring(1, 10), new Date(kpv.getFullYear(), kpv.getMonth()+1, '05').toLocaleDateString());