let obj = {
    asutus: 'asutus'
};

const def = 'obj.asutus112';
let result;
try {
    result = eval(def);
} catch (error) {
    console.error (error)
}

let newObj = Object.assign([],[]);
console.log(result, def, newObj);
