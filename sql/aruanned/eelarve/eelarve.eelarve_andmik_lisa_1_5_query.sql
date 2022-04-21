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
    l_count   INTEGER = 0;
    l_rekv_id INTEGER = CASE WHEN l_rekvid = 63 AND coalesce(l_kond, 0) = 1 THEN 999 ELSE l_rekvid END;
BEGIN


    DROP TABLE IF EXISTS tmp_andmik;

    CREATE TEMPORARY TABLE tmp_andmik (
        idx                TEXT,
        tyyp               INTEGER,
        rekvid             INTEGER,
        tegev              VARCHAR(20),
        allikas            VARCHAR(20),
        artikkel           VARCHAR(20),
        rahavoog           VARCHAR(20),
        nimetus            VARCHAR(254),
        eelarve            NUMERIC(14, 2),
        eelarve_taps       NUMERIC(14, 2),
        eelarve_kassa      NUMERIC(14, 2),
        eelarve_kassa_taps NUMERIC(14, 2),
        tegelik            NUMERIC(14, 2),
        kassa              NUMERIC(14, 2),
        saldoandmik        NUMERIC(14, 2),
        db                 NUMERIC(14, 2),
        kr                 NUMERIC(14, 2),
        aasta              INTEGER,
        kuu                INTEGER,
        is_kulud           INTEGER DEFAULT 0,
        rekv_id            INTEGER NULL
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
    INSERT INTO tmp_andmik (idx, tyyp, rekvid, tegev, allikas, artikkel, nimetus, eelarve, eelarve_kassa,
                            eelarve_taps, eelarve_kassa_taps,
                            tegelik,
                            kassa, aasta, kuu,
                            is_kulud)
    WITH cur_kulude_kassa_taitmine AS (
        SELECT *
        FROM eelarve.uus_kassa_taitmine(make_date(year(l_kpv), 01, 01), l_kpv, l_rekvid, l_kond)
        WHERE artikkel NOT IN ('655')
          AND rekv_id <> 9 -- исключить
    ),
         cur_tulude_kassa_taitmine AS (
             SELECT *
             FROM eelarve.uus_kassa_tulu_taitmine(make_date(year(l_kpv), 01, 01), l_kpv, l_rekvid, l_kond)
             WHERE rekv_id <> 9
         )

    SELECT '2.1'                                           AS idx,
           1                                               AS tyyp,
           qry.rekvid,
           qry.tegev::VARCHAR(20)                          AS tegev,
           qry.allikas::VARCHAR(20)                        AS allikas,
           qry.artikkel::VARCHAR(20)                       AS artikkel,
           l.nimetus::VARCHAR(254),
           sum(qry.eelarve)::NUMERIC(14, 2)                AS eelarve,
           sum(qry.eelarve_kassa)::NUMERIC(14, 2)          AS eelarve_kassa,
           sum(qry.eelarve_taps)::NUMERIC(14, 2)           AS eelarve_taps,
           sum(qry.eelarve_kassa_taps)::NUMERIC(14, 2)     AS eelarve_kassa_taps,
           sum(qry.tegelik)::NUMERIC(14, 2)                AS tegelik,
           sum(qry.kassa)::NUMERIC(14, 2)                  AS kassa,
           year(l_kpv)                                     AS aasta,
           month(l_kpv),
           CASE WHEN l.tun5 = 1 THEN 0 ELSE 1 END::INTEGER AS is_kulud
    FROM (
             -- eelarve kinni
             SELECT e.rekvid,
                    e.summa       AS eelarve,
                    e.summa_kassa AS eelarve_kassa,
                    0             AS eelarve_taps,
                    0             AS eelarve_kassa_taps,
                    0 :: NUMERIC  AS tegelik,
                    0 :: NUMERIC  AS kassa,
                    e.kood1       AS tegev,
                    e.kood2       AS allikas,
                    e.kood5       AS artikkel
             FROM eelarve.eelarve e
             WHERE rekvid = (CASE
                                 WHEN $3 = 1
                                     THEN rekvid
                                 ELSE l_rekv_id END)
               AND e.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid, $1))
               AND e.rekvid <> 9
               AND aasta = year($1)
               AND (e.kpv IS NULL) --  OR e.kpv <= $1
               AND e.status <> 3
             UNION ALL
             -- eelarve taps
             SELECT e.rekvid
                     ,
                    0             AS eelarve
                     ,
                    0             AS eelarve_kassa
                     ,
                    e.summa       AS eelarve_taps
                     ,
                    e.summa_kassa AS eelarve_kassa_taps
                     ,
                    0 :: NUMERIC  AS tegelik
                     ,
                    0 :: NUMERIC  AS kassa
                     ,
                    e.kood1       AS tegev
                     ,
                    e.kood2       AS allikas
                     ,
                    e.kood5       AS artikkel
             FROM eelarve.eelarve e
             WHERE rekvid = (CASE
                                 WHEN $3 = 1
                                     THEN rekvid
                                 ELSE l_rekv_id END)
               AND e.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid, $1))
               AND e.rekvid <> 9
               AND aasta = year($1)
               AND (e.kpv IS NOT NULL AND e.kpv <= l_kpv)
               AND e.status <> 3
             UNION ALL
             SELECT rekvid
                     ,
                    0 :: NUMERIC              AS eelarve
                     ,
                    0 :: NUMERIC              AS eelarve_kassa
                     ,
                    0 :: NUMERIC              AS eelarve_taps
                     ,
                    0 :: NUMERIC              AS eelarve_kassa_taps
                     ,
                    summa                     AS tegelik
                     ,
                    0 :: NUMERIC              AS kassa
                     ,
                    COALESCE(ft.tegev, '')    AS tegev
                     ,
                    COALESCE(ft.allikas, '')  AS allikas
                     ,
                    COALESCE(ft.artikkel, '') AS artikkel
             FROM cur_kulude_taitmine ft
             WHERE ft.rekvid = (CASE
                                    WHEN l_kond = 1
                                        THEN rekvid
                                    ELSE l_rekv_id END)
               AND ft.rekvid IN (SELECT rekv_id
                                 FROM get_asutuse_struktuur(l_rekvid, $1))
               AND ft.rekvid <> 9
               AND ft.kuu <= MONTH(l_kpv)
               AND ft.aasta = year(l_kpv)
               AND ft.artikkel IS NOT NULL
               AND NOT empty(ft.artikkel)
             UNION ALL
             SELECT rekvid
                     ,
                    0 :: NUMERIC              AS eelarve
                     ,
                    0 :: NUMERIC              AS eelarve_kassa
                     ,
                    0 :: NUMERIC              AS eelarve_taps
                     ,
                    0 :: NUMERIC              AS eelarve_kassa_taps
                     ,
                    summa                     AS tegelik
                     ,
                    0 :: NUMERIC              AS kassa
                     ,
                    COALESCE(tt.tegev, '')    AS tegev
                     ,
                    COALESCE(tt.allikas, '')  AS allikas
                     ,
                    COALESCE(tt.artikkel, '') AS artikkel
             FROM cur_tulude_taitmine tt
             WHERE tt.rekvid = (CASE
                                    WHEN l_kond = 1
                                        THEN rekvid
                                    ELSE l_rekv_id END)
               AND tt.rekvid IN (SELECT rekv_id
                                 FROM get_asutuse_struktuur(l_rekvid, $1))
               AND tt.rekvid <> 9
               AND tt.kuu <= MONTH(l_kpv)
               AND tt.aasta = year(l_kpv)
               AND tt.artikkel IS NOT NULL
               AND NOT empty(tt.artikkel)
             UNION ALL
             SELECT rekv_id      AS rekvid,
                    0 :: NUMERIC AS eelarve,
                    0 :: NUMERIC AS eelarve_kassa,
                    0 :: NUMERIC AS eelarve_taps,
                    0 :: NUMERIC AS eelarve_kassa_taps,
                    0 :: NUMERIC AS tegelik,
                    summa        AS kassa,
                    tegev,
                    allikas,
                    artikkel
             FROM cur_kulude_kassa_taitmine kt
             WHERE kt.artikkel IS NOT NULL
               AND NOT empty(kt.artikkel)
             UNION ALL
             SELECT rekv_id      AS rekvid,
                    0 :: NUMERIC AS eelarve,
                    0 :: NUMERIC AS eelarve_kassa,
                    0 :: NUMERIC AS eelarve_taps,
                    0 :: NUMERIC AS eelarve_kassa_taps,
                    0 :: NUMERIC AS tegelik,
                    summa        AS kassa,
                    tegev,
                    allikas,
                    artikkel
             FROM cur_tulude_kassa_taitmine kt
             WHERE kt.artikkel IS NOT NULL
               AND NOT empty(kt.artikkel)
             UNION ALL

             -- kassatulud (art.jargi) miinus
             SELECT kassakulu.rekvid,
                    0::NUMERIC   AS eelarve,
                    0::NUMERIC   AS eelarve_kassa,
                    0 :: NUMERIC AS eelarve_taps,
                    0 :: NUMERIC AS eelarve_kassa_taps,
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
                        AND YEAR(j.kpv) = YEAR(l_kpv)
                        AND j.rekvid = (CASE
                                            WHEN l_kond = 1
                                                THEN j.rekvid
                                            ELSE $2 END)
                        AND j.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid, $1))
                        AND j.rekvid <> 9
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
             WHERE artikkel <> '655'
             UNION ALL

             -- kassatulud (art.jargi), kulud
             -- 3500, 352
             SELECT kassatulu.rekvid,
                    0::NUMERIC   AS eelarve
                     ,
                    0::NUMERIC   AS eelarve_kassa
                     ,
                    0 :: NUMERIC AS eelarve_taps
                     ,
                    0 :: NUMERIC AS eelarve_kassa_taps
                     ,
                    0::NUMERIC   AS tegelik
                     ,
                    (summa)      AS kassa
                     ,
                    kassatulu.tegev::VARCHAR(20)
                     ,
                    kassatulu.allikas::VARCHAR(20)
                     ,
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
                        AND j.rekvid = (CASE
                                            WHEN $3 = 1
                                                THEN j.rekvid
                                            ELSE l_rekvid END)
                        AND j.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid, $1))
                        AND j.rekvid <> 9
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
                    0::NUMERIC   AS eelarve,
                    0::NUMERIC   AS eelarve_kassa,
                    0 :: NUMERIC AS eelarve_taps,
                    0 :: NUMERIC AS eelarve_kassa_taps,
                    0::NUMERIC   AS tegelik,
                    (summa)      AS kassa,
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
                        AND j.rekvid = (CASE
                                            WHEN $3 = 1
                                                THEN j.rekvid
                                            ELSE l_rekvid END)
                        AND j.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid, $1))
                        AND j.rekvid <> 9
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
         ) qry
             LEFT OUTER JOIN libs.library l ON l.kood = qry.artikkel
        AND l.library = 'TULUDEALLIKAD'
        AND l.status <> 3
    GROUP BY qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, l.nimetus, l.tun5;

    INSERT INTO tmp_andmik (idx, tyyp, rekvid, tegev, artikkel, rahavoog, nimetus, saldoandmik, db, kr, aasta, kuu)
    SELECT 2,
           2,
           l_rekvid,
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
                        WHEN $3 = 1 AND l_rekvid = 63
                            THEN 999
                        WHEN $3 = 1 AND l_rekvid <> 63 THEN rekvid
                        ELSE l_rekvid END)
      AND rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid, $1)
                     UNION ALL
                     SELECT CASE WHEN l_rekvid = 63 THEN 999 ELSE l_rekvid END AS rekv_id
    )
      AND rekvid <> 9
    GROUP BY tegev
            , konto
            , rahavoo
            , nimetus;

    GET DIAGNOSTICS l_count= ROW_COUNT;

    -- eelmise periodi andmed
    INSERT INTO tmp_andmik (idx, tyyp, rekvid, tegev, artikkel, rahavoog, nimetus, saldoandmik, db, kr, aasta, kuu)
    SELECT 2,
           2,
           l_rekvid,
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
                        WHEN $3 = 1 AND l_rekvid = 63
                            THEN 999
                        WHEN $3 = 1 AND l_rekvid <> 63 THEN rekvid
                        ELSE l_rekv_id END)
      AND rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid, make_date(year($1) - 1, 12, 31))
                     UNION ALL
                     SELECT CASE WHEN l_rekvid = 63 THEN 999 ELSE l_rekvid END AS rekv_id
    )
      AND rekvid <> 9
    GROUP BY tegev
            , allikas
            , konto
            , rahavoo
            , nimetus;


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
select * from (
    SELECT * from eelarve.eelarve_andmik_lisa_1_5_query(DATE(2022, 03, 31), 119, 1)
    ) qry
where artikkel =  '3221'


1413729.28

SELECT *
FROM tmp_andmik
WHERE artikkel like '100%'
and aasta = 2020
  AND tyyp = 2;

select *from eelarve.saldoandmik
where rekvid = 999
and kuu = 12
and aasta = 2020
and konto like '100%'

select * from eelarve.saldoandmik where timestamp = '2022-03-17 03:00:00.010366'

*/

SELECT now()
--