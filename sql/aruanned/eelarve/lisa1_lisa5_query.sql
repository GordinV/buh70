DROP FUNCTION IF EXISTS eelarve.eelarve_andmik_query(DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.lisa_1_5_query(DATE, INTEGER, INTEGER);
/*
DROP TYPE IF EXISTS EELARVE_ANDMIK_TYPE;
CREATE TYPE EELARVE_ANDMIK_TYPE AS (idx VARCHAR(20), is_e INTEGER, rekvid INTEGER, tegev VARCHAR(20), allikas VARCHAR(20), artikkel VARCHAR(20), nimetus VARCHAR(254), eelarve NUMERIC(14,2), tegelik NUMERIC(14,2), kassa NUMERIC(14,2), saldoandmik NUMERIC(14,2));
*/
CREATE OR REPLACE FUNCTION eelarve.lisa_1_5_query(IN l_kpv DATE,
                                                  IN l_rekvid INTEGER,
                                                  IN l_kond INTEGER)
    RETURNS TABLE (
        idx                TEXT,
        tyyp               INTEGER,
        rekvid             INTEGER,
        tegev              VARCHAR(20),
        allikas            VARCHAR(20),
        artikkel           VARCHAR(20),
        nimetus            VARCHAR(254),
        eelarve            NUMERIC(14, 2),
        eelarve_taps       NUMERIC(14, 2),
        eelarve_kassa      NUMERIC(14, 2),
        eelarve_kassa_taps NUMERIC(14, 2),
        tegelik            NUMERIC(14, 2),
        kassa              NUMERIC(14, 2),
        saldoandmik        NUMERIC(14, 2),
        is_kulud           INTEGER,
        rekv_id            INTEGER
    )
AS
$BODY$
SELECT idx:: TEXT,
       tyyp:: INTEGER,
       rekvid:: INTEGER,
       tegev:: VARCHAR(20),
       allikas:: VARCHAR(20),
       artikkel:: VARCHAR(20),
       nimetus:: VARCHAR(254),
       eelarve:: NUMERIC(14, 2),
       eelarve_taps:: NUMERIC(14, 2),
       eelarve_kassa:: NUMERIC(14, 2),
       eelarve_kassa_taps:: NUMERIC(14, 2),
       tegelik:: NUMERIC(14, 2),
       kassa:: NUMERIC(14, 2),
       saldoandmik:: NUMERIC(14, 2),
       is_kulud:: INTEGER,
       rekvid::INTEGER AS rekv_id
FROM (
         WITH cur_kulude_kassa_taitmine AS (
             SELECT *
             FROM eelarve.uus_kassa_taitmine(make_date(year(l_kpv), 01, 01), l_kpv, l_rekvid, l_kond) q
             WHERE q.artikkel NOT IN ('655')
               AND q.rekv_id <> 9 -- исключить
         ),
              cur_tulude_kassa_taitmine AS (
                  SELECT *
                  FROM eelarve.uus_kassa_tulu_taitmine(make_date(year(l_kpv), 01, 01), l_kpv, l_rekvid, l_kond) q
                  WHERE q.rekv_id <> 9
              ),
              rekv_ids AS (
                  SELECT q.rekv_id
                  FROM get_asutuse_struktuur(l_rekvid) q
                  WHERE q.rekv_id = CASE
                                        WHEN l_kond = 1
                                            -- kond
                                            THEN q.rekv_id
                                        ELSE l_rekvid END
              ),
              docs_types AS (
                  SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood = 'JOURNAL'
              ),
              cur_saldoandmik AS (
                  SELECT rekvid,
                         tegev,
                         konto,
                         sum(-1 * (db - kr)) AS summa
                  FROM eelarve.saldoandmik
                  WHERE aasta = year($1)
                    AND kuu = month($1)
                    AND rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                  GROUP BY rekvid, tegev, konto
              ),
              tmp_report AS (
                  SELECT '2.1'                                                                    AS idx,
                         1                                                                        AS tyyp,
                         qry.rekvid,
                         qry.tegev::VARCHAR(20)                                                   AS tegev,
                         qry.allikas::VARCHAR(20)                                                 AS allikas,
                         qry.artikkel::VARCHAR(20)                                                AS artikkel,
                         l.nimetus::VARCHAR(254),
                         CASE WHEN l.tun5 = 1 THEN 1 ELSE -1 END *
                         sum(qry.eelarve)::NUMERIC(14, 2)                                         AS eelarve,
                         CASE WHEN l.tun5 = 1 THEN 1 ELSE -1 END *
                         sum(qry.eelarve_kassa)::NUMERIC(14, 2)                                   AS eelarve_kassa,
                         CASE WHEN l.tun5 = 1 THEN 1 ELSE -1 END *
                         sum(qry.eelarve + qry.eelarve_taps)::NUMERIC(14, 2)                      AS eelarve_taps,
                         CASE WHEN l.tun5 = 1 THEN 1 ELSE -1 END *
                         sum(qry.eelarve_kassa + qry.eelarve_kassa_taps)::NUMERIC(14, 2)          AS eelarve_kassa_taps,
                         CASE WHEN l.tun5 = 1 THEN 1 ELSE -1 END *
                         sum(qry.tegelik)::NUMERIC(14, 2)                                         AS tegelik,
                         CASE WHEN l.tun5 = 1 THEN 1 ELSE -1 END * sum(qry.kassa)::NUMERIC(14, 2) AS kassa,
                         CASE WHEN l.tun5 = 1 THEN 1 ELSE -1 END *
                         sum(qry.saldoandmik)::NUMERIC(14, 2)                                     AS saldoandmik,
                         CASE WHEN l.tun5 = 1 THEN 0 ELSE 1 END::INTEGER                          AS is_kulud
                  FROM (
                           -- eelarve kinni
                           SELECT e.rekvid,
                                  e.summa       AS eelarve,
                                  e.summa_kassa AS eelarve_kassa,
                                  0             AS eelarve_taps,
                                  0             AS eelarve_kassa_taps,
                                  0 :: NUMERIC  AS tegelik,
                                  0 :: NUMERIC  AS kassa,
                                  0 :: NUMERIC  AS saldoandmik,
                                  e.kood1       AS tegev,
                                  e.kood2       AS allikas,
                                  e.kood5       AS artikkel
                           FROM eelarve.eelarve e
                           WHERE e.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
--               AND e.rekvid <> 9
                             AND e.aasta = year($1)
                             AND (e.kpv IS NULL) --  OR e.kpv <= $1
                             AND e.status <> 3
                           UNION ALL
                           -- eelarve taps
                           SELECT e.rekvid,
                                  0             AS eelarve,
                                  0             AS eelarve_kassa,
                                  e.summa       AS eelarve_taps,
                                  e.summa_kassa AS eelarve_kassa_taps,
                                  0 :: NUMERIC  AS tegelik,
                                  0 :: NUMERIC  AS kassa,
                                  0 :: NUMERIC  AS saldoandmik,
                                  e.kood1       AS tegev,
                                  e.kood2       AS allikas,
                                  e.kood5       AS artikkel
                           FROM eelarve.eelarve e
                           WHERE e.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
--               AND e.rekvid <> 9
                             AND e.aasta = year($1)
                             AND (e.kpv IS NOT NULL AND e.kpv <= l_kpv)
                             AND e.status <> 3
                           UNION ALL
                           SELECT ft.rekvid,
                                  0 :: NUMERIC              AS eelarve,
                                  0 :: NUMERIC              AS eelarve_kassa,
                                  0 :: NUMERIC              AS eelarve_taps,
                                  0 :: NUMERIC              AS eelarve_kassa_taps,
                                  ft.summa                  AS tegelik,
                                  0 :: NUMERIC              AS kassa,
                                  0 :: NUMERIC              AS saldoandmik,
                                  COALESCE(ft.tegev, '')    AS tegev,
                                  COALESCE(ft.allikas, '')  AS allikas,
                                  COALESCE(ft.artikkel, '') AS artikkel
                           FROM cur_kulude_taitmine ft
                           WHERE ft.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
--               AND ft.rekvid <> 9
                             AND ft.kuu <= MONTH(l_kpv)
                             AND ft.aasta = year(l_kpv)
                             AND ft.artikkel IS NOT NULL
                             AND NOT empty(ft.artikkel)
                           UNION ALL
                           SELECT tt.rekvid,
                                  0 :: NUMERIC              AS eelarve,
                                  0 :: NUMERIC              AS eelarve_kassa,
                                  0 :: NUMERIC              AS eelarve_taps,
                                  0 :: NUMERIC              AS eelarve_kassa_taps,
                                  tt.summa                  AS tegelik,
                                  0 :: NUMERIC              AS kassa,
                                  0 :: NUMERIC              AS saldoandmik,
                                  COALESCE(tt.tegev, '')    AS tegev,
                                  COALESCE(tt.allikas, '')  AS allikas,
                                  COALESCE(tt.artikkel, '') AS artikkel
                           FROM cur_tulude_taitmine tt
                           WHERE tt.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
--               AND tt.rekvid <> 9
                             AND tt.kuu <= MONTH(l_kpv)
                             AND tt.aasta = year(l_kpv)
                             AND tt.artikkel IS NOT NULL
                             AND NOT empty(tt.artikkel)
                           UNION ALL
                           SELECT kt.rekv_id   AS rekvid,
                                  0 :: NUMERIC AS eelarve,
                                  0 :: NUMERIC AS eelarve_kassa,
                                  0 :: NUMERIC AS eelarve_taps,
                                  0 :: NUMERIC AS eelarve_kassa_taps,
                                  0 :: NUMERIC AS tegelik,
                                  kt.summa     AS kassa,
                                  0 :: NUMERIC AS saldoandmik,
                                  kt.tegev,
                                  kt.allikas,
                                  kt.artikkel
                           FROM cur_kulude_kassa_taitmine kt
                           WHERE kt.artikkel IS NOT NULL
                             AND NOT empty(kt.artikkel)
                           UNION ALL
                           SELECT kt.rekv_id   AS rekvid,
                                  0 :: NUMERIC AS eelarve,
                                  0 :: NUMERIC AS eelarve_kassa,
                                  0 :: NUMERIC AS eelarve_taps,
                                  0 :: NUMERIC AS eelarve_kassa_taps,
                                  0 :: NUMERIC AS tegelik,
                                  kt.summa     AS kassa,
                                  0 :: NUMERIC AS saldoandmik,
                                  kt.tegev,
                                  kt.allikas,
                                  kt.artikkel
                           FROM cur_tulude_kassa_taitmine kt
                           WHERE kt.artikkel IS NOT NULL
                             AND NOT empty(kt.artikkel)
                           UNION ALL
                           -- kassatulud (art.jargi) miinus
                           SELECT kassakulu.rekvid,
                                  0::NUMERIC             AS eelarve,
                                  0::NUMERIC             AS eelarve_kassa,
                                  0 :: NUMERIC           AS eelarve_taps,
                                  0 :: NUMERIC           AS eelarve_kassa_taps,
                                  0::NUMERIC             AS tegelik,
                                  -1 * (kassakulu.summa) AS kassa,
                                  0 :: NUMERIC           AS saldoandmik,
                                  kassakulu.tegev::VARCHAR(20),
                                  kassakulu.allikas::VARCHAR(20),
                                  kassakulu.artikkel::VARCHAR(20)
                           FROM (
                                    SELECT j.rekvid,
                                           sum(j1.summa) AS summa,
                                           j1.kood1      AS tegev,
                                           j1.kood2      AS allikas,
                                           j1.kood5      AS artikkel
                                    FROM docs.doc d
                                             INNER JOIN docs.journal j ON j.parentid = d.id
                                             INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                             JOIN eelarve.kassa_kulud kk
                                                  ON j1.deebet::TEXT ~~ kk.kood::TEXT
                                             JOIN eelarve.kassa_kontod kassa
                                                  ON j1.kreedit::TEXT ~~ kassa.kood::TEXT
                                    WHERE d.status < 3
                                      AND j.kpv <= $1
                                      AND YEAR(j.kpv) = YEAR(l_kpv)
                                      AND j.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                                      AND d.doc_type_id IN (SELECT * FROM docs_types)
--                        AND j.rekvid <> 9
                                      AND j1.kood5 IS NOT NULL
                                      AND NOT empty(j1.kood5)
                                      AND j1.kood5 IN
                                          (SELECT kood
                                           FROM libs.library
                                           WHERE library.library = 'TULUDEALLIKAD'
                                             AND tun5 = 1
                                             AND status <> 3)
                                    GROUP BY j.rekvid
                                            , j1.kood1
                                            , j1.kood2
                                            , j1.kood5
                                ) kassakulu
                           WHERE kassakulu.artikkel <> '655'
                           UNION ALL

                           -- kassatulud (art.jargi), kulud
                           -- 3500, 352
                           SELECT kassatulu.rekvid,
                                  0::NUMERIC        AS eelarve,
                                  0::NUMERIC        AS eelarve_kassa,
                                  0 :: NUMERIC      AS eelarve_taps,
                                  0 :: NUMERIC      AS eelarve_kassa_taps,
                                  0::NUMERIC        AS tegelik,
                                  (kassatulu.summa) AS kassa,
                                  0 :: NUMERIC      AS saldoandmik,
                                  kassatulu.tegev::VARCHAR(20),
                                  kassatulu.allikas::VARCHAR(20),
                                  kassatulu.artikkel::VARCHAR(20)
                           FROM (
                                    SELECT j.rekvid,
                                           sum(j1.summa) AS summa,
                                           j1.kood1      AS tegev,
                                           j1.kood2      AS allikas,
                                           j1.kood5      AS artikkel
                                    FROM docs.doc d
                                             INNER JOIN docs.journal j ON j.parentid = d.id
                                             INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                    WHERE j.kpv <= $1
                                      AND YEAR(j.kpv) = YEAR($1)
                                      AND j.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                                      AND d.doc_type_id IN (SELECT * FROM docs_types)
--                        AND j.rekvid <> 9
                                      AND j1.kood5 IS NOT NULL
                                      AND NOT empty(j1.kood5)
                                      AND j1.deebet LIKE '100%'
                                      AND kreedit LIKE '700000%'
                                      AND j1.kood5 IN ('3500', '352')
                                    GROUP BY j.rekvid
                                            , j1.kood1
                                            , j1.kood2
                                            , j1.kood5
                                ) kassatulu
                           UNION ALL
                           -- возврат кассовых доходов
                           SELECT kassakulu.rekvid,
                                  0::NUMERIC        AS eelarve,
                                  0::NUMERIC        AS eelarve_kassa,
                                  0 :: NUMERIC      AS eelarve_taps,
                                  0 :: NUMERIC      AS eelarve_kassa_taps,
                                  0::NUMERIC        AS tegelik,
                                  (kassakulu.summa) AS kassa,
                                  0 :: NUMERIC      AS saldoandmik,
                                  kassakulu.tegev::VARCHAR(20),
                                  kassakulu.allikas::VARCHAR(20),
                                  kassakulu.artikkel::VARCHAR(20)
                           FROM (
                                    SELECT j.rekvid,
                                           sum(- 1 * j1.summa) AS summa,
                                           j1.kood1            AS tegev,
                                           j1.kood2            AS allikas,
                                           j1.kood5            AS artikkel
                                    FROM docs.doc d
                                             INNER JOIN docs.journal j ON j.parentid = d.id
                                             INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                                    WHERE d.status < 3
                                      AND j.kpv <= $1
                                      AND YEAR(j.kpv) = YEAR($1)
                                      AND j.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                                      AND d.doc_type_id IN (SELECT * FROM docs_types)
--                        AND j.rekvid <> 9
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
                                            , j1.kood5
                                ) kassakulu
                           UNION ALL
                           SELECT kt.rekvid    AS rekvid,
                                  0 :: NUMERIC AS eelarve,
                                  0 :: NUMERIC AS eelarve_kassa,
                                  0 :: NUMERIC AS eelarve_taps,
                                  0 :: NUMERIC AS eelarve_kassa_taps,
                                  0 :: NUMERIC AS tegelik,
                                  0            AS kassa,
                                  (summa)      AS saldoandmik,
                                  kt.tegev,
                                  ''           AS allikas,
                                  kt.konto     AS artikkel
                           FROM cur_saldoandmik kt
                       ) qry
                           LEFT OUTER JOIN libs.library l ON l.kood = qry.artikkel
                      AND l.library = 'TULUDEALLIKAD'
                      AND l.status <> 3
                  GROUP BY qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, l.nimetus, l.tun5)
         SELECT *
         FROM tmp_report) qry;


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;



GRANT EXECUTE ON FUNCTION eelarve.lisa_1_5_query(DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.lisa_1_5_query(DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.lisa_1_5_query(DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.lisa_1_5_query(DATE, INTEGER, INTEGER ) TO dbvaatleja;

/*
select * from (
    SELECT * from eelarve.lisa_1_5_query(DATE(2023, 06, 30), 119, 1)
    ) qry
where artikkel like  '35%'


*/

