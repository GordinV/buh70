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
        sqlString: `select * 
        from docs.pv_kulud($1::DATE, $2::DATE, $3::INTEGER, $4::JSONB) qry`,     //  $1 - kpv1, $2 - kpv2, $3 - rekvid (svod),  $4 - доп. параметры
        params: '',
        alias: 'pv_kulud_report'
    }
};
