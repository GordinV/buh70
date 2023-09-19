let min = 10;
let arr = [{id:4}, {id:1}, {id: 2}];
arr.forEach(row => {
   min = Math.min(min, row.id)
});

console.log('min', min);