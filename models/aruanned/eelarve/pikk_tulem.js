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
        sqlString: ` SELECT CASE WHEN konto IN ('39999','9999', '99999','9999999') THEN '' ELSE konto END AS konto,
                            nimetus,
                            summa,
                            rekv_id
                     FROM eelarve.pikk_tulem($1::DATE, $2::INTEGER, $3::INTEGER)
                     ORDER BY idx, konto`,     // $1 - kpv , $2 - rekvid (svod), $3 - kond
        params: '',
        alias: 'pikk_tulem'
    },
    executeCommand: {
        command: `SELECT error_code, result, error_message
                  FROM eelarve.sp_koosta_saldoandmik($1::INTEGER, $2::JSON)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'koosta_saldoandmik'
    },

};
