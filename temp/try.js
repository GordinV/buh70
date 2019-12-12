const obj = [
    {id: 1},
    {id: 2, filter:'show'}
];

obj.forEach(row => {
    console.log(!row.filter)
});