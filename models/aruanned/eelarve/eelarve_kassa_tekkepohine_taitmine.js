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
        sqlString: `SELECT
                      qryReport.rekv_id,
                      qryReport.tunnus,
                      qryReport.tegev,
                      qryReport.allikas,
                      qryReport.artikkel,
                      qryReport.eelarve_kinnitatud,
                      qryReport.eelarve_tapsustatud,
                      qryReport.taitmine_kassa,
                      qryReport.taitmine_tekke,
                      a.nimetus :: VARCHAR(254) as nimetus,
                      r.nimetus:: VARCHAR(254) as asutus,
                      qryReport.is_kulud::INTEGER as is_kulud
                    FROM  eelarve.eelarve_kassa_tekkepohine_taitmine($1::date, $2::integer, $3::integer) qryReport
                      LEFT OUTER JOIN com_artikkel a ON a.kood :: TEXT = qryReport.artikkel :: TEXT
                      INNER JOIN ou.rekv r on r.id = qryReport.rekv_id
                    ORDER BY qryReport.is_kulud, r.parentid, r.nimetus, qryReport.allikas, qryReport.tegev, qryReport.artikkel`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'eelarve_taitmine_report'
    }
};
