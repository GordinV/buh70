'use strict';

let Obj = {id: 0, key: 'id'};
let ObjKeys = Object.keys(Obj);
let found = Object.keys(Obj).some('id');
//indexOf('id1');
console.log(Obj, ObjKeys, found);