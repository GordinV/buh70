const _ = require('lodash');
const obj = [{
    isikukood: '36708052213',
    nimi:'Ivanov Deniss',
    tululiik:'10'
},{
    isikukood: '36708052213',
    nimi:'Ivanov Deniss',
    tululiik:'10'
}];

let tuluLiigid = ['10','17','33'];

let tl = obj.filter(kiri => {

    return tuluLiigid.indexOf(kiri.tululiik) !== -1;
})

console.log(tl)
