'use strict';
const _ = require('lodash');
const arv_data = {
    id: 0,
    data: {
        id: 0,
        kpv: new Date(),
        asutusid: 4113,
        lapsid: 1,
        aa: 'AA',
        viitenr: 'viitenumber',
        muud: 'test muud',
        liik: 0,
        gridData: [
            {
                id: 0,
                nomid: 9,
                kogus: 1,
                hind: 100,
                kbm: 0,
                summa: 100,
                kbm_maar: 0

            }
        ]
    }
};

let json = JSON.stringify(arv_data);
console.log(json);

