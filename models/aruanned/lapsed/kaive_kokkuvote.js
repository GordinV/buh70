module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "5%", show: false, type: "date", interval: true},
            {id: "kulastatavus", name: "Külastatavus", width: "5%", show: true},
            {id: "alg_saldo", name: "Alg.saldo", width: "7%", type: "number", interval: true},
            {id: "arvestatud", name: "Arvestatud", width: "7%", type: "number", interval: true},
            {id: "soodustus", name: "Soodustus", width: "7%", type: "number", interval: true},
            {id: "umberarvestus", name: "Ümberarv.", width: "7%", type: "number", interval: true},
            {id: "arv_kokku", name: "Kokku arvestatud", width: "5%", type: "number", interval: true},
            {id: "laekumised", name: "Laekumised", width: "7%", type: "number", interval: true},
            {id: "tagastused", name: "Tagastused", width: "7%", type: "number", interval: true},
            {id: "mahakantud", name: "Mahakantud", width: "7%", type: "number", interval: true},
            {id: "jaak", name: "Võlg", width: "7%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "10%"},
        ],
        sqlString: `WITH qryReport AS (
                    SELECT qryReport.period,
                           sum(case when qryReport.kulastatavus = 'Jah' then 1 else 0 end)          as kulastatavus,
                           sum(coalesce(alg_saldo, 0))::NUMERIC(14, 2)                              AS alg_saldo,
                           sum(coalesce(arvestatud, 0))::NUMERIC(14, 2)                             AS arvestatud,
                           sum(coalesce(umberarvestus, 0))::NUMERIC(14, 2)                          AS umberarvestus,                           
                           sum(-1 * coalesce(soodustus, 0))::NUMERIC(14, 2)                             AS soodustus,
                           sum(coalesce(laekumised, 0))::NUMERIC(14, 2)                            AS laekumised,
                           sum(coalesce(mahakantud, 0))::NUMERIC(14, 2)                            AS mahakantud,
                           sum(coalesce(tagastused, 0) + coalesce(ulekanned, 0))::NUMERIC(14, 2)                            AS tagastused,
                           sum((coalesce(arvestatud, 0) - coalesce(soodustus, 0) + coalesce(umberarvestus, 0)))::NUMERIC(14, 2) AS arv_kokku,
                           sum(coalesce(jaak, 0))::NUMERIC(14, 4)                                  AS jaak,
                           rekvid,
                           r.nimetus::TEXT                                                         AS asutus
                            FROM lapsed.kaive_aruanne($1::INTEGER, $3, $4) qryReport
                                     INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                    GROUP BY rekvid, r.nimetus, qryReport.period
                )
                SELECT sum(r.alg_saldo) OVER ()                                 AS alg_saldo_group,
                       sum(r.arvestatud) OVER ()                                AS arvestatud_group,
                       sum(r.umberarvestus) OVER ()                                AS umberarvestus_group,
                       sum(r.soodustus) OVER ()                                 AS soodustus_group,
                       sum(r.laekumised) OVER ()                                AS laekumised_group,
                       sum(r.mahakantud) OVER ()                                AS mahakantud_group,
                       sum(r.arvestatud + r.soodustus + r.umberarvestus)
                       OVER ()                                                          AS arv_kokku_group,
                       sum(r.tagastused) OVER ()                                AS tagastused_group,
                       sum(r.jaak) OVER ()                                      AS jaak_group,
                       count(*) OVER ()                                                 AS rows_total,
                       row_number() OVER () as id,
                       period,
                       kulastatavus as kulastatavus,
                       coalesce(alg_saldo, 0)::NUMERIC(14, 2)                           AS alg_saldo,
                       coalesce(arvestatud, 0)::NUMERIC(14, 2)                          AS arvestatud,
                   coalesce(umberarvestus, 0)::NUMERIC(14, 2)                           AS umberarvestus,
                       coalesce(soodustus, 0)::NUMERIC(14, 2)                           AS soodustus,
                       coalesce(laekumised, 0)::NUMERIC(14, 2)                          AS laekumised,
                       coalesce(mahakantud, 0)::NUMERIC(14, 2)                          AS mahakantud,
                       -1 * coalesce(tagastused, 0)::NUMERIC(14, 2)                          AS tagastused,
                       (coalesce(arvestatud, 0) + coalesce(soodustus, 0) + coalesce(umberarvestus, 0))::NUMERIC(14, 2) AS arv_kokku,
                       coalesce(jaak, 0)::NUMERIC(14, 2)                                AS jaak,
                       rekvid,
                           $2                                                                 AS user_id,
                       r.asutus::TEXT                                                   AS asutus
                FROM qryReport r
                ORDER BY r.asutus`,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        min_params: 2,
        totals: ` sum(alg_saldo) over() as alg_saldo_total,
                sum(arvestatud) over() as arvestatud_total,
                sum(umberarvestus) over() as umberarvestus_total,
                sum(soodustus) over() as soodustus_total, 
                sum(arvestatud + soodustus + umberarvestus) over() as arv_kokku_total, 
                sum(laekumised) over() as laekumised_total,
                sum(mahakantud) over() as mahakantud_total,
                sum(tagastused) over() as tagastused_total,
                sum(jaak) over() as jaak_total `,
        alias: 'kaive_aruanne_report',
        notReloadWithoutParameters: true

    },
    print: [
        {
            view: 'kaive_kokkuvote_register',
            params: 'sqlWhere',
        },
    ],

};
