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
        sqlString: ` SELECT * from eelarve.kond_saldoandmik_aruanne($1::date,  $2::integer, $3::integer, $4::boolean)`,     // $1 - kpv , $2 - rekvid (svod), $3 - kond, $4 - kas xml
        params: '',
        alias: 'kond_saldoandmik_report'
    },
    executeCommand: {
        command: `select error_code, result, error_message from eelarve.sp_koosta_saldoandmik($1::integer, $2::json)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'koosta_saldoandmik'
    },

};
