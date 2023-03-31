module.exports = {
    grid: {
        gridConfiguration: [
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "10%", filterValidation: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "viitenumber", name: "Viitenumber", width: "10%"},
            {id: "vanem_nimi", name: "Maksja", width: "15%"},
            {
                id: "period",
                name: "Period",
                width: "0%",
                show: false,
                type: "date",
                interval: true,
                filterValidation: true
            },
            {id: "arv_period", name: "Period", width: "5%", hideFilter: true},
            {id: "alg_db", name: "Algsaldo deebet (nõuded)", width: "8%", type: "number", interval: true},
            {id: "alg_kr", name: "Algsaldo kreedit (ettemaksed)", width: "8%", type: "number", interval: true},
            {id: "db", name: "Käive deebet (arvestatud)", width: "8%", type: "number", interval: true},
            {id: "kr", name: "Käive kreedit (maksed)", width: "8%", type: "number", interval: true},
            {id: "mahakantud", name: "Mahakantud", width: "8%", type: "number", interval: true},
            {id: "lopp_db", name: "Lõppsaldo deebet (nõuded)", width: "8%", type: "number", interval: true},
            {id: "lopp_kr", name: "Lõppsaldo kreedit (ettemaksed)", width: "8%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "10%"},
        ],
        sqlString: `WITH report AS (
                        SELECT qryReport.id,
                               qryReport.period,
                               qryReport.arv_period,                               
                               alg_db     AS alg_db,
                               alg_kr     AS alg_kr,
                               coalesce(db, 0)::NUMERIC(14, 2)         AS db,
                               coalesce(kr, 0)::NUMERIC(14, 2)         AS kr,
                               coalesce(mahakantud, 0)::NUMERIC(14, 2) AS mahakantud,
                               lopp_db    AS lopp_db,
                               lopp_kr    AS lopp_kr,
                               qryReport.rekvid                                  AS rekv_id,
                               qryReport.asutus::TEXT                            AS asutus,
                               qryReport.isik_id,
                               l.isikukood as lapse_isikukood,
                               lapsed.get_viitenumber(qryReport.rekvid,qryReport.isik_id) as viitenumber,
                               $2                                       AS user_id,
                               l.nimi as lapse_nimi,
                               vn.vn,
                               a.nimetus                                                   AS vanem_nimi                               
                        FROM lapsed.saldo_ja_kaibeandmik_period($1::INTEGER, $3::date, $4::date, $5::text) qryReport
                        inner join lapsed.laps l on l.id = qryReport.isik_id
                             LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                              FROM lapsed.viitenr vn
                                              WHERE vn.rekv_id IN (SELECT rekv_id
                                                                   FROM get_asutuse_struktuur($1))
                                              AND vn.isikukood LIKE $5 || '%'
                                              GROUP BY vn.isikukood
                    ) vn
                                             ON vn.isikukood = l.isikukood                        
                             LEFT OUTER JOIN lapsed.vanem_arveldus va ON va.parentid = l.id
                        AND va.rekvid = qryReport.rekvid
                        AND va.arveldus
                             LEFT OUTER JOIN libs.asutus a ON a.id = va.asutusid
                                             
                    )
                    SELECT count(*) OVER ()                            AS rows_total,
                           count(*) OVER (PARTITION BY report.isik_id) AS id,
                           lapse_isikukood,
                           lapse_nimi,
                           vn,
                           viitenumber,
                           period,
                           arv_period,
                           (alg_db)                                 AS alg_db,
                           (alg_kr)                                 AS alg_kr,
                           (db)                                     AS db,
                           (kr)                                     AS kr,
                           (mahakantud)                             AS mahakantud,
                           (lopp_db)                                AS lopp_db,
                           (lopp_kr)                                AS lopp_kr,
                           asutus,
                           vanem_nimi,
                           to_char($3::date,'DD.MM.YYYY') || '-' || to_char($4::date,'DD.MM.YYYY') as print_period
                    FROM report
                    ORDER BY asutus,lapse_nimi, 
                        case when left(arv_period,1) = 'A' then 'a' when  left(arv_period,1) = 'L' then 'l' else 'k'  end,
                        arv_period`,
        params: ['rekvid', 'userid', 'period_start', 'period_end', 'lapse_isikukood'],
        notReloadWithoutParameters: true,
        alias: 'child_summary_report_period',
        totals: `sum(db) OVER ()               AS db_total,
                 sum(kr) OVER ()               AS kr_total,
                 sum(mahakantud) OVER ()       AS mahakantud_total`,
    },
    print: [
        {
            view: 'child_summary_kaibed',
            params: 'sqlWhere',
            group: 'lapse_isikukood'
        },
    ],

};
