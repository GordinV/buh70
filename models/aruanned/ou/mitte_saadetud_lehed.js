module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_db", name: "Alg.Deebet", width: "100px"},
            {id: "alg_kr", name: "Alg.Kreedit", width: "75px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "lopp_db", name: "Lõpp deebet", width: "100px"},
            {id: "lopp_kr", name: "Lõpp kreedit", width: "200px"}
        ],
        sqlString: `SELECT DISTINCT t.rekvid,
                                    t.id,
                                    r.parentid,
                                    r.regkood,
                                    r.nimetus AS asutus,
                                    r.muud    AS asutus_tais,
                                    t.nimetus AS nimi,
                                    t.email
                    FROM palk.cur_tootajad t
                             INNER JOIN ou.rekv r ON r.id = t.rekvid
                    WHERE (lopp IS NULL OR lopp >= $1::DATE)
                      AND (t.email IS NOT NULL AND NOT empty(t.email) AND t.email LIKE '%@%')
                      AND t.rekvid IN (SELECT rekv_id
                                       FROM get_asutuse_struktuur($2))
                      AND t.rekvid = (CASE
                                          WHEN $3::INTEGER IS NULL OR empty($3::INTEGER)
                                              THEN $2::INTEGER
                                          ELSE t.rekvid END)
                      AND t.id NOT IN (
                        SELECT (propertis ->> 'isik_id')::INTEGER
                        FROM ou.logs
                        WHERE doc_id = 213041
                          AND propertis ->> 'event' = 'email'
                          AND month((timestamp)::DATE) = month($1::DATE)
                          AND year(timestamp::DATE) = year($1::DATE)
                    )
                    ORDER BY r.parentid, t.rekvid, t.id`,     //  $1 - kpv1, $2- rekvid, $3 svod (null)
        params: '',
        alias: 'saadetud_palk_leht'
    },
};
