module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "5%", show: false, type: "date", interval: true},
            {id: "kulastatavus", name: "Külastatavus", width: "5%", show: true},
            {id: "yksus", name: "Rühm", width: "10%", show: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "10%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "0%", show: false},
            {id: "viitenumber", name: "Viitenumber", width: "10%", show: true},
            {id: "alg_saldo", name: "Alg.saldo", width: "8%", type: "number", interval: true},
            {id: "arvestatud", name: "Arvestatud", width: "8%", type: "number"},
            {id: "soodustus", name: "Soodustus", width: "8%", type: "number"},
            {id: "laekumised", name: "Laekumised", width: "8%", type: "number"},
            {id: "tagastused", name: "Tagastused", width: "8%", type: "number"},
            {id: "jaak", name: "Võlg", width: "8%", type: "number"},
            {id: "asutus", name: "Asutus", width: "10%"},
        ],
        sqlString: `SELECT sum(qryReport.alg_saldo) OVER (PARTITION BY rekvid)  AS alg_saldo_group,
                           sum(qryReport.arvestatud) OVER (PARTITION BY rekvid) AS arvestatud_group,
                           sum(qryReport.soodustus) OVER (PARTITION BY rekvid)  AS soodustus_group,
                           sum(qryReport.laekumised) OVER (PARTITION BY rekvid) AS laekumised_group,
                           sum(qryReport.tagastused) OVER (PARTITION BY rekvid) AS tagastused_group,
                           sum(qryReport.jaak) OVER (PARTITION BY rekvid)       AS jaak_group,
                           qryReport.*,
                           $2                                                   AS user_id,
                           r.nimetus::TEXT                                      AS asutus
                    FROM lapsed.saldo_ja_kaive($1::INTEGER, $3, $4) qryReport
                             INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                    ORDER BY r.nimetus
        `,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        alias: 'saldo_ja_kaive_report'
    },
    print: [
        {
            view: 'saldo_ja_kaive_register',
            params: 'sqlWhere',
            group: 'asutus',
            converter: function (data) {
                let alg_saldo_kokku = 0;
                let arvestatud_kokku = 0;
                let soodustus_kokku = 0;
                let laekumised_kokku = 0;
                let tagastused_kokku = 0;
                let row_id = 0;
                let groupedData = {};
                data.forEach(row => {
                    alg_saldo_kokku = Number(alg_saldo_kokku) + Number(row.alg_saldo);
                    arvestatud_kokku = Number(arvestatud_kokku) + Number(row.arvestatud);
                    soodustus_kokku = Number(soodustus_kokku) + Number(row.soodustus);
                    laekumised_kokku = Number(laekumised_kokku) + Number(row.laekumised);
                    tagastused_kokku = Number(tagastused_kokku) + Number(row.tagastused);
                });

                return data.map(row => {
                    row_id++;
                    row.alg_saldo_kokku = alg_saldo_kokku;
                    row.arvestatud_kokku = arvestatud_kokku;
                    row.soodustus_kokku = soodustus_kokku;
                    row.laekumised_kokku = laekumised_kokku;
                    row.tagastused_kokku = tagastused_kokku;
                    row.row_id = row_id;
                    return row;
                })
            }
        },
    ],

};
