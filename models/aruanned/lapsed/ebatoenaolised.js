module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "kpv", name: "Seisuga", width: "0%", show: false, type: "date", interval: false},
            {id: "number", name: "Arve nr", width: "10%"},
            {id: "tahtaeg", name: "Tähtaeg", width: "10%", show: true, type: "date", interval: true},
            {id: "lapse_isikukood", name: "Lapse IK", width: "10%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "maksja_isikukood", name: "Maksja nimi", width: "10%"},
            {id: "maksja_nimi", name: "Maksja nimi", width: "15%"},
            {id: "noude_50", name: "50%", width: "7%", type: "number"},
            {id: "noude_100", name: "100%", width: "7%", type: "number"},
            {id: "jaak", name: "Võlg", width: "7%", type: "number"},
            {id: "asutus", name: "Asutus", width: "10"},

        ],
        sqlString: `SELECT row_number() OVER ()                           AS id,
                           sum(qry.noude_50) OVER (PARTITION BY nimetus)  AS noude_50_group,
                           sum(qry.noude_100) OVER (PARTITION BY nimetus) AS noude_100_group,
                           sum(qry.jaak) OVER (PARTITION BY nimetus)      AS jaak_group,
                           r.nimetus::TEXT                                AS asutus,
                           qry.kpv,
                           qry.number,
                           to_char(qry.tahtaeg, 'DD.MM.YYYY')             AS tahtaeg,
                           qry.lapse_nimi,
                           qry.lapse_isikukood,
                           qry.maksja_isikukood,
                           qry.maksja_nimi,
                           qry.noude_50,
                           qry.noude_100,
                           qry.jaak,
                           $2                                             AS user_id
                    FROM lapsed.ebatoenaolised($1, $3) qry
                             INNER JOIN ou.rekv r ON r.id = qry.rekvid
                    WHERE noude_50 > 0
                       OR noude_100 > 0
                    ORDER BY asutus, number
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'kpv'],
        alias: 'ebatoenaolised_report'
    },
    print: [
        {
            view: 'ebatoenaolised_register',
            params: 'sqlWhere',
            group: 'asutus'
        },
    ],

};
