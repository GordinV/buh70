const gridData = [{"summa": 100}, {"summa":200}];
let sumField = 'summa';
let total = 0;
 gridData.forEach(row =>  total = total + row[sumField]);

console.log('total', total);