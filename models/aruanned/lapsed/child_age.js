module.exports = {
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "0%", show: false},
            {id: "isikukood", name: "Isikukood", width: "20%"},
            {id: "nimi", name: "Lapse nimi", width: "40%"},
            {id: "age", name: "Sünniaeg", width: "10%", type: "date", interval: true},
            {id: "age_27", name: "27 aastane", width: "10%", type: "date", interval: true},
            {id: "asutus", name: "Asutud", width: "20%"},
        ],
        sqlString: `SELECT row_number() OVER ()                                                             AS id,
                           qry.isikukood,
                           qry.nimi,
                           qry.asutus,
                           to_char(date_of_birth, 'DD.MM.YYYY')                                             AS age,
                           to_char(current_date + (INTERVAL '27 years' - age(date_of_birth)), 'DD.MM.YYYY') AS age_27
                    FROM (
                             SELECT l.isikukood,
                                    l.nimi,
                                    r.nimetus                             AS asutus,
                                    lk.rekvid,
                                    lapsed.get_date_of_birth(l.isikukood) AS date_of_birth,
                                    $2                                    AS userid
                             FROM lapsed.laps l
                                      INNER JOIN (SELECT DISTINCT parentid, rekvid
                                                  FROM lapsed.lapse_kaart lk
                                                  WHERE lk.staatus <> 3) lk ON lk.parentid = l.id
                                      INNER JOIN ou.rekv r ON lk.rekvid = r.id
                         ) qry
                    WHERE date_of_birth IS NOT NULL
                      AND qry.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur($1))
                    ORDER BY qry.asutus, qry.nimi
        `,     // $1 - rekvid, $3 - kond
        params: '',
        alias: 'child_age_report'
    },
    print: [
        {
            view: 'child_age_report',
            params: 'sqlWhere',
            group: 'asutus',
        },
    ],

};
