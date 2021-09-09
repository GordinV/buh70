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
        sqlString: ` SELECT rekv_id,
                            idx,
                            summa,
                            eelmise_summa,
                            konto,
                            grupp,
                            all_grupp,
                            CASE
                                WHEN empty(ltrim(rtrim(nimetus))) AND empty(ltrim(rtrim(all_grupp)))
                                    THEN ltrim(rtrim(grupp))
                                WHEN empty(ltrim(rtrim(nimetus))) THEN ltrim(rtrim(all_grupp))
                                ELSE ltrim(rtrim(nimetus)) END:: VARCHAR(254) AS nimetus
                     FROM eelarve.rahavoog_aruanne($1::DATE, $2::INTEGER, $3::INTEGER)`,     // $1 - kpv , $2 - rekvid (svod), $3 - kond
        params: '',
        alias: 'rahavoog_aruanne'
    },
    executeCommand: {
        command: `SELECT error_code, result, error_message
                  FROM eelarve.sp_koosta_saldoandmik($1::INTEGER, $2::JSON)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'koosta_saldoandmik'
    },

};
