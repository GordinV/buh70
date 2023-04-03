module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "kuu", name: "Kuu", width: "5%", show: true, type: "integer"},
            {id: "aasta", name: "Aasta", width: "5%", show: true, type: "integer"},
            {id: "isikukood", name: "Isikukood", width: "10%", show: true},
            {id: "nimi", name: "Nimi", width: "20%"},
            {id: "asutus", name: "Asutus", width: "20%"},
            {id: "viitenumber", name: "Viitenumber", width: "10%", show: true},
            {id: "kood", name: "Operatsiooni kood", width: "10%", show: true},
            {id: "nimetus", name: "Operatsiooni nimetus", width: "20%", show: true},
            {id: "summa", name: "Arvestatud summa", width: "10%", show: true, type: "number", interval: true},
            {id: "koht", name: "Andmete koht", width: "10%", show: true},
        ],
        sqlString: `SELECT row_number() OVER ()                     AS id,
                           sum(summa) OVER (PARTITION BY isikukood) AS kogus_group,
                           count(*) OVER ()                         AS rows_total,
                           $2                                       AS user_id,
                           asutus::TEXT                             AS asutus,
                           nimi,
                           isikukood,
                           viitenumber,
                           kood,
                           nimetus,
                           summa,
                           kuu,
                           aasta,
                           koht
                    FROM lapsed.topeltmaksud($1::INTEGER, $3, $4) qryReport
                    ORDER BY isikukood, kood`,     // $1 - rekvid, $3 - kuu, $4 - aasta
        params: ['rekvid', 'userid', 'kuu', 'aasta'],
        min_params: 2,
        notReloadWithoutParameters: true,
        alias: 'topeltmaksud_report'
    },
    print: [
        {
            view: 'topeltmaksud_register',
            params: 'sqlWhere',
            group: 'isikukood'
        },
    ],

};
