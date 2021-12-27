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
        sqlString: `SELECT qryReport.*, r.nimetus as asutus
                    FROM eelarve.lisa_9($1::DATE, $2::DATE, $3::INTEGER, $4::INTEGER) qryReport
                             INNER JOIN ou.rekv r ON r.id = qryReport.rekv_id
                    ORDER BY maksja_regkood, asutus, saaja_nimi, kpv, artikkel, tegev
        `,     // $1 - alg_kpv $2 - lopp_kpv, $3 - rekvid, $4 - kond
        params: '',
        alias: 'lisa_9'
    }
};
