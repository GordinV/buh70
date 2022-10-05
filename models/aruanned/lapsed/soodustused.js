module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "vanem_isikukood", name: "Vanem isikukood", width: "10%"},
            {id: "vanem_nimi", name: "Vanem nimi", width: "15%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "10%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "vana_vn", name: "Vana VN", width: "10%"},
            {id: "soodustus", name: "%", width: "5%", type: "number"},
            {id: "period", name: "Period", width: "5%", show: false, type: "date", interval: true},
            {id: "viga", name: "Viga", width: "10%"},
            {id: "asutus", name: "Asutus", width: "10%"},
        ],
        sqlString: `SELECT row_number() OVER ()                                                         AS id,
                           count(*) OVER ()                                                             AS lapsed_kokku,
                           sum(CASE
                                   WHEN lapsed <= 2 AND soodustus > 25 THEN 1
                                   WHEN lapsed = 2 AND soodustus <> 25 THEN 1
                                   WHEN lapsed > 2 AND soodustus < 100 THEN 1
                                   ELSE 0 END) OVER ()                                                  AS vead_kokku,
                           soodustus,
                           CASE WHEN lapsed = 2 THEN '25' WHEN lapsed >= 3 THEN '100' ELSE '' END::TEXT AS percent,
                           period                                                                       AS period,
                           lapse_isikukood,
                           lapse_nimi,
                           vanem_nimi,
                           vanem_isikukood,
                           lapsed,
                           pered_kokku,
                           asutus,
                           CASE
                               WHEN lapsed <= 2 AND soodustus > 25 THEN 'Viga, > 25'
                               WHEN lapsed = 2 AND soodustus <> 25 THEN 'Viga, <> 25'
                               WHEN lapsed > 2 AND soodustus < 100 THEN 'Viga, < 100'
                               ELSE NULL::TEXT
                               END::TEXT                                                                AS viga,
                           $2                                                                           AS user_id,
                           vn.vn                                                                        AS vana_vn
                    FROM lapsed.soodustused($1, 1, $3, $4) qry
                             LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                              FROM lapsed.viitenr vn
                                              WHERE vn.rekv_id IN (SELECT rekv_id
                                                                   FROM get_asutuse_struktuur($1))
                                              GROUP BY vn.isikukood
                    ) vn
                                             ON vn.isikukood = qry.lapse_isikukood

                    WHERE qry.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur($1))
                    ORDER BY vanem_isikukood, lapse_nimi
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        notReloadWithoutParameters: true,
        alias: 'soodustused_report'
    },
    print: [
        {
            view: 'soodustused_register',
            params: 'sqlWhere',
            group: 'vanem_isikukood'
        },
    ],

};
