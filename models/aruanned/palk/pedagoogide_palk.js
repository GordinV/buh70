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
        sqlString: `SELECT qry.*, r.nimetus::varchar(254) AS asutus
                    FROM palk.pedagoogide_palk($1::DATE, $2::DATE, $3::INTEGER, $4::INTEGER, $5::JSONB) qry
                             INNER JOIN ou.rekv r ON r.id = qry.rekv_id
                    ORDER BY r.nimetus, qry.Isik, qry.konto`,     //  $1 - kpv1, $2 - kpv2, $3 - rekvid, $4 svod (null)
        params: '',
        alias: 'pedagoogide_palk'
    }
};
