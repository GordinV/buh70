module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "Konto", width: "100px"},
            {id: "korr_konto", name: "Korr.konto", width: "75px"},
            {id: "alg_saldo", name: "Alg.saldo", width: "100px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "lopp_saldo", name: "Lopp saldo", width: "200px"}
        ],
        sqlString: `SELECT
                      coalesce(sum(deebet)
                        FILTER (WHERE korr_konto IS NULL) OVER (
                        PARTITION BY rekv_id, konto ),0)::numeric(12,2) AS alg_saldo,
                      CASE WHEN korr_konto IS NOT NULL
                        THEN deebet
                      ELSE 0 END                      AS deebet,
                      kreedit,
                      sum(deebet - kreedit)
                      OVER (
                        PARTITION BY rekv_id, konto ) AS lopp_saldo,
                      rekv_id,
                      konto,
                      korr_konto                    
                    FROM docs.pearaamat($1::text, $2::date, $3 :: DATE, $4::integer)`,     //  $1 конто $2 - kpv1, $3 - kpv2, $4 - rekvid (svod)
        params: '',
        alias: 'pearaamat_report'
    }
};
