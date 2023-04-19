module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "5%", show: false, type: "date", interval: true},
            {id: "kulastatavus", name: "Külastatavus", width: "5%", show: true},
            {id: "yksus", name: "Rühm", width: "7%", show: true},
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
        sqlString: `SELECT sum(qryReport.alg_saldo) OVER (PARTITION BY qryReport.rekvid)                AS alg_saldo_group,
                           sum(qryReport.arvestatud) OVER (PARTITION BY qryReport.rekvid)               AS arvestatud_group,
                           sum(qryReport.umberarvestus) OVER (PARTITION BY qryReport.rekvid)            AS umberarvestus_group,
                           sum(qryReport.soodustus) OVER (PARTITION BY qryReport.rekvid)                AS soodustus_group,
                           sum(qryReport.laekumised) OVER (PARTITION BY qryReport.rekvid)               AS laekumised_group,
                           sum(qryReport.mahakantud) OVER (PARTITION BY qryReport.rekvid)               AS mahakantud_group,
                           sum(qryReport.arvestatud - qryReport.soodustus)
                           OVER (PARTITION BY qryReport.rekvid)                                         AS arv_ja_soodustus_group,
                           sum(qryReport.tagastused) OVER (PARTITION BY qryReport.rekvid)               AS tagastused_group,
                           sum(qryReport.jaak) OVER (PARTITION BY qryReport.rekvid)                     AS jaak_group,
                           count(*) OVER ()                                                   AS rows_total,
                           qryReport.id,
                           qryReport.period,
                           qryReport.kulastatavus,
                           qryReport.lapse_nimi,
                           lapse_isikukood,
                           yksus,
                           ltrim(rtrim(kt.kood)) as koolituse_tyyp,
                           ltrim(rtrim(kt.nimetus)) as koolitus_nimetus,       
                           viitenumber,
                           coalesce(alg_saldo, 0)::NUMERIC(14, 2)                             AS alg_saldo,
                           coalesce(arvestatud, 0)::NUMERIC(14, 2)                            AS arvestatud,
                           coalesce(umberarvestus, 0)::NUMERIC(14, 2)                         AS umberarvestus,
                           -1 * coalesce(soodustus, 0)::NUMERIC(14, 2)                        AS soodustus,
                           coalesce(laekumised, 0)::NUMERIC(14, 4)                            AS laekumised,
                           coalesce(mahakantud, 0)::NUMERIC(14, 2)                            AS mahakantud,
                           coalesce(tagastused, 0)::NUMERIC(14, 2)                            AS tagastused,
                           (coalesce(arvestatud, 0) - coalesce(soodustus, 0))::NUMERIC(14, 2) AS arv_ja_soodustus,
                           (coalesce(arvestatud, 0) - coalesce(soodustus, 0) +
                            coalesce(umberarvestus, 0))::NUMERIC(14, 2)                       AS arv_kokku,
                           coalesce(jaak, 0)::NUMERIC(14, 4)                                  AS jaak,
                           qryReport.rekvid,
                           $2                                                                 AS user_id,
                           r.nimetus::TEXT                                                    AS asutus,
                           vn.vn                                                              AS vana_vn
                    FROM lapsed.saldo_ja_kaive($1::INTEGER, $3::DATE, $4::DATE) qryReport
                             INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                             LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                              FROM lapsed.viitenr vn
                                              WHERE vn.rekv_id IN (SELECT rekv_id
                                                                   FROM get_asutuse_struktuur($1))
                                              GROUP BY vn.isikukood
                    ) vn
                                             ON vn.isikukood = qryReport.lapse_isikukood
                             left outer JOIN libs.library l on (l.kood = ltrim(qryReport.yksus,'EM_'))  and l.library = 'LAPSE_GRUPP' and l.status < 3 and l.rekvid = qryReport.rekvid
                             left outer join libs.library kt on kt.id = (l.properties::jsonb->'tyyp')::integer
                    ORDER BY r.nimetus, koolituse_tyyp, regexp_replace(yksus, '[a-zA-Z_-]', '', 'g'), lapse_nimi
        `,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        min_params: 2,
        notReloadWithoutParameters: true,
        totals: ` sum(alg_saldo) over() as alg_saldo_total,
                sum(arvestatud) over() as arvestatud_total,
                sum(umberarvestus) over() as umberarvestus_total,
                sum(soodustus) over() as soodustus_total, 
                sum(arvestatud + soodustus) over() as arv_ja_soodustus_total, 
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
            group: ['asutus','koolitus_nimetus'],
            //,
            converter: function (data) {
                let alg_saldo_kokku = 0;
                let arvestatud_kokku = 0;
                let umberarvestus_kokku = 0;
                let soodustus_kokku = 0;
                let laekumised_kokku = 0;
                let mahakantud_kokku = 0;
                let tagastused_kokku = 0;
                let row_id = 0;

/*
                let dataSort = data.sort((a, b) => {
                    let fa = a.lapse_nimi.toLowerCase();
                    let fb = b.lapse_nimi.toLowerCase();
                    return (fa < fb ? -1 : 1);
                });
*/

                dataSort = data;

                dataSort.forEach(row => {
                    alg_saldo_kokku = Number(alg_saldo_kokku) + Number(row.alg_saldo);
                    arvestatud_kokku = Number(arvestatud_kokku) + Number(row.arvestatud);
                    umberarvestus_kokku = Number(umberarvestus_kokku) + Number(row.umberarvestus);
                    soodustus_kokku = Number(soodustus_kokku) + Number(row.soodustus);
                    laekumised_kokku = Number(laekumised_kokku) + Number(row.laekumised);
                    mahakantud_kokku = Number(mahakantud_kokku) + Number(row.mahakantud);
                    tagastused_kokku = Number(tagastused_kokku) + Number(row.tagastused);
                });

                return dataSort.map(row => {
                    row_id++;
                    row.alg_saldo_kokku = alg_saldo_kokku;
                    row.arvestatud_kokku = arvestatud_kokku;
                    row.umberarvestus_kokku = umberarvestus_kokku;
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
