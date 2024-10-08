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
                    FROM eelarve.lisa1_lisa5_kontrol($1::date, $2::integer, $3::integer) qryReport
                    INNER JOIN ou.rekv r on r.id = $2
                    `,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'lisa1_lisa5_kontrol'
    }
};
