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
        sqlString: `SELECT qry.*, 
                        sum(deebet) over(PARTITION BY leping_id) as deebet_kokku,
                        sum(kreedit) over(PARTITION BY leping_id) as kreedit_kokku,
                        sum(sotsmaks) over(PARTITION BY leping_id) as sotsmaks_kokku       
                    FROM palk.palk_leht($1::DATE, $2::DATE, $3::INTEGER, $4::INTEGER, $5::INTEGER) qry`,     //  $1 - kpv1, $2 - kpv2, $3 - rekvid, $4 svod (null), $5 osakond_id
        params: '',
        alias: 'palk_leht'
    },
    getLog: {
        command: `SELECT l.id,
                         u.kasutaja                     AS kasutaja,
                         $2                             AS user_id,
                         ''::VARCHAR(20)                AS koostatud,
                         ''::VARCHAR(20)                AS muudatud,
                         (case when (coalesce((l.propertis->>'event'),'no') = 'print') then to_char(l.timestamp, 'DD.MM.YYYY HH.MM.SS') else '' end)::VARCHAR(20) as  prinditud,
                         (case when (coalesce((l.propertis->>'event'),'no') = 'email') then to_char(l.timestamp, 'DD.MM.YYYY HH.MM.SS') else '' end)::VARCHAR(20) as  email,
                         (l.propertis->>'mail_info')::text as muud       
                  FROM ou.logs l
                           INNER JOIN ou.userid u ON l.user_id = u.id
                  WHERE coalesce((l.propertis ->> 'isik_id')::INTEGER, 0) = $1::INTEGER
                    AND l.rekvid = u.rekvid
                    ORDER BY l.id DESC 
        `,
        type: "sql",
        alias: "getLogs"
    },
    print: [
        {
            view: 'palk_leht',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS print,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        }
    ],
    email: [
        {
            view: 'arve_email',
            params: 'id',
            register: `UPDATE docs.doc
                       SET history = history ||
                                     (SELECT row_to_json(row)
                                      FROM (SELECT now()                                                AS email,
                                                   (SELECT kasutaja FROM ou.userid WHERE id = $2)::TEXT AS user) row)::JSONB
                       WHERE id = $1`
        }
    ],


};
