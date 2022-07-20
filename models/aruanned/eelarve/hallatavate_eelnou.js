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
        sqlString: `SELECT CASE
                               WHEN r.parentid IN (119, 3, 64) THEN ltrim(rtrim(coalesce(p.nimetus, '')))
                               ELSE ltrim(rtrim(coalesce(r.nimetus, ''))) END ::VARCHAR(254) AS asutus,
                           CASE
                               WHEN r.parentid IN (119, 3, 64) THEN ltrim(rtrim(r.nimetus))
                               ELSE '' END ::VARCHAR(254)                                    AS hallava_asutus,
                           l.nimetus                                                         AS nimetus,
                           t.nimetus                                                         AS tegev_nimetus,
                           CASE
                               WHEN qry.artikkel IN ('KULUD', 'TULUD') THEN ''
                               ELSE qry.artikkel END::VARCHAR(20)                            AS artikkel,
                           qry.tegev,
                           qry.summa_1,
                           qry.summa_2,
                           qry.summa_3,
                           qry.summa_4
                    FROM eelarve.hallatavate_eelnou($1::DATE, $2::INTEGER, $3::INTEGER) qry
                             LEFT OUTER JOIN ou.rekv r ON r.id = qry.rekv_id
                             LEFT OUTER JOIN ou.rekv p ON p.id = qry.parent_id
                             LEFT OUTER JOIN (SELECT kood, nimetus
                                              FROM libs.library l
                                              WHERE l.library = 'TULUDEALLIKAD'
                                              UNION ALL
                                              SELECT 'KULUD' AS kood, 'KOKKU KULUD' AS nimetus
                                              UNION ALL
                                              SELECT 'TULUD' AS kood, 'KOKKU OMATULUD' AS nimetus
                    ) l
                                             ON l.kood = qry.artikkel
                             LEFT OUTER JOIN libs.library t ON t.kood = qry.tegev AND t.library = 'TEGEV'
                    ORDER BY CASE
                                 WHEN r.id IS NULL THEN 0
                                 WHEN r.id > 9999 THEN 1
                                 WHEN r.id = 63 THEN 10
                                 WHEN r.id = 1190 THEN 100
                                 WHEN r.id = 119 THEN 110
                                 WHEN r.parentid = 119 THEN 120
                                 WHEN r.id = 300 THEN 130
                                 WHEN r.id = 3 OR r.parentid = 3 THEN 140
                                 WHEN r.id = 640 THEN 150
                                 WHEN r.id = 64 THEN 160
                                 WHEN r.parentid = 64 THEN 170
                                 WHEN r.parentid = 63 THEN 200
                                 WHEN r.parentid = 119 THEN 300
                                 ELSE 900 END * 1000, r.nimetus, qry.kas_tulud,
                             CASE
                                 WHEN artikkel = 'KULUD' THEN '0'
                                 WHEN artikkel = 'TULUD' THEN '00'
                                 ELSE qry.artikkel END,
                             CASE WHEN qry.tegev IS NULL THEN '000000' ELSE qry.tegev END`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'hallatavate_eelnou'
    }
};
