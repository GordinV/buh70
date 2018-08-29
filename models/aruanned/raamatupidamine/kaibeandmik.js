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
                      qry.rekv_id,
                      qry.konto,
                      l.nimetus,
                      (CASE WHEN l.tyyp IN (0, 1, 3)
                        THEN qry.alg_saldo
                       ELSE 0 END) :: NUMERIC(14, 2) AS alg_db,
                      (CASE WHEN l.tyyp IN (2, 4)
                        THEN -1 * qry.alg_saldo
                       ELSE 0 END) :: NUMERIC(14, 2) AS alg_kr,
                      qry.deebet,
                      qry.kreedit,
                      (CASE WHEN l.tyyp IN (0, 1, 3)
                        THEN (qry.alg_saldo + deebet - kreedit)
                       ELSE 0 END) :: NUMERIC(14, 2) AS lopp_db,
                      (CASE WHEN l.tyyp IN (2, 4)
                        THEN -1 * (qry.alg_saldo + deebet - kreedit)
                       ELSE 0 END) :: NUMERIC(14, 2) AS lopp_kr
                    FROM docs.kaibeandmik($1::date, $2::date, $3::integer) qry
                      INNER JOIN com_kontoplaan l ON l.kood = qry.konto`,     //  $1 - kpv1, $2 - kpv2, $3 - rekvid (svod)
        params: '',
        alias: 'kaibeandmik_report'
    }
};
