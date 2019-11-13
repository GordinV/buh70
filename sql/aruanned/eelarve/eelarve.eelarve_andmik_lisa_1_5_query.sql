DROP FUNCTION IF EXISTS eelarve.eelarve_andmik_query(DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.eelarve_andmik_lisa_1_5_query(DATE, INTEGER, INTEGER);
/*
DROP TYPE IF EXISTS EELARVE_ANDMIK_TYPE;
CREATE TYPE EELARVE_ANDMIK_TYPE AS (idx VARCHAR(20), is_e INTEGER, rekvid INTEGER, tegev VARCHAR(20), allikas VARCHAR(20), artikkel VARCHAR(20), nimetus VARCHAR(254), eelarve NUMERIC(14,2), tegelik NUMERIC(14,2), kassa NUMERIC(14,2), saldoandmik NUMERIC(14,2));
*/
CREATE OR REPLACE FUNCTION eelarve.eelarve_andmik_lisa_1_5_query(IN l_kpv DATE,
                                                                 IN l_rekvid INTEGER,
                                                                 IN l_kond INTEGER)
    RETURNS BOOLEAN
AS
$$
DECLARE
    l_count INTEGER = 0;
BEGIN


   DROP TABLE IF EXISTS tmp_andmik;

    CREATE TEMPORARY TABLE tmp_andmik (
        idx         TEXT,
        tyyp        INTEGER,
        rekvid      INTEGER,
        tegev       VARCHAR(20),
        allikas     VARCHAR(20),
        artikkel    VARCHAR(20),
        rahavoog    VARCHAR(20),
        nimetus     VARCHAR(254),
        eelarve     NUMERIC(14, 2),
        tegelik     NUMERIC(14, 2),
        kassa       NUMERIC(14, 2),
        saldoandmik NUMERIC(14, 2),
        db          NUMERIC(14, 2),
        kr          NUMERIC(14, 2),
        aasta       INTEGER,
        kuu         INTEGER,
        is_kulud    INTEGER DEFAULT 0
    );

/*
  CREATE INDEX tyyp_tmp_andmik
    ON tmp_andmik
      USING btree
      (tyyp);


  CREATE INDEX artikkel_tmp_andmik
    ON tmp_andmik
      USING btree
      (artikkel);


  CREATE INDEX rahavoog_tmp_andmik
    ON tmp_andmik
      USING btree
      (rahavoog);

*/
    INSERT INTO tmp_andmik (idx, tyyp, rekvid, tegev, allikas, artikkel, nimetus, eelarve, tegelik, kassa, aasta, kuu,
                            is_kulud)
    SELECT '2.1'                                           AS idx,
           1                                               AS tyyp,
           qry.rekvid,
           qry.tegev::VARCHAR(20)                          AS tegev,
           qry.allikas::VARCHAR(20)                        AS allikas,
           qry.artikkel::VARCHAR(20)                       AS artikkel,
           l.nimetus::VARCHAR(254),
           sum(qry.eelarve)::NUMERIC(14, 2)                AS eelarve,
           sum(qry.tegelik)::NUMERIC(14, 2)                AS tegelik,
           sum(qry.kassa)::NUMERIC(14, 2)                  AS kassa,
           year(l_kpv)                                     AS aasta,
           month(l_kpv),
           CASE WHEN l.tun5 = 1 THEN 0 ELSE 1 END::INTEGER AS is_kulud
    FROM (
             SELECT e.rekvid,
                    e.summa        AS eelarve,
                    0 :: NUMERIC AS tegelik,
                    0 :: NUMERIC AS kassa,
                    e.kood1        AS tegev,
                    e.kood2        AS allikas,
                    e.kood5        AS artikkel
             FROM eelarve.eelarve e
             WHERE rekvid = (CASE
                                 WHEN $3 = 1
                                     THEN rekvid
                                 ELSE $2 END)
               AND e.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur($2))
               AND aasta = year($1)
               AND (e.kpv IS NULL OR e.kpv <= $1)
             UNION ALL
             SELECT rekvid,
                    0 :: NUMERIC              AS eelarve,
                    summa                     AS tegelik,
                    0 :: NUMERIC              AS kassa,
                    COALESCE(ft.tegev, '')    AS tegev,
                    COALESCE(ft.allikas, '')  AS allikas,
                    COALESCE(ft.artikkel, '') AS artikkel
             FROM cur_kulude_taitmine ft
             WHERE ft.rekvid = (CASE
                                    WHEN $3 = 1
                                        THEN rekvid
                                    ELSE $2 END)
               AND ft.rekvid IN (SELECT rekv_id
                                 FROM get_asutuse_struktuur($2))
               AND ft.kuu <= MONTH($1)
               AND ft.aasta = year($1)
               AND ft.artikkel IS NOT NULL
               AND NOT empty(ft.artikkel)
             UNION ALL
             SELECT rekvid,
                    0 :: NUMERIC              AS eelarve,
                    summa                     AS tegelik,
                    0 :: NUMERIC              AS kassa,
                    COALESCE(tt.tegev, '')    AS tegev,
                    COALESCE(tt.allikas, '')  AS allikas,
                    COALESCE(tt.artikkel, '') AS artikkel
             FROM cur_tulude_taitmine tt
             WHERE tt.rekvid = (CASE
                                    WHEN $3 = 1
                                        THEN rekvid
                                    ELSE $2 END)
               AND tt.rekvid IN (SELECT rekv_id
                                 FROM get_asutuse_struktuur($2))
               AND tt.kuu <= MONTH($1)
               AND tt.aasta = year($1)
               AND tt.artikkel IS NOT NULL
               AND NOT empty(tt.artikkel)
             UNION ALL
             SELECT rekvid,
                    0 :: NUMERIC AS eelarve,
                    0 :: NUMERIC AS tegelik,
                    summa        AS kassa,
                    tegev,
                    allikas,
                    artikkel
             FROM cur_kulude_kassa_taitmine kt
             WHERE kt.rekvid = (CASE
                                    WHEN $3 = 1
                                        THEN rekvid
                                    ELSE $2 END)

               AND kt.rekvid IN (SELECT rekv_id
                                 FROM get_asutuse_struktuur($2))
               AND kt.aasta = year($1)
               AND kt.kuu <= MONTH($1)
               AND kt.artikkel IS NOT NULL
               AND NOT empty(kt.artikkel)
             UNION ALL
             SELECT rekvid,
                    0 :: NUMERIC AS eelarve,
                    0 :: NUMERIC AS tegelik,
                    summa        AS kassa,
                    tegev,
                    allikas,
                    artikkel
             FROM (
                      SELECT j.rekvid,
                             sum(j1.summa) AS summa,
                             j1.kood5      AS artikkel,
                             j1.kood1      AS tegev,
                             j1.kood2      AS allikas
                      FROM docs.doc d
                               INNER JOIN docs.journal j ON d.id = j.parentid
                               JOIN docs.journal1 j1 ON j1.parentid = j.id
                               JOIN eelarve.kassa_tulud kt
                                    ON j1.kreedit::TEXT ~~ kt.kood::TEXT
                               JOIN eelarve.kassa_kontod kk
                                    ON j1.deebet::TEXT ~~ kk.kood::TEXT
                      WHERE d.status < 3
                        AND j.rekvid = (CASE
                                            WHEN $3 = 1
                                                THEN j.rekvid
                                            ELSE $2 END)

                        AND j.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur($2))
                        AND year(j.kpv) = year($1)
                        AND J.KPV <= $1
                        AND j1.kood5 IN
                            (SELECT kood FROM libs.library WHERE library.library = 'TULUDEALLIKAD' AND tun5 = 1)
                      GROUP BY j.rekvid, j1.kood5, j1.kood1, j1.kood2
                  ) tt
             WHERE tt.artikkel IS NOT NULL
               AND NOT empty(tt.artikkel)

             UNION ALL

             -- kassatulud (art.jargi) miinus
             SELECT kassakulu.rekvid,
                    0::NUMERIC   AS eelarve,
                    0::NUMERIC   AS tegelik,
                    -1 * (summa) AS kassa,
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
                        AND YEAR(j.kpv) = YEAR($1)
                        AND j.rekvid = (CASE
                                            WHEN $3 = 1
                                                THEN j.rekvid
                                            ELSE $2 END)
                        AND j.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur($2))
                        AND j1.kood5 IS NOT NULL
                        AND NOT empty(j1.kood5)
                        AND j1.kood5 IN
                            (SELECT kood FROM library WHERE library.library = 'TULUDEALLIKAD' AND tun5 = 1)
                      GROUP BY j.rekvid, j1.kood1, j1.kood2, j1.kood5
                  ) kassakulu
             UNION ALL

             -- kassatulud (art.jargi), kulud
             SELECT kassatulu.rekvid,
                    0::NUMERIC   AS eelarve,
                    0::NUMERIC   AS tegelik,
                    -1 * (summa) AS kassa,
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
                               JOIN eelarve.kassa_tulud kassatulud
                                    ON j1.kreedit::TEXT ~~ kassatulud.kood::TEXT
                               JOIN eelarve.kassa_kontod kassakontod
                                    ON j1.deebet::TEXT ~~ kassakontod.kood::TEXT
                      WHERE j.kpv <= $1
                        AND YEAR(j.kpv) = YEAR($1)
                        AND j.rekvid = (CASE
                                            WHEN $3 = 1
                                                THEN j.rekvid
                                            ELSE $2 END)
                        AND j.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur($2))
                        AND j1.kood5 IS NOT NULL
                        AND NOT empty(j1.kood5)
                        AND j1.kood5 IN
                            (SELECT kood FROM libs.library WHERE library.library = 'TULUDEALLIKAD' AND tun5 = 2)
                      GROUP BY j.rekvid, j1.kood1, j1.kood2, j1.kood5
                  ) kassatulu
         ) qry
             LEFT OUTER JOIN libs.library l ON l.
                                                   kood = qry.artikkel AND l.library = 'TULUDEALLIKAD'
    GROUP BY qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, l.nimetus, l.tun5;

    INSERT INTO tmp_andmik (idx, tyyp, rekvid, tegev, artikkel, rahavoog, nimetus, saldoandmik, db, kr, aasta, kuu)
    SELECT 2,
           2,
           (CASE
                WHEN $3 = 1
                    THEN 999
                ELSE $2 END),
           tegev,
           konto,
           rahavoo,
           nimetus,
           sum(CASE WHEN db = 0 THEN (kr - db) ELSE (db - kr) END),
           sum(db),
           sum(kr),
           year($1),
           month($1)
    FROM eelarve.saldoandmik
    WHERE aasta = year($1)
      AND kuu = month($1)
      AND rekvid = (CASE
                        WHEN $3 = 1
                            THEN 999
                        ELSE $2 END)
    GROUP BY tegev, konto, rahavoo, nimetus;

    GET DIAGNOSTICS l_count= ROW_COUNT;

    -- eelmise periodi andmed
    INSERT INTO tmp_andmik (idx, tyyp, rekvid, tegev, artikkel, rahavoog, nimetus, saldoandmik, db, kr, aasta, kuu)
    SELECT 2,
           2,
           (CASE
                WHEN $3 = 1
                    THEN 999
                ELSE $2 END),

           tegev,
           konto,
           rahavoo,
           nimetus,
           sum(CASE WHEN db = 0 THEN (kr - db) ELSE (db - kr) END),
           sum(db),
           sum(kr),
           year($1) - 1, -- year(($1 - interval '3 month')::date),
           12            --month(($1 - interval '3 month')::date)
    FROM eelarve.saldoandmik
    WHERE aasta = year($1) - 1 --year(($1 - interval '3 month')::date)
      AND kuu = 12             -- month(($1 - interval '3 month')::date)
      AND rekvid = (CASE
                        WHEN $3 = 1
                            THEN 999
                        ELSE $2 END)
    GROUP BY tegev, allikas, konto, rahavoo, nimetus;


    GET DIAGNOSTICS l_count= ROW_COUNT;

    RETURN TRUE;


END;
$$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5_query(DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5_query(DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5_query(DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik_lisa_1_5_query(DATE, INTEGER, INTEGER ) TO dbvaatleja;

/*
SELECT eelarve.eelarve_andmik_lisa_1_5_query(DATE(2018, 12, 31), 63, 0);

SELECT *
FROM tmp_andmik
WHERE rekvid = 63
  AND tyyp = 2;
*/
--