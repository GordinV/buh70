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
        sqlString: `SELECT qryReport.*,
                           r.regkood::VARCHAR(20),
                           r.nimetus::VARCHAR(254)               AS asutus,
                           coalesce(p.regkood, '')::VARCHAR(20)  AS parregkood,
                           coalesce(p.nimetus, '')::VARCHAR(254) AS parasutus
                    FROM eelarve.eelarve_taitmine_art_ta_allikas_proj_tunnus($1::INTEGER, $2::DATE, $3::DATE, $4::INTEGER,
                                                                   $5::INTEGER, $6::JSONB) qryReport
                             LEFT OUTER JOIN (
                        SELECT id, kood, nimetus, rekvid, is_kulud, valid
                        FROM com_artikkel
                        UNION ALL
                        SELECT 152586458                   AS id,
                               '2586(A80)'                 AS kood,
                               'Kohustuste tasumine kokku' AS nimetus,
                               999999                      AS rekvid,
                               TRUE                        AS is_kulud,
                               NULL::DATE                  AS valid
                        UNION ALL
                        SELECT 152586458                        AS id,
                               '2585(A80)'                      AS kood,
                               'Kohustuse võtmine (Allikas 80)' AS nimetus,
                               999999                           AS rekvid,
                               FALSE                            AS is_kulud,
                               NULL::DATE                       AS valid
                        UNION ALL
                        SELECT 152586456       AS id,
                               '15,2586,4,5,6' AS kood,
                               'Kulud'         AS nimetus,
                               999999          AS rekvid,
                               TRUE            AS is_kulud,
                               NULL::DATE      AS valid
                        UNION ALL
                        SELECT 3655000                                   AS id,
                               '15, 3, 655'                              AS kood,
                               'Tulud (siirded eelarvesse, tagastamine)' AS nimetus,
                               999999                                    AS rekvid,
                               FALSE                                     AS is_kulud,
                               NULL::DATE                                AS valid
                    ) a ON ltrim(rtrim(a.kood)) = ltrim(rtrim(qryReport.artikkel))
                             INNER JOIN (SELECT id, parentid, regkood, nimetus
                                         FROM ou.rekv
                                         WHERE parentid < 999
                                         UNION ALL
                                         SELECT 999999, 0, '' AS regkood, 'Kond' AS nimetus) r
                                        ON r.id = qryReport.rekv_id
                             LEFT OUTER JOIN ou.rekv p ON r.parentid = p.id
                    WHERE (qryReport.idx <= (CASE WHEN $4 = 63 AND $5 = 1 THEN 100 ELSE 0 END) OR
                           qryReport.idx >= CASE WHEN $4 = 63 AND $5 = 1 THEN 200 ELSE 0 END)`,     // $1 - aasta $2 - rekvid, $3 - kond
        params: '',
        alias: 'eelarve_taitmine_report'
    }
};
