module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "kuu", name: "Kuu", width: "5%", show: true, type:"integer"},
            {id: "aasta", name: "Aasta", width: "5%", show: true,type:"integer"},
            {id: "ruhm", name: "Rühm", width: "10%", show: true},
            {id: "isikukood", name: "Isikukood", width: "10%", show: true},
            {id: "nimi", name: "Nimi", width: "20%"},
            {id: "viitenumber", name: "Viitenumber", width: "10%", show: true},
            {id: "arvestatud", name: "Arvestatud", width: "10%", show: true, type: "number", interval: true},
            {id: "soodustus", name: "Soodustus", width: "10%", show: true, type: "number", interval: true},
            {id: "summa", name: "Arvestatud ja Soodustus", width: "10%", show: true, type: "number", interval: true}
        ],
        sqlString: `SELECT row_number() OVER ()                     AS id,
                           count(*) OVER ()                         AS rows_total,
                           $2                                       AS user_id,
                           ruhm,
                           nimi,
                           isikukood,
                           viitenumber,
                           arvestatud::numeric(14,2),
                           soodustus::numeric(14,2),
                           (arvestatud - soodustus)::numeric(14,2) as summa,
                           kuu,
                           aasta
                    FROM lapsed.kuutabeli_aruanne($1::INTEGER, $3, $4) qryReport
                        order by nimi, ruhm`,     // $1 - rekvid, $3 - kuu, $4 - aasta
        params: ['rekvid', 'userid', 'kuu', 'aasta'],
        totals: ` sum(arvestatud) over() as arvestatud_total,
                sum(soodustus) over() as soodustus_total, 
                sum(arvestatud - soodustus) over() as summa_total` ,
        alias: 'kuutabeli_aruanne'
    },
    print: [
        {
            view: 'kuutabeli_aruanne_register',
            params: 'sqlWhere'
        },
    ],

};
