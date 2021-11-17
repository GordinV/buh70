module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "5%", show: false, type: "date", interval: true},
            {id: "kulastatavus", name: "Külastatavus", width: "5%", show: true},
            {id: "yksus", name: "Rühm", width: "10%", show: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "10%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "0%", show: false},
            {id: "viitenumber", name: "Viitenumber", width: "10%", show: true},
            {id: "alg_saldo", name: "Alg.saldo", width: "5%", type: "number", interval: true},
            {id: "arvestatud", name: "Arvestatud", width: "5%", type: "number", interval: true},
            {id: "soodustus", name: "Soodustus", width: "5%", type: "number", interval: true},
            {id: "arv_ja_soodustus", name: "Arvestatud ja Soodustus", width: "5%", type: "number", interval: true},
            {id: "laekumised", name: "Laekumised", width: "5%", type: "number", interval: true},
            {id: "mahakantud", name: "Mahakantud", width: "5%", type: "number", interval: true},
            {id: "tagastused", name: "Tagastused", width: "5%", type: "number", interval: true},
            {id: "jaak", name: "Võlg", width: "5%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "10%"},
        ],
        sqlString: `SELECT sum(qryReport.alg_saldo) OVER (PARTITION BY rekvid)                AS alg_saldo_group,
                           sum(qryReport.arvestatud) OVER (PARTITION BY rekvid)               AS arvestatud_group,
                           sum(qryReport.soodustus) OVER (PARTITION BY rekvid)                AS soodustus_group,
                           sum(qryReport.laekumised) OVER (PARTITION BY rekvid)               AS laekumised_group,
                           sum(qryReport.mahakantud) OVER (PARTITION BY rekvid)               AS mahakantud_group,
                           sum(qryReport.arvestatud - qryReport.soodustus)
                           OVER (PARTITION BY rekvid)                                         AS arv_ja_soodustus_group,
                           sum(qryReport.tagastused) OVER (PARTITION BY rekvid)               AS tagastused_group,
                           sum(qryReport.jaak) OVER (PARTITION BY rekvid)                     AS jaak_group,
                           count(*) OVER ()                                                   AS rows_total,
                           qryReport.id,
                           qryReport.period,
                           qryReport.kulastatavus,
                           qryReport.lapse_nimi,
                           lapse_isikukood,
                           yksus,
                           viitenumber,
                           coalesce(alg_saldo, 0)::NUMERIC(14, 4)                             AS alg_saldo,
                           coalesce(arvestatud, 0)::NUMERIC(14, 4)                            AS arvestatud,
                           coalesce(soodustus, 0)::NUMERIC(14, 4)                             AS soodustus,
                           coalesce(laekumised, 0)::NUMERIC(14, 4)                            AS laekumised,
                           coalesce(mahakantud, 0)::NUMERIC(14, 4)                            AS mahakantud,
                           coalesce(tagastused, 0)::NUMERIC(14, 4)                            AS tagastused,
                           (coalesce(arvestatud, 0) - coalesce(soodustus, 0))::NUMERIC(14, 4) AS arv_ja_soodustus,
                           coalesce(jaak, 0)::NUMERIC(14, 4)                                  AS jaak,
                           rekvid,
                           $2                                                                 AS user_id,
                           r.nimetus::TEXT                                                    AS asutus
                    FROM lapsed.get_saldo_ja_kaive_from_cache($1::INTEGER, jsonb_build_object('kpv_start',$3::date, 'kpv_end', $4::date)) qryReport
                             INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                    ORDER BY r.nimetus
        `,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        totals: ` sum(alg_saldo) over() as alg_saldo_total,
                sum(arvestatud) over() as arvestatud_total,
                sum(soodustus) over() as soodustus_total, 
                sum(arvestatud - soodustus) over() as arv_ja_soodustus_total, 
                sum(laekumised) over() as laekumised_total,
                sum(mahakantud) over() as mahakantud_total,
                sum(tagastused) over() as tagastused_total,
                sum(jaak) over() as jaak_total `,
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
                let mahakantud_kokku = 0;
                let tagastused_kokku = 0;
                let row_id = 0;
                let groupedData = {};
                data.forEach(row => {
                    alg_saldo_kokku = Number(alg_saldo_kokku) + Number(row.alg_saldo);
                    arvestatud_kokku = Number(arvestatud_kokku) + Number(row.arvestatud);
                    soodustus_kokku = Number(soodustus_kokku) + Number(row.soodustus);
                    laekumised_kokku = Number(laekumised_kokku) + Number(row.laekumised);
                    mahakantud_kokku = Number(mahakantud_kokku) + Number(row.mahakantud);
                    tagastused_kokku = Number(tagastused_kokku) + Number(row.tagastused);
                });

                return data.map(row => {
                    row_id++;
                    row.alg_saldo_kokku = alg_saldo_kokku;
                    row.arvestatud_kokku = arvestatud_kokku;
                    row.soodustus_kokku = soodustus_kokku;
                    row.laekumised_kokku = laekumised_kokku;
                    row.mahakantud_kokku = mahakantud_kokku;
                    row.tagastused_kokku = tagastused_kokku;
                    row.row_id = row_id;
                    return row;
                })
            }
        },
    ],

};
