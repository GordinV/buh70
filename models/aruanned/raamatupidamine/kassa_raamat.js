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
        sqlString: `SELECT 
                      sum(deebet) OVER (PARTITION BY kpv)  AS db_kaibed,
                      sum(kreedit) OVER (PARTITION BY kpv) AS kr_kaibed,
                      min(lopp_paevi_saldo) over (PARTITION BY kassa order by kpv) as kassa_alg_jaak,
                      max(lopp_paevi_saldo) over (PARTITION BY kassa order by kpv) as kassa_lopp_jaak,
                       *                    
                    FROM docs.kassa_raamat($1::date, $2::date, $3::integer) qry
                    ORDER BY kassa, kpv, number`,     //  $1 - kpv1, $2 - kpv2, $3 - rekvid
        params: '',
        alias: 'kassa_raamat'
    }
};
