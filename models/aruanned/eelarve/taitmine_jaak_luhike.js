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

        sqlString: `WITH qryReport AS (
            SELECT rekv_id,
                   tegev,
                   artikkel,
                   a.nimetus,
                   eelarve,
                   eelarve_kassa,
                   taitmine,
                   taitmine_kassa,
                   r.nimetus AS asutus
            FROM eelarve.eelarve_taitmine_jaak($1::DATE, $2::INTEGER, $3::INTEGER) qryReport
                     LEFT OUTER JOIN com_artikkel a ON ltrim(rtrim(a.kood)) = ltrim(rtrim(qryReport.artikkel))
                     INNER JOIN (SELECT id, parentid, regkood, nimetus
                                 FROM ou.rekv
                                 WHERE parentid < 999
                                     UNION ALL
                                     SELECT 999999
                                     , 0
                                     , '' AS regkood
                                     , 'Kond' AS nimetus) r
                                ON r.id = qryReport.rekv_id
                     LEFT OUTER JOIN ou.rekv p ON r.parentid = p.id
        )
        SELECT rekv_id,
               ''                  AS tegev,
               '15,2586,4,5,6'     AS artikkel,
               'Kulud'             AS nimetus,
               sum(eelarve)        AS eelarve,
               sum(eelarve_kassa)  AS eelarve_kassa,
               sum(taitmine)       AS taitmine,
               sum(taitmine_kassa) AS taitmine_kassa,
               asutus
        FROM qryReport
        WHERE (artikkel LIKE '15%'
           OR artikkel = '2586'
           OR left(artikkel, 1) IN ('4', '5', '6'))
            GROUP BY rekv_id
            , asutus
            UNION ALL
            SELECT rekv_id,
            tegev,
            artikkel,
            nimetus,
            (eelarve) AS eelarve,
            (eelarve_kassa) AS eelarve_kassa,
            (taitmine) AS taitmine,
            (taitmine_kassa) AS taitmine_kassa,
            asutus
            FROM qryReport`,     // $1 - kpv,  $2 - rekvid, $3::integer  1 - kond, 0 - only asutus
        params: '',
        alias: 'taitmine_jaak'
    }
};
