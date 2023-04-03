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
            {id: "arvestatud", name: "Arvestatud (sh vahe)", width: "5%", show: true, type: "number", interval: true},
            {id: "soodustus", name: "Soodustus", width: "5%", show: true, type: "number", interval: true},
            {id: "umberarvestus", name: "Ümberarv.", width: "5%", show: true, type: "number", interval: true},
            {id: "summa", name: "Kokku arvestatud", width: "5%", show: true, type: "number", interval: true}
        ],
        sqlString: `SELECT row_number() OVER ()                                            AS id,
                           count(*) OVER ()                                                AS rows_total,
                           $2                                                              AS user_id,
                           ruhm,
                           nimi,
                           qryReport.isikukood,
                           viitenumber,
                           arvestatud::NUMERIC(14, 2),
                           soodustus::NUMERIC(14, 2),
                           umberarvestus::NUMERIC(14, 2),
                           vahe,
                           (arvestatud + soodustus + umberarvestus)::NUMERIC(14, 2) AS summa,
                           kuu,
                           aasta,
                           vana_vn                                                         AS vana_vn
                    FROM lapsed.kuutabeli_aruanne($1::INTEGER, $3, $4) qryReport
                    ORDER BY nimi, ruhm`,     // $1 - rekvid, $3 - kuu, $4 - aasta
        params: ['rekvid', 'userid', 'kuu', 'aasta'],
        min_params: 2,
        notReloadWithoutParameters: true,
        totals: ` sum(arvestatud) over() as arvestatud_total,
                sum(soodustus) over() as soodustus_total, 
                sum(umberarvestus) over() as umberarvestus_total, 
                sum(vahe) over() as vahe_total, 
                sum(arvestatud + soodustus + umberarvestus) over() as summa_total`,
        alias: 'kuutabeli_aruanne'
    },
    print: [
        {
            view: 'kuutabeli_aruanne_register',
            params: 'sqlWhere'
        },
    ],

};
