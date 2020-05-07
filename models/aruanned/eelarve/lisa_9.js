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
        sqlString: `SELECT *                      
                    FROM eelarve.lisa_9($1::date,$2::date, $3::integer, $4::integer) qryReport
                    ORDER BY maksja_regkood, saaja_nimi, kpv, artikkel, tegev
                    `,     // $1 - alg_kpv $2 - lopp_kpv, $3 - rekvid, $4 - kond
        params: '',
        alias: 'lisa_9'
    }
};
