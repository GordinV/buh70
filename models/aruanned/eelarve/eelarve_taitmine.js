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
                      qryReport.rekv_id,  
                      qryReport.artikkel,
                      qryReport.tegev,
                      qryReport.allikas,
                      sum(eelarve_2)  AS eelarve_2,
                      sum(taitmine_2) AS taitmine_2,
                      sum(eelarve_1)  AS eelarve_1,
                      sum(taitmine_1) AS taitmine_1,
                      sum(eelarve_0)  AS eelarve_0,
                      sum(taitmine_0) AS taitmine_0,
                      a.nimetus :: VARCHAR(254),
                      coalesce(a.is_kulud,false)::boolean as is_kulud
                    FROM eelarve.eelarve_taitmine($1::integer, $2::integer, $3::integer) qryReport
                      LEFT OUTER JOIN com_artikkel a ON a.kood :: TEXT = qryReport.artikkel :: TEXT
                    GROUP BY qryReport.rekv_id, qryReport.artikkel, qryReport.tegev, qryReport.allikas, a.nimetus, a.is_kulud`,     // $1 - aasta $2 - rekvid, $3 - kond
        params: '',
        alias: 'eelarve_taitmine_report'
    }
};
