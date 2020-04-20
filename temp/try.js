/*
let arr = '1,2,3';
const reg =  /^\d+$/;
console.log('result', reg.test(1));*/

const parent = new Set;

const data = [
    {yksus: "yksus1", tyyp:"tyyp1", kogus: 1, is_row: true},
    {yksus: "yksus2", tyyp:"tyyp2", kogus: 2, is_row: true},
    {yksus: "yksus1", tyyp:"tyyp2", kogus: 3, is_row: true},
    {yksus: "yksus2", tyyp:"tyyp1", kogus: 4, is_row: true},
    {yksus: "yksus1", tyyp:"tyyp1", kogus: 5, is_row: false},
    ];

const group = 'yksus';
const group2 = 'tyyp';

data.forEach(row => {
    parent.add(row[group])
});

result = Array.from(parent).map(field => {
    const subGroupData = data.filter(row => row[group] === field);
    let returnData = {};
    returnData[field] = subGroupData;
    return returnData;
});

console.log(JSON.stringify(result));

let filteredData = result;
for each (var tyyp in filteredData;) {

}
//    each rea in tyyp[Object.keys(tyyp)[0]]