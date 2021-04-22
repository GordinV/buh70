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
                           a.nimetus::VARCHAR(254),
                           r.regkood::VARCHAR(20),
                           r.nimetus::VARCHAR(254)               AS asutus,
                           coalesce(p.regkood, '')::VARCHAR(20)  AS parregkood,
                           coalesce(p.nimetus, '')::VARCHAR(254) AS parasutus
                    FROM eelarve.eelarve_taitmine_allikas_artikkel($1::INTEGER, $2::DATE, $3::DATE, $4::INTEGER,
                                                                   $5::INTEGER) qryReport
                             LEFT OUTER JOIN com_artikkel a ON ltrim(rtrim(a.kood)) = ltrim(rtrim(qryReport.artikkel))
                             INNER JOIN (SELECT id, parentid, regkood, nimetus
                                         FROM ou.rekv
                                         WHERE parentid < 999
                                         UNION ALL
                                         SELECT 999999, 0, '' AS regkood, 'Kond' AS nimetus) r
                                        ON r.id = qryReport.rekv_id
                             LEFT OUTER JOIN ou.rekv p ON r.parentid = p.id                    `,     // $1 - aasta $2 - kpv_alg, $3 - kpv_lopp, $4 - rekvid (svod), $5::integer  1 - kond, 0 - only asutus
        params: '',
        alias: 'kulud_report'
    }
};
