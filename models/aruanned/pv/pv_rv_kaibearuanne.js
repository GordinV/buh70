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
        sqlString: `SELECT qry.*
                    FROM docs.pv_rv_kaibe_aruanne($1::DATE, $2::DATE, $3::INTEGER, $4::INTEGER, $5::jsonb) qry
                    ORDER BY konto, kood`,     // $1 - kpv1, $2 - kpv2, $3- rekvid, $4 - kond
        params: '',
        alias: 'pv_rv_kaibe_aruanne_report'
    }
};
