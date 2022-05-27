module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "period", name: "Period", width: "10%", show: false, type: "date", interval: true},
            {id: "nimetus", name: "Nimetus", width: "50%"},
            {id: "text_indikator", name: "Selgitus", width: "50%"},
            {id: "indikator_1", name: " 1 ", width: "15%"},
            {id: "indikator_2", name: " 2 ", width: "15%"},
            {id: "indikator_3", name: " 3 ", width: "15%"},

        ],
        sqlString: `SELECT row_number() OVER ()                             AS id,
                           sum(qry.indikator_1) OVER (PARTITION BY nimetus) AS indikator_1_group,
                           sum(qry.indikator_2) OVER (PARTITION BY nimetus) AS indikator_2_group,
                           sum(qry.indikator_3) OVER (PARTITION BY nimetus) AS indikator_3_group,
                           nimetus,
                           text_indikator,
                           indikator_1,
                           indikator_2,
                           indikator_3,
                           $2                                               AS user_id,
                           period,
                           aruanne
                    FROM lapsed.statistika($1, 1, $3, $4) qry
                    WHERE qry.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur($1))
                    ORDER BY aruanne, text_indikator
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        notReloadWithoutParameters: true,
        alias: 'statistika_report'
    },
    print: [
        {
            view: 'statistika_register',
            params: 'sqlWhere',
            group: 'aruanne'
        },
    ],

};
