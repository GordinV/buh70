module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "period", name: "Period", width: "0%", show: false, type: "date", interval: true},
            {id: "asutus", name: "Asutus", width: "20%"},
            {id: "alg_db", name: "Algsaldo deebet (nõuded)", width: "15%", type: "number", interval: true},
            {id: "alg_kr", name: "Algsaldo kreedit (ettemaksed)", width: "15%", type: "number", interval: true},
            {id: "db", name: "Käive deebet (arvestatud)", width: "15%", type: "number", interval: true},
            {id: "kr", name: "Käive kreedit (maksed)", width: "15%", type: "number", interval: true},
            {id: "mahakantud", name: "Mahakantud", width: "15%", type: "number", interval: true},
            {id: "lopp_db", name: "Lõppsaldo deebet (nõuded)", width: "15%", type: "number", interval: true},
            {id: "lopp_kr", name: "Lõppsaldo kreedit (ettemaksed)", width: "15%", type: "number", interval: true},
        ],
        sqlString: `SELECT count(*) OVER ()                        AS rows_total,
                           qryReport.id,
                           qryReport.period,
                           coalesce(alg_db, 0)::NUMERIC(14, 4)     AS alg_db,
                           coalesce(alg_kr, 0)::NUMERIC(14, 4)     AS alg_kr,
                           coalesce(db, 0)::NUMERIC(14, 4)         AS db,
                           coalesce(kr, 0)::NUMERIC(14, 4)         AS kr,
                           coalesce(mahakantud, 0)::NUMERIC(14, 4) AS mahakantud,
                           coalesce(lopp_db, 0)::NUMERIC(14, 4)    AS lopp_db,
                           coalesce(lopp_kr, 0)::NUMERIC(14, 4)    AS lopp_kr,
                           rekvid,
                           $2                                      AS user_id,
                           asutus::TEXT                            AS asutus
                    FROM lapsed.saldo_ja_kaibeandmik($1::INTEGER, $3::date, $4::date) qryReport
                    ORDER BY asutus
        `,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
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
