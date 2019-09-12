'use strict';
const _ = require('lodash');
/*
const finder = require('../libs/getDataByFilter');
let data = [
    {id: 1,
        kood:'12345',
        Nimetus: 'test 12'
    },
    {id: 2,
        kood:'7890',
        Nimetus: 'test 654'
    },
]

const soap = require('libs/callSoapService');

// _.find(doc.select, {alias: 'details'}).sql;
debugger;
//let Obj = {select: [{sql: `select 1`, alias:'test'}]};
//let sql = _.find(Obj.select,{alias:'test'}).sql;
console.log('sql',sql);

//curl -X; GET; "https://graph.facebook.com/<PSID>?fields='Nina','Martonenko'";

var sites = {
    links: [
        {href: 'https://www.example.com/v1/contact-us/ca'},
        {href: 'https://www.example.com/v1/contact-us/au'},
        {href: 'https://www.example.com/v1/contact-us/us'},
        {href: 'https://www.example.com/v1/dontcontact-us/us'}
    ]
};

const regex = new RegExp('/contact\\b', 'g');
const matchedSites = sites.links.filter(({href}) => href.match(regex));
console.log(matchedSites);




let data = [
    {id: 1,
        kood:'12345',
        Nimetus: 'test 12'
    },
    {id: 2,
        kood:'7890',
        Nimetus: 'test 654'
    },
]

let seachFor = '34';
const found = data.filter((row) => (row.kood.indexOf(seachFor) > 0 || row.Nimetus.indexOf(seachFor)) > 0 );


//let found = _.filter(data,  _.matches({ kood: '12' }));
*/

//let found = finder(data,'89');

let params = {asutused:'where'};
let key = 'asutused';
let exists = _.has(params, 'asutused');
console.log(params[key], exists);