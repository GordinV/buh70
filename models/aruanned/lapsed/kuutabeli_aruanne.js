module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "kuu", name: "Kuu", width: "5%", show: true, type: "integer"},
            {id: "aasta", name: "Aasta", width: "5%", show: true, type: "integer"},
            {id: "ruhm", name: "Rühm", width: "7%", show: true},
            {id: "isikukood", name: "Isikukood", width: "10%", show: true},
            {id: "nimi", name: "Nimi", width: "20%"},
            {id: "viitenumber", name: "Viitenumber", width: "7%", show: true},
            {id: "vana_vn", name: "Vana VN", width: "5%"},
            {id: "arvestatud", name: "Arvestatud", width: "10%", show: true, type: "number", interval: true},
            {id: "soodustus", name: "Soodustus", width: "10%", show: true, type: "number", interval: true},
            {id: "summa", name: "Arvestatud ja Soodustus", width: "10%", show: true, type: "number", interval: true}
        ],
        sqlString: `SELECT row_number() OVER ()                     AS id,
                           count(*) OVER ()                         AS rows_total,
                           $2                                       AS user_id,
                           ruhm,
                           nimi,
                           qryReport.isikukood,
                           viitenumber,
                           arvestatud::NUMERIC(14, 2),
                           soodustus::NUMERIC(14, 2),
                           (arvestatud - soodustus)::NUMERIC(14, 2) AS summa,
                           kuu,
                           aasta,
                           vn.vn                                    AS vana_vn
                    FROM lapsed.kuutabeli_aruanne($1::INTEGER, $3, $4) qryReport
                             LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                              FROM lapsed.viitenr vn
                                              WHERE vn.rekv_id IN (SELECT rekv_id
                                                                   FROM get_asutuse_struktuur($1))
                                              GROUP BY vn.isikukood
                    ) vn
                                             ON vn.isikukood = qryReport.isikukood

                    ORDER BY nimi, ruhm`,     // $1 - rekvid, $3 - kuu, $4 - aasta
        params: ['rekvid', 'userid', 'kuu', 'aasta'],
        notReloadWithoutParameters: true,
        totals: ` sum(arvestatud) over() as arvestatud_total,
                sum(soodustus) over() as soodustus_total, 
                sum(arvestatud - soodustus) over() as summa_total`,
        alias: 'kuutabeli_aruanne'
    },
    print: [
        {
            view: 'kuutabeli_aruanne_register',
            params: 'sqlWhere'
        },
    ],

};
