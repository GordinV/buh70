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
        sqlString: `SELECT (qryReport.eelarve_kinni)             AS eelarve_kinni,
                           (eelarve_parandatud)                  AS eelarve_parandatud,
                           (eelarve_kassa_kinni)                 AS eelarve_kassa_kinni,
                           (eelarve_kassa_parandatud)            AS eelarve_kassa_parandatud,
                           (tegelik)                             AS tegelik,
                           (kassa)                               AS kassa,
                           rekv_id,
                           tegev,
                           allikas,
                           artikkel,
                           rahavoog,
                           tunnus,
                           proj,
                           uritus,
                           a.nimetus::VARCHAR(254),
                           r.regkood::VARCHAR(20),
                           r.nimetus::VARCHAR(254)               AS asutus,
                           coalesce(p.regkood, '')::VARCHAR(20)  AS parregkood,
                           coalesce(p.nimetus, '')::VARCHAR(254) AS parasutus,
                           idx
                    FROM eelarve.tulude_taitmine_a_art_tt_tunnus_proj_uritus($1::INTEGER, $2::DATE, $3::DATE, $4::INTEGER,
                                                                  $5::INTEGER, $6::JSONB) qryReport
                             LEFT OUTER JOIN (
                        SELECT id, kood, nimetus, rekvid, is_kulud, valid
                        FROM com_artikkel
                        UNION ALL
                        SELECT 152586458                   AS id,
                               '2585(A80)'                 AS kood,
                               'Kohustuste tasumine kokku' AS nimetus,
                               999999                      AS rekvid,
                               TRUE                        AS is_kulud,
                               NULL::DATE                  AS valid
                        UNION ALL
                        SELECT 152586454  AS id,
                               '1,2,3,6'  AS kood,
                               'Tulud'    AS nimetus,
                               999999     AS rekvid,
                               FALSE      AS is_kulud,
                               NULL::DATE AS valid
                        UNION ALL

                        SELECT 152586455            AS id,
                               '3'                  AS kood,
                               'Põhitegevuse tulud' AS nimetus,
                               999999               AS rekvid,
                               FALSE                AS is_kulud,
                               NULL::DATE           AS valid
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
                    WHERE (
                                  eelarve_kinni <> 0
                                  OR eelarve_parandatud <> 0
                                  OR eelarve_kassa_kinni <> 0
                                  OR eelarve_kassa_parandatud <> 0
                                  OR tegelik <> 0
                                  OR kassa <> 0
                              )
        `,     // $1 - aasta $2 - kpv,  $3 - rekvid (svod), $4::integer  1 - kond, 0 - only asutus
        params: '',
        alias: 'tulud_report'
    }
};
