module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "5%", show: false, type: "date", interval: true},
            {id: "kulastatavus", name: "Külastatavus", width: "10%", show: true},
            {id: "yksus", name: "Rühm", width: "10%", show: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "0%", show: false},
            {id: "viitenumber", name: "Viitenumber", width: "0%", show: false},
            {id: "number", name: "Number", width: "10%"},
            {id: "alg_saldo", name: "Alg.saldo", width: "10%", type: "number", interval: true},
            {id: "arvestatud", name: "Arvestatud", width: "10%", type: "number"},
            {id: "soodustus", name: "Soodustus", width: "10%", type: "number"},
            {id: "laekumised", name: "Laekumised", width: "10%", type: "number"},
            {id: "tagastused", name: "Tagastused", width: "10%", type: "number"},
            {id: "jaak", name: "Võlg", width: "10%", type: "number"},
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
                    ORDER BY r.nimetus, (regexp_replace(qryReport.number, '[^0-9]', '0', 'g')::INTEGER)
        `,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        alias: 'saldo_ja_kaive_report'
    },
    print: [
        {
            view: 'saldo_ja_kaive_register',
            params: 'sqlWhere',
            group: 'asutus'
        },
    ],

};