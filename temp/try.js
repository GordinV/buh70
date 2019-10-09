/*
let obj = [{name: "Koosta arve", task: "koosta_arve"}];

let index = obj.find(row => row.id === 2);
console.log('indx', index);

let newObj = {id: 0, name: ''};

*/
let n = 0;
while (++n < 5) {
    console.log(n);
    setTimeout(() => console.log(n), 10 + n, n)
}