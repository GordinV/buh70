const getGroupedData = require('./../public/javascripts/getGroupedData');
const data = [{"id":1,"parent":2}, {"id":2,"parent":2}, {"id":3,"parent":1}];

const result = getGroupedData(data,'parent');
console.log(result);