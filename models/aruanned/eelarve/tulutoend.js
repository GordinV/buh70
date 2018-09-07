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
        sqlString: ` SELECT
                        d.rekvid,
                        sum(j1.summa) AS summa,
                        j1.kood5                             AS artikkel,
                        l.nimetus                            AS nimetus
                      FROM docs.doc d 
                        inner join docs.journal j on j.parentid = d.id
                        INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                        INNER JOIN ou.rekv rekv ON j.rekvid = rekv.id
                        LEFT OUTER JOIN com_artikkel l ON l.kood = j1.kood5
                        JOIN eelarve.kassa_tulud as kassatulud ON ltrim(rtrim(j1.kreedit)) ~~ ltrim(rtrim(kassatulud.kood))
                        JOIN eelarve.kassa_kontod kassakontod ON ltrim(rtrim((j1.deebet)::text)) ~~ ltrim(rtrim(kassakontod.kood))
                        where j.kpv >= $1 and j.kpv <= $2 
                        and d.rekvid  IN (SELECT rekv_id
                           FROM get_asutuse_struktuur($3))
                      GROUP BY d.rekvid, j1.kood5, l.nimetus
                      ORDER BY d.rekvid,  j1.kood5`,     // $1 - kpv1 $2 - kpv2, $3 - rekvid (svod)
        params: '',
        alias: 'tulutoend_report'
    }
};
