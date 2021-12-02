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
        sqlString: `SELECT qryReport.*,
                           r.regkood::VARCHAR(20),
                           r.nimetus::VARCHAR(254) AS asutus
                    FROM eelarve.tulud_eelnou($1::DATE, $2::INTEGER, $3::INTEGER) qryReport
                             INNER JOIN (SELECT id, parentid, regkood, nimetus
                                         FROM ou.rekv
                                         WHERE parentid < 999
                                         UNION ALL
                                         SELECT 999999, 0, '' AS regkood, 'Kond' AS nimetus) r
                                        ON r.id = qryReport.rekv_id
                             LEFT OUTER JOIN ou.rekv p ON r.parentid = p.id
                    ORDER BY r.id DESC, r.parentid, qryReport.rekv_id, qryReport.idx,
                             qryReport.artikkel                             `,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'tulud_eelnou'
    }
};
