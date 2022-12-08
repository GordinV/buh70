module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "period", name: "Period", width: "0%", show: false, type: "date", interval: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "lapse_isikukood", name: "Lapse IK", width: "0%", show: false},
            {id: "vn", name: "Vana VN", width: "5%"},
            {id: "alg_db", name: "Algsaldo deebet (nõuded)", width: "10%", type: "number", interval: true},
            {id: "alg_kr", name: "Algsaldo kreedit (ettemaksed)", width: "10%", type: "number", interval: true},
            {id: "db", name: "Käive deebet (arvestatud)", width: "10%", type: "number", interval: true},
            {id: "kr", name: "Käive kreedit (maksed)", width: "10%", type: "number", interval: true},
            {id: "mahakantud", name: "Mahakantud", width: "10%", type: "number", interval: true},
            {id: "lopp_db", name: "Lõppsaldo deebet (nõuded)", width: "10%", type: "number", interval: true},
            {id: "lopp_kr", name: "Lõppsaldo kreedit (ettemaksed)", width: "10%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "15%"},
        ],
        sqlString: `WITH report AS (
                        SELECT qryReport.id,
                               qryReport.period,
                               coalesce(alg_db, 0)::NUMERIC(14, 4)     AS alg_db,
                               coalesce(alg_kr, 0)::NUMERIC(14, 4)     AS alg_kr,
                               coalesce(db, 0)::NUMERIC(14, 4)         AS db,
                               coalesce(kr, 0)::NUMERIC(14, 4)         AS kr,
                               coalesce(mahakantud, 0)::NUMERIC(14, 4) AS mahakantud,
                               coalesce(lopp_db, 0)::NUMERIC(14, 4)    AS lopp_db,
                               coalesce(lopp_kr, 0)::NUMERIC(14, 4)    AS lopp_kr,
                               rekvid                                  AS rekv_id,
                               $2                                       AS user_id,
                               asutus::TEXT                            AS asutus,
                               qryReport.isik_id,
                               l.isikukood as lapse_isikukood,
                               lapsed.get_viitenumber(qryReport.rekvid,qryReport.isik_id) as viitenumber,
                               l.nimi as lapse_nimi,
                               vn.vn
                        FROM lapsed.saldo_ja_kaibeandmik($1::INTEGER, $3::date, $4::date) qryReport
                        inner join lapsed.laps l on l.id = qryReport.isik_id
                             LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                              FROM lapsed.viitenr vn
                                              WHERE vn.rekv_id IN (SELECT rekv_id
                                                                   FROM get_asutuse_struktuur($1))
                                              GROUP BY vn.isikukood
                    ) vn
                                             ON vn.isikukood = l.isikukood                        
                    )
                    SELECT count(*) OVER ()                            AS rows_total,
                           count(*) OVER (PARTITION BY report.isik_id) AS id,
                           lapse_isikukood,
                           lapse_nimi,
                           vn,
                           viitenumber,
                           period,
                           (alg_db)                                 AS alg_db,
                           (alg_kr)                                 AS alg_kr,
                           (db)                                     AS db,
                           (kr)                                     AS kr,
                           (mahakantud)                             AS mahakantud,
                           (lopp_db)                                AS lopp_db,
                           (lopp_kr)                                AS lopp_kr,
                           asutus
                    FROM report
                    ORDER BY asutus,lapse_nimi `,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        notReloadWithoutParameters: true,
        totals: `sum(alg_db) OVER ()           AS alg_db_total,
                 sum(alg_kr) OVER ()           AS alg_kr_total,
                 sum(db) OVER ()               AS db_total,
                 sum(kr) OVER ()               AS kr_total,
                 sum(mahakantud) OVER ()       AS mahakantud_total,
                 sum(lopp_db) OVER ()          AS lopp_db_total,
                 sum(lopp_kr) OVER ()          AS lopp_kr_total`,
        alias: 'saldo_ja_kaibeandmik_report'
    },
    print: [
        {
            view: 'saldo_ja_kaibeandmik_register',
            params: 'sqlWhere',
        },
    ],

};
