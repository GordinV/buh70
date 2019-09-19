'use strict';
const _ = require('lodash');
/*
const filter = [
    {
        name: 'kood',
        type: 'text',
        value: null
    },
    {
        name: 'nimetus',
        type: 'text',
        value: null
    },
];


const searchObj = {kood: '9999', Nimetus: 'test lodash', obj: 'Not valid'};

let mergedData = mergeParametersWithFilter(filter, searchObj);

console.log('mergedData', mergedData);

function mergeParametersWithFilter(filter, parameters) {
    console.log(filter,parameters);
    let keys = _.keys(parameters);
    _.forEach(keys, (key) => {
        // find row in filter array
        let filterRowIndex = _.findIndex(filter, {name:key});
        console.log('foreach', key, filterRowIndex);
        if (filterRowIndex >= 0) {
            filter[filterRowIndex].value = parameters[key];
            console.log('found', filter[filterRowIndex], parameters[key]);
        }
    });

    return filter;
}
