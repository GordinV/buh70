module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_db", name: "Alg.Deebet", width: "100px"},
            {id: "alg_kr", name: "Alg.Kreedit", width: "75px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "alopp_db", name: "Lõpp deebet", width: "100px"},
            {id: "lopp_kr", name: "Lõpp kreedit", width: "200px"}
        ],
        sqlString: `SELECT report.idx:: VARCHAR(20),
                           report.rekvid:: INTEGER,
                           report.tegev:: VARCHAR(20),
                           report.allikas:: VARCHAR(20),
                           report.artikkel:: VARCHAR(20),
                           report.nimetus:: VARCHAR(254),
                           report.kassa:: NUMERIC(14, 2),
                           r.nimetus::VARCHAR(254) AS asutus
                    FROM eelarve.eelarve_andmik_lisa_1_5_detailne($1::DATE, $2::INTEGER,
                                                                  $3::INTEGER) report
                             LEFT OUTER JOIN ou.rekv r ON r.id = report.rekvid`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'eelarve_andmik_lisa_1_5_report'
    },
};
