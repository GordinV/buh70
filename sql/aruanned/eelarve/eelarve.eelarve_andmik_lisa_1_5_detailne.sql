DROP FUNCTION IF EXISTS eelarve.eelarve_andmik_lisa_1_5_detailne(DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.eelarve_andmik_lisa_1_5_detailne_(DATE, INTEGER, INTEGER);



CREATE OR REPLACE FUNCTION eelarve.eelarve_andmik_lisa_1_5_detailne(IN l_kpv DATE,
                                                                    IN l_rekvid INTEGER,
                                                                    IN l_kond INTEGER)
    RETURNS TABLE (
        idx      VARCHAR(20),
        rekvid   INTEGER,
        allikas  VARCHAR(20),
        artikkel VARCHAR(20),
        nimetus  VARCHAR(254),
        kassa    NUMERIC(14, 2),
        tegevus  VARCHAR(20),
        tunnus   VARCHAR(20)
    )
AS
$$

BEGIN
    -- data analise
    RETURN QUERY
        WITH params AS (
            SELECT l_rekvid AS rekvid, l_kpv AS kpv, l_kond AS kond
        ),
             rekv_ids AS (
                 SELECT rekv_id
                 FROM params,
                      get_asutuse_struktuur(params.rekvid) a
                 WHERE a.rekv_id = CASE
                                       WHEN params.kond = 1
                                           -- kond
                                           THEN a.rekv_id
                                       ELSE params.rekvid END
             ),
-- признаки, В отчете Eelarvesse ülekantavad tulud Tunnus-ы должны быть только те, которые есть в Taotlused запрашиваемого в отчете периода.
             qryTunnused AS (SELECT DISTINCT t.rekvid, t1.tunnus
                             FROM eelarve.taotlus t
                                      INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
                                  params
                             WHERE t1.tunnus IS NOT NULL
                               AND NOT empty(t1.tunnus)
                               AND t.status IN (3)
                               AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                               AND t.aasta = YEAR(params.kpv)
             ),

             tmp_andmik AS (
                 SELECT qry.idx,
                        qry.rekvid,
                        sum(qry.kassa)  AS kassa,
                        qry.allikas,
                        qry.artikkel,
                        qry.nimetus,
                        qry.tegev,
                        CASE
                            WHEN EXISTS(
                                    SELECT 1 FROM qryTunnused t WHERE t.tunnus = qry.tunnus AND t.rekvid = qry.rekvid)
                                THEN qry.tunnus
                            ELSE '' END AS tunnus
                 FROM (
                          SELECT '2.1'     AS idx,
                                 q.rekv_id AS rekvid,
                                 q.summa   AS kassa,
                                 q.allikas,
                                 q.artikkel,
                                 a.nimetus,
                                 q.tegev,
                                 q.tunnus
                          FROM params,
                               eelarve.uus_kassa_tulu_taitmine(make_date(year(params.kpv), 01, 01), params.kpv,
                                                               params.rekvid,
                                                               params.kond) q
                                   LEFT OUTER JOIN libs.library a ON a.kood = q.artikkel
                                   AND a.library = 'TULUDEALLIKAD'
                                   AND a.status <> 3
                          WHERE q.rekv_id <> 9 -- исключить
                            AND q.artikkel NOT IN
                                ('3000', '3500', '352', '35200', '35201', '38250', '38254', '3882', '3500')
                          UNION ALL
                          -- возврат кассовых доходов
                          SELECT '2.1'   AS idx,
                                 kassakulu.rekvid,
                                 (summa) AS kassa,
                                 kassakulu.allikas::VARCHAR(20),
                                 kassakulu.artikkel::VARCHAR(20),
                                 a.nimetus,
                                 tegev,
                                 kassakulu.tunnus
                          FROM (
                                   SELECT j.rekvid,
                                          sum(- 1 * j1.summa) AS summa,
                                          j1.kood2            AS allikas,
                                          j1.kood5            AS artikkel,
                                          j1.kood1            AS tegev,
                                          j1.tunnus
                                   FROM docs.doc d
                                            INNER JOIN docs.journal j ON j.parentid = d.id
                                            INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                                        params
                                   WHERE d.status < 3
                                     AND j.kpv <= params.kpv
                                     AND YEAR(j.kpv) = YEAR(params.kpv)
                                     AND j.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                                     AND j1.kood5 IS NOT NULL
                                     AND NOT empty(j1.kood5)
                                     AND left(j1.kreedit, 3) IN ('100', '999')
                                     AND ltrim(rtrim(j1.deebet)) = '710001'
                                     AND j1.kood5 IN
                                         (SELECT kood
                                          FROM libs.library
                                          WHERE library.library = 'TULUDEALLIKAD'
                                            AND tun5 = 1
                                            AND status <> 3
                                            AND (kood LIKE '3%' OR kood LIKE '655%' OR kood = '1532')
                                         )
                                   GROUP BY j.rekvid
                                           , j1.kood1
                                           , j1.kood2
                                           , j1.kood5,
                                            j1.tunnus
                               ) kassakulu
                                   LEFT OUTER JOIN libs.library a ON a.kood = kassakulu.artikkel
                              AND a.library = 'TULUDEALLIKAD'
                              AND a.status <> 3
                      ) qry
                 WHERE qry.artikkel NOT IN
                       ('3000', '3030', '3500', '352', '35200', '35201', '38250', '38254', '3882', '3500')
                 GROUP BY qry.idx, qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, qry.nimetus, qry.tunnus
             ),
             tmp_report AS (
                 SELECT qry.idx::VARCHAR(20),
                        qry.rekvid::INTEGER,
                        ltrim(rtrim(qry.allikas))::VARCHAR(20)  AS allikas,
                        ltrim(rtrim(qry.artikkel))::VARCHAR(20) AS artikkel,
                        ltrim(rtrim(qry.nimetus))::VARCHAR(254) AS nimetus,
                        sum(qry.kassa)                          AS kassa,
                        ltrim(rtrim(qry.tegev))::VARCHAR(20)    AS tegev,
                        ltrim(rtrim(qry.tunnus)) ::VARCHAR(20)  AS tunnus
                 FROM (
                          SELECT '2.1'::VARCHAR(20)                                     AS idx,
                                 999                                               AS rekvid,
                                 q.allikas::VARCHAR(20)                                 AS allikas,
                                 '32'::VARCHAR(20)                                      AS artikkel,
                                 'Tulud kaupade ja teenuste müügist'::VARCHAR(254)      AS nimetus,
                                 COALESCE(COALESCE(sum(q.kassa), 0), 0)::NUMERIC(12, 2) AS kassa,
                                 ''::VARCHAR(20)                                        AS tegev,
                                 ''::VARCHAR(20)                                        AS tunnus
                          FROM tmp_andmik q
                          WHERE q.artikkel LIKE '32%'
                          GROUP BY q.allikas, q.tegev, q.tunnus
                          UNION ALL
                          SELECT '2.1'::VARCHAR(20)                                     AS idx,
                                 q.rekvid                                               AS rekvid,
                                 q.allikas::VARCHAR(20)                                 AS allikas,
                                 '320'::VARCHAR(20)                                     AS artikkel,
                                 'Riigilõivud'::VARCHAR(254)                            AS nimetus,
                                 COALESCE(COALESCE(sum(q.kassa), 0), 0)::NUMERIC(12, 2) AS kassa,
                                 q.tegev::VARCHAR(20)                                   AS tegev,
                                 q.tunnus::VARCHAR(20)                                  AS tunnus
                          FROM tmp_andmik q
                          WHERE q.artikkel LIKE '320%'
                          GROUP BY q.allikas, q.tegev, q.tunnus, q.rekvid
                          UNION ALL
                          SELECT '2.1'::VARCHAR(20),
                                 q.rekvid                  AS rekvid,
                                 q.allikas::VARCHAR(20)    AS allikas,
                                 '382'::VARCHAR(20)        AS artikkel,
                                 'Muud tulud varadelt'     AS nimetus,
                                 COALESCE(sum(q.kassa), 0) AS kassa,
                                 q.tegev::VARCHAR(20)      AS tegev,
                                 q.tunnus::VARCHAR(20)     AS tunnus
                          FROM tmp_andmik q
                          WHERE q.artikkel LIKE '382%'
                            AND q.artikkel NOT IN ('38250', '38251', '38252', '38254')
                          GROUP BY q.allikas, q.tegev, q.tunnus, q.rekvid
                          UNION ALL
                          SELECT '2.4'::VARCHAR(20),
                                 q.rekvid                  AS rekvid,
                                 q.allikas::VARCHAR(20)    AS allikas,
                                 '381'::VARCHAR(20)        AS artikkel,
                                 'Põhivara müük (+)'       AS nimetus,
                                 COALESCE(sum(q.kassa), 0) AS kassa,
                                 q.tegev::VARCHAR(20)      AS tegev,
                                 q.tunnus::VARCHAR(20)     AS tunnus
                          FROM tmp_andmik q
                          WHERE q.artikkel LIKE '381%'
                            AND q.artikkel <> '3818'
                          GROUP BY q.allikas, q.tegev, q.tunnus, q.rekvid
                          UNION ALL
                          SELECT q.idx,
                                 q.rekvid                  AS rekvid,
                                 q.allikas::VARCHAR(20)    AS allikas,
                                 q.artikkel::VARCHAR(20)   AS artikkel,
                                 q.nimetus                 AS nimetus,
                                 COALESCE(sum(q.kassa), 0) AS kassa,
                                 q.tegev::VARCHAR(20)      AS tegev,
                                 q.tunnus::VARCHAR(20)     AS tunnus
                          FROM tmp_andmik q
                          WHERE q.artikkel = '3818'
                          GROUP BY q.idx, q.artikkel, q.nimetus, q.rekvid, q.allikas, q.tegev, q.tunnus
                          UNION ALL
                          SELECT '2.4.2'::VARCHAR(20),
                                 q.rekvid                  AS rekvid,
                                 ''::VARCHAR(20)           AS allikas,
                                 '1502'::VARCHAR(20)       AS artikkel,
                                 'Osaluste müük (+)'       AS nimetus,
                                 COALESCE(sum(q.kassa), 0) AS kassa,
                                 q.tegev::VARCHAR(20)      AS tegev,
                                 q.tunnus::VARCHAR(20)     AS tunnus
                          FROM tmp_andmik q
                          WHERE q.artikkel LIKE '1502%'
                          GROUP BY q.rekvid, q.tegev, q.tunnus
                          UNION ALL
                          SELECT '2.4.3',
                                 q.rekvid                           AS rekvid,
                                 ''::VARCHAR(20)                    AS allikas,
                                 '1512'::VARCHAR(20)                AS artikkel,
                                 'Muude aktsiate ja osade müük (+)' AS nimetus,
                                 COALESCE(sum(q.kassa), 0)          AS kassa,
                                 q.tegev::VARCHAR(20)               AS tegev,
                                 q.tunnus::VARCHAR(20)              AS tunnus
                          FROM tmp_andmik q
                          WHERE q.artikkel LIKE '1512%'
                          GROUP BY q.rekvid, q.tegev, q.tunnus
                          UNION ALL
                          SELECT '3.1',
                                 q.rekvid                    AS rekvid,
                                 ''::VARCHAR(20)             AS allikas,
                                 '1532'::VARCHAR(20)         AS artikkel,
                                 'Tagasilaekuvad laenud (+)' AS nimetus,
                                 COALESCE(sum(q.kassa), 0)   AS kassa,
                                 q.tegev::VARCHAR(20)        AS tegev,
                                 q.tunnus::VARCHAR(20)       AS tunnus
                          FROM tmp_andmik q
                          WHERE LEFT(q.artikkel, 4) IN ('1032', '1532')
                          GROUP BY q.rekvid, q.tegev, q.tunnus
                          UNION ALL
                          SELECT '2.4.5',
                                 q.rekvid                  AS rekvid,
                                 ''::VARCHAR(20)           AS allikas,
                                 '655'::VARCHAR(20)        AS artikkel,
                                 'Finantstulud (+)'        AS nimetus,
                                 COALESCE(sum(q.kassa), 0) AS kassa,
                                 q.tegev::VARCHAR(20)      AS tegev,
                                 q.tunnus::VARCHAR(20)     AS tunnus
                          FROM tmp_andmik q
                          WHERE q.artikkel LIKE '655%'
                          GROUP BY q.rekvid, q.tegev, q.tunnus
                          UNION ALL
                          SELECT '8.2',
                                 q.rekvid            AS rekvid,
                                 ''::VARCHAR(20)     AS allikas,
                                 '9101'::VARCHAR(20) AS artikkel,
                                 'Sildfinantseering' AS nimetus,
                                 -1 * q.summa        AS kassa,
                                 ''::VARCHAR(20)     AS tegev,
                                 ''::VARCHAR(20)     AS tunnus

                          FROM (SELECT sum(kr - db) AS summa,
                                       S.rekvid
                                FROM eelarve.saldoandmik S
                                WHERE S.konto LIKE '910090%'
                                  AND S.aasta = YEAR(l_kpv)
                                  AND S.kuu = MONTH(l_kpv)
                                  AND S.rekvid IN (SELECT rekv_id FROM rekv_ids r)
                                GROUP BY S.rekvid) q
                          UNION ALL
                          SELECT q.idx,
                                 q.rekvid                  AS rekvid,
                                 q.allikas::VARCHAR(20)    AS allikas,
                                 q.artikkel,
                                 q.nimetus,
                                 COALESCE(sum(q.kassa), 0) AS kassa,
                                 q.tegev::VARCHAR(20)      AS tegev,
                                 q.tunnus::VARCHAR(20)     AS tunnus
                          FROM tmp_andmik q
                          WHERE LEFT(q.artikkel, 2) NOT IN ('15', '40', '50', '55', '60', '91')
                            AND LEFT(q.artikkel, 4) NOT IN (
                                                            '3200',
                                                            '3201',
                                                            '3203',
                                                            '3209',
                                                            '3501',
                                                            '3502',
                                                            '3823',
                                                            '2585',
                                                            '2586',
                                                            '1001',
                                                            '4500',
                                                            '4502')
                            AND LEFT(q.artikkel, 3) NOT IN ('655', '650', '352', '381', '413', '452', '910', '320')
                            AND TRIM(q.artikkel) NOT IN ('382', '100')
                          GROUP BY q.idx,
                                   q.artikkel,
                                   q.nimetus,
                                   q.rekvid,
                                   q.allikas,
                                   q.tegev,
                                   q.tunnus
                      ) qry
                 WHERE qry.artikkel NOT IN ('3500.00', '3209')
                 GROUP BY qry.idx, qry.rekvid, ltrim(rtrim(qry.allikas)), ltrim(rtrim(qry.artikkel)),
                          ltrim(rtrim(qry.nimetus)), ltrim(rtrim(qry.tegev)), ltrim(rtrim(qry.tunnus))
             ) -- VB, нет необходимости
        SELECT *
        FROM tmp_report r
        WHERE r.artikkel NOT IN ('6580')
        ORDER BY r.idx, r.allikas, r.artikkel, tegev, tunnus, CASE WHEN r.rekvid = 63 THEN 0 ELSE 1 END;
END ;
$$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5_detailne(DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5_detailne(DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5_detailne(DATE, INTEGER, INTEGER ) TO dbvaatleja;


/*SELECT len(tegevus), len(tunnus), *
FROM eelarve.eelarve_andmik_lisa_1_5_detailne(DATE(2023, 05, 31), 119, 1) qry
WHERE tunnus LIKE '%0951002%'
*/

/*WHERE allikas = '80'
  AND artikkel = '3044'
*/
/*
SELECT *
FROM (
         SELECT *
         FROM eelarve.eelarve_andmik_lisa_1_5_detailne(DATE(2023,12, 31),63, 1) qry
--         where artikkel like '382%'
        where tegev is not null and tegev = '01114'
     ) qry

 */