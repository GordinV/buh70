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
                    FROM eelarve.eelarve_tulud($1::integer,$2::date, $3::date, $4::boolean, $5::integer, $6::integer) qryReport
                    INNER JOIN ou.rekv r ON r.id = qryReport.rekv_id
                    LEFT OUTER JOIN com_artikkel a ON a.kood::text = qryReport.artikkel::text
                    LEFT OUTER JOIN ou.rekv p ON r.parentid = p.id                    `,     // $1 - aasta $2 - kpv, $3 - parandus, $4 - rekvid (svod)
        params: '',
        alias: 'tulud_report'
    }
};
