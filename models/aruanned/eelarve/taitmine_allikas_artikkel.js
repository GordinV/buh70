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
        sqlString: `SELECT
                        qryReport.*,
                        a.nimetus::varchar(254),
                        r.regkood::varchar(20),
                        r.nimetus::varchar(254) AS asutus,
                        coalesce(p.regkood,'')::varchar(20) AS parregkood,
                        coalesce(p.nimetus,'')::varchar(254) AS parasutus
                    FROM eelarve.eelarve_taitmine_allikas_artikkel($1::integer,$2::date, $3::integer, $4::integer) qryReport
                    LEFT OUTER JOIN com_artikkel a ON ltrim(rtrim(a.kood)) = ltrim(rtrim(qryReport.artikkel))
                    INNER JOIN ou.rekv r ON r.id = qryReport.rekv_id
                    LEFT OUTER JOIN ou.rekv p ON r.parentid = p.id                    `,     // $1 - aasta $2 - kpv,  $3 - rekvid (svod), $4::integer  1 - kond, 0 - only asutus
        params: '',
        alias: 'kulud_report'
    }
};
