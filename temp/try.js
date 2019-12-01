let sqlParamsQantity = 4;
let params = [1, 2];
let paramsToAdd = sqlParamsQantity - params.length;

if (sqlParamsQantity > 2 && params.length == 2) {
    console.log('sqlParamsQantity',sqlParamsQantity, params.length, paramsToAdd);
    for (let i = 0; i < paramsToAdd; i++ ) {
        console.log('i',i);
        params.push(null)
    }
}

console.log(params);
