module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "kpv", name: "Seisuga", width: "0%", show: false, type: "date", interval: false},
            {id: "number", name: "Arve nr", width: "10%"},
            {id: "tahtaeg", name: "Tähtaeg", width: "10%", show: true, type: "date", interval: true},
            {id: "lapse_isikukood", name: "Lapse IK", width: "10%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "maksja_isikukood", name: "Maksja IK", width: "10%"},
            {id: "maksja_nimi", name: "Maksja nimi", width: "15%"},
            {id: "noude_50", name: "50%", width: "7%", type: "number", interval: true},
            {id: "noude_100", name: "100%", width: "7%", type: "number", interval: true},
            {id: "jaak", name: "Võlg", width: "7%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "10"},

        ],
        sqlString: `SELECT row_number() OVER ()                                         AS id,
                           sum(qry.noude_50) OVER (PARTITION BY nimetus)                AS noude_50_group,
                           sum(qry.noude_100) OVER (PARTITION BY nimetus)               AS noude_100_group,
                           sum(qry.jaak) OVER (PARTITION BY nimetus)                    AS jaak_group,
                           r.nimetus::VARCHAR(254)                                      AS asutus,
                           qry.kpv::DATE,
                           qry.number::VARCHAR(20),
                           qry.tahtaeg::DATE                                            AS tahtaeg,
                           coalesce(qry.lapse_nimi, '')::VARCHAR(254)                   AS lapse_nimi,
                           coalesce(qry.lapse_isikukood, '')::VARCHAR(20)               AS lapse_isikukood,
                           coalesce(qry.maksja_isikukood, '')::VARCHAR(20)              AS maksja_isikukood,
                           coalesce(qry.maksja_nimi, '')::VARCHAR(254)                  AS maksja_nimi,
                           qry.noude_50,
                           qry.noude_100,
                           qry.jaak,
                           qry.konto::VARCHAR(20)                                       AS konto,
                           qry.rekvid,
                           $2::INTEGER                                                  AS user_id,
                           qry.ArvestatudPaevaraamatus                                  AS arv_pr,
                           (qry.noude_50 + qry.noude_100) - qry.ArvestatudPaevaraamatus AS vahe
                    FROM lapsed.ebatoenaolised($1::INTEGER, $3::DATE) qry
                             INNER JOIN ou.rekv r ON r.id = qry.rekvid
                    WHERE (qry.noude_50 + qry.noude_100) > 0
                    ORDER BY asutus, konto, number
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'kpv'],
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
