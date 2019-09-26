'use strict';
const _ = require('lodash');
const users = [{id:1, name:'vlad'},{id:2,name:'temp'}];
let result = users.includes({id:2});
result = _.findIndex(users,{id:2});

console.log(result, users[result]);

