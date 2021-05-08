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
        sqlString: ` WITH qryDocs AS (
                        SELECT j1.id
                        FROM docs.doc d
                                 INNER JOIN docs.journal j ON j.parentid = d.id
                                 INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                                 JOIN eelarve.kassa_tulud AS kassatulud ON ltrim(rtrim(j1.kreedit)) ~~ ltrim(rtrim(kassatulud.kood))
                                 JOIN eelarve.kassa_kontod kassakontod ON ltrim(rtrim((j1.deebet)::TEXT)) ~~ ltrim(rtrim(kassakontod.kood))
                        WHERE j.kpv >= $1 and j.kpv <= $2 
                            and d.rekvid  IN (SELECT rekv_id
                                FROM get_asutuse_struktuur($3))
                          AND d.status <> 3
                    )
                    SELECT d.rekvid,
                           sum(j1.summa) AS summa,
                           j1.kood5      AS artikkel,
                           l.nimetus     AS nimetus
                    FROM docs.doc d
                             INNER JOIN docs.journal j ON j.parentid = d.id
                             INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                             LEFT OUTER JOIN com_artikkel l ON l.kood = j1.kood5
                    WHERE j1.id IN (SELECT id FROM qryDocs)
                    GROUP BY d.rekvid, j1.kood5, l.nimetus
                    ORDER BY d.rekvid, j1.kood5`,     // $1 - kpv1 $2 - kpv2, $3 - rekvid (svod)
        params: '',
        alias: 'tulutoend_report'
    }
};
