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
        sqlString: ` SELECT * from eelarve.saldo_vordlemine($1::date,  $2::integer)`,     // $1 - kpv , $2 - rekvid (svod)
        params: '',
        alias: 'saldo_vordlemine'
    },
    executeCommand: {
        command: `select error_code, result, error_message from eelarve.sp_koosta_saldoandmik($1::integer, $2::json)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'koosta_saldoandmik'
    },

};
