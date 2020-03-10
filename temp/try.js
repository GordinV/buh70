let arr = [{id: "id", name: "id", width: "25px", show: false},
    {id: "number", name: "Number", width: "100px"},
    {id: "kpv", name: "Kuupaev", width: "100px", type: "date", interval: true}];

let row = arr.find(row => row.id == 'number');

console.log(row);
