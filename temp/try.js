let arr = [{id:'id', type:'text'},{id:'123', type:'text'},{id:'321', type:'text'}];
let result = [];
const reg =  /^\d+$/;

arr.forEach(row => {
    if (reg.test(row.id)) {
        result.push(row.id);
    }
});

console.log('result', result);