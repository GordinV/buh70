module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "1%", show: false, type: "date", interval: true},
            {id: "kulastatavus", name: "Külastatavus", width: "5%", show: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "7%"},
            {id: "lapse_isikukood", name: "Lapse IK", width: "0%", show: false},
            {id: "viitenumber", name: "Viitenumber", width: "7%", show: true},
            {id: "vana_vn", name: "Vana VN", width: "5%"},
            {id: "alg_saldo", name: "Alg.saldo", width: "5%", type: "number", interval: true},
            {id: "arvestatud", name: "Arvestatud", width: "5%", type: "number", interval: true},
            {id: "soodustus", name: "Soodustus", width: "5%", type: "number", interval: true},
            {id: "umberarvestus", name: "Ümberarv.", width: "5%", type: "number", interval: true},
            {id: "arv_kokku", name: "Kokku arvestatud", width: "5%", type: "number", interval: true},
            {id: "laekumised", name: "Laekumised", width: "5%", type: "number", interval: true},
            {id: "tagastused", name: "Tagastused", width: "5%", type: "number", interval: true},
            {id: "mahakantud", name: "Mahakantud", width: "5%", type: "number", interval: true},
            {id: "jaak", name: "Võlg", width: "5%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "8%"},
        ],
        sqlString: `SELECT sum(qryReport.alg_saldo) OVER (PARTITION BY rekvid)                AS alg_saldo_group,
                           sum(qryReport.arvestatud) OVER (PARTITION BY rekvid)               AS arvestatud_group,
                           sum(qryReport.umberarvestus) OVER (PARTITION BY rekvid)            AS umberarvestus_group,
                           sum(qryReport.soodustus) OVER (PARTITION BY rekvid)                AS soodustus_group,
                           sum(qryReport.laekumised) OVER (PARTITION BY rekvid)               AS laekumised_group,
                           sum(qryReport.mahakantud) OVER (PARTITION BY rekvid)               AS mahakantud_group,
                           sum(qryReport.arvestatud - qryReport.soodustus)
                           OVER (PARTITION BY rekvid)                                         AS arv_ja_soodustus_group,
                           -1 * sum(qryReport.tagastused) OVER (PARTITION BY rekvid)          AS tagastused_group,
                           sum(qryReport.jaak) OVER (PARTITION BY rekvid)                     AS jaak_group,
                           count(*) OVER ()                                                   AS rows_total,
                           qryReport.id,
                           qryReport.period,
                           qryReport.kulastatavus,
                           qryReport.lapse_nimi,
                           lapse_isikukood,
                           viitenumber,
                           coalesce(alg_saldo, 0)::NUMERIC(14, 2)                             AS alg_saldo,
                           coalesce(arvestatud, 0)::NUMERIC(14, 2)                            AS arvestatud,
                           coalesce(umberarvestus, 0)::NUMERIC(14, 2)                         AS umberarvestus,
                           -1 * coalesce(soodustus, 0)::NUMERIC(14, 2)                        AS soodustus,
                           coalesce(laekumised, 0)::NUMERIC(14, 2)                            AS laekumised,
                           coalesce(mahakantud, 0)::NUMERIC(14, 2)                            AS mahakantud,
                           -1 * coalesce(tagastused, 0)::NUMERIC(14, 2)                       AS tagastused,
                           (coalesce(arvestatud, 0) - coalesce(soodustus, 0))::NUMERIC(14, 4) AS arv_ja_soodustus,
                           (coalesce(arvestatud, 0) - coalesce(soodustus, 0) +
                            coalesce(umberarvestus, 0))::NUMERIC(14, 2)                       AS arv_kokku,
                           coalesce(jaak, 0)::NUMERIC(14, 2)                                  AS jaak,
                           rekvid,
                           $2                                                                 AS user_id,
                           r.nimetus::TEXT                                                    AS asutus,
                           vn.vn                                                              AS vana_vn
                    FROM lapsed.kaive_aruanne($1::INTEGER, $3, $4) qryReport
                             INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                             LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                              FROM lapsed.viitenr vn
                                              WHERE vn.rekv_id IN (SELECT rekv_id
                                                                   FROM get_asutuse_struktuur($1))
                                              GROUP BY vn.isikukood
                    ) vn
                                             ON vn.isikukood = qryReport.lapse_isikukood
                    ORDER BY r.nimetus
        `,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        totals: ` sum(alg_saldo) over() as alg_saldo_total,
                sum(arvestatud) over() as arvestatud_total,
                sum(umberarvestus) over() as umberarvestus_total,                
                sum(soodustus) over() as soodustus_total, 
                sum(arvestatud + soodustus) over() as arv_ja_soodustus_total, 
                sum(laekumised) over() as laekumised_total,
                sum(mahakantud) over() as mahakantud_total,
                sum(tagastused) over() as tagastused_total,
                sum(jaak) over() as jaak_total `,
        alias: 'kaive_aruanne_report',
        notReloadWithoutParameters: true
    },
    print: [
        {
            view: 'kaive_aruanne_register',
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
                    row.tagastused_kokku = -1 * tagastused_kokku;
                    row.row_id = row_id;
                    return row;
                })
            }
        },
    ],

};
