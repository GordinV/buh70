module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "kpv", name: "Seisuga", width: "0%", show: false, type: "date", interval: false},
            {id: "number", name: "Arve nr", width: "7%"},
            {id: "tahtaeg", name: "Tähtaeg", width: "7%", show: true, type: "date", interval: true},
            {id: "lapse_isikukood", name: "Lapse IK", width: "7%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "12%"},
            {id: "maksja_isikukood", name: "Maksja IK", width: "7%"},
            {id: "maksja_nimi", name: "Maksja nimi", width: "12%"},
            {id: "noude_50", name: "50%", width: "7%", type: "number", interval: true},
            {id: "noude_100", name: "100%", width: "7%", type: "number", interval: true},
            {id: "jaak", name: "Võlg", width: "7%", type: "number", interval: true},
            {
                id: "arv_pr",
                name: "Arvestatud päevaraamatus",
                width: "7%",
                type: "number",
                interval: true
            },
            {id: "vahe", name: "Vahe", width: "5%", type: "number", interval: false},
            {id: "asutus", name: "Asutus", width: "10"},

        ],
        sqlString: `SELECT row_number() OVER ()                                         AS id,
                           sum(qry.noude_50) OVER (PARTITION BY nimetus)                AS noude_50_group,
                           sum(qry.noude_100) OVER (PARTITION BY nimetus)               AS noude_100_group,
                           sum(qry.jaak) OVER (PARTITION BY nimetus)                    AS jaak_group,
                           r.nimetus::TEXT                                              AS asutus,
                           r.id                                                         AS rekvid,
                           qry.kpv,
                           qry.number,
                           to_char(qry.tahtaeg, 'DD.MM.YYYY')                           AS tahtaeg,
                           qry.lapse_nimi,
                           qry.lapse_isikukood,
                           qry.maksja_isikukood,
                           qry.maksja_nimi,
                           qry.noude_50,
                           qry.noude_100,
                           qry.jaak,
                           $2                                                           AS user_id,
                           qry.ArvestatudPaevaraamatus                                  AS arv_pr,
                           (qry.noude_50 + qry.noude_100) - qry.ArvestatudPaevaraamatus AS vahe
                    FROM lapsed.ebatoenaolised($1, $3) qry
                             INNER JOIN ou.rekv r ON r.id = qry.rekvid
                    WHERE
                          ((qry.noude_50 + qry.noude_100) > 0
                        OR ((qry.noude_50 + qry.noude_100) - qry.ArvestatudPaevaraamatus ) <> 0)                              
                      AND qry.lapse_isikukood IS NOT NULL
                    ORDER BY asutus, number
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'kpv'],
        totals: `sum(noude_50) OVER (PARTITION BY rekvid)           AS noude_50_total,
                 sum(noude_100) OVER (PARTITION BY rekvid)           AS noude_100_total,
                 sum(arv_pr) OVER (PARTITION BY rekvid)           AS arv_pr_total,
                 sum(vahe) OVER (PARTITION BY rekvid)           AS vahe_total,
                 sum(jaak) OVER (PARTITION BY rekvid)           AS jaak_total`,
        min_params: 1,
        alias: 'ebatoenaolised_report',
        notReloadWithoutParameters: true

    },
    print: [
        {
            view: 'ebatoenaolised_register',
            params: 'sqlWhere',
            group: 'asutus'
        },
    ],

};
