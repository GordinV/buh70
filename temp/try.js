let parameter = 'value1, value2';
let is_koma = parameter.match(/,/);
let prepairedParameter = parameter.split(',').map(str=>`'${str.trim()}'`).join(',');
let sql = parameter.match(/,/) ? `in (${prepairedParameter})`: `ilike ${parameter}`;

console.log('Is_koma', is_koma, sql);

