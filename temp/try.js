'use strict';
const _ = require('lodash');

const uuids = [{
    uuid: 'c7b12d60-e37f-11e9-88e6-1bc46bf80d1e',
    ametnik: 'Vladislav Gordin'
},
    {
        uuid: '66bc2250-e382-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'c2c90b80-e382-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'aa0e36f0-e383-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '6dc05420-e384-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'f1901d20-e385-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '6a934530-e386-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'c7c74940-e386-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '42274230-e387-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '558e7e50-e388-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'f752d8d0-e388-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '601081b0-e389-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '1d2cd460-e38a-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'a4ab9110-e38a-11e9-88e6-1bc46bf80d1e',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'f036dc70-e38a-11e9-91d3-8b7b9b983e57',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'aede5110-e38d-11e9-8b59-41d9607a158c',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'f3b59b90-e38d-11e9-b733-c3c21186a8c6',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '064f1ce0-e38e-11e9-9090-25f46f04b8c8',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '8a6cded0-e38f-11e9-9090-25f46f04b8c8',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: 'd383ced0-e38f-11e9-907d-e7f68c179bea',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '18cf7410-e392-11e9-b271-f3a049337732',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '99a0e6a0-e392-11e9-b271-f3a049337732',
        ametnik: 'Vladislav Gordin'
    },
    {
        uuid: '57998f90-e393-11e9-8c62-1557e2e5f986',
        ametnik: 'Vladislav Gordin'
    }];

let index = _.findIndex(uuids,{uuid:'c7b12d60-e37f-11e9-88e6-1bc46bf80d1e'});

console.log('lib', index);

