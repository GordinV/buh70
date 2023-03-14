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
        sqlString: ` 
                     SELECT rekv_id,
                            konto::VARCHAR(20),
                            tp::VARCHAR(20),
                            tegev::VARCHAR(20),
                            allikas::VARCHAR(20),
                            rahavoog::VARCHAR(20),
                            sum(deebet)   AS deebet,
                            sum(kreedit)  AS kreedit,
                            tyyp::INTEGER AS tyyp
                     FROM eelarve.saldoandmik_aruanne($1 :: DATE, $2 :: INTEGER, $3 ::INTEGER, $4::JSONB)
                     WHERE deebet <> 0
                        OR kreedit <> 0
                     GROUP BY rekv_id
                             , konto
                             , tp
                             , tegev
                             , allikas
                             , rahavoog
                             , tyyp`,
        // $1 - kpv $2 - rekvid , $3 - KOND, $4 tunnus
        params: '',
        alias: 'saldoandmik_report'
    }
};
