DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, BOOLEAN, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(l_aasta INTEGER,
                                                                     l_kpv DATE,
                                                                     l_rekvid INTEGER,
                                                                     l_kond INTEGER)
    RETURNS TABLE (
        rekv_id            INTEGER,
        eelarve_kinni      NUMERIC(14, 2),
        eelarve_parandatud NUMERIC(14, 2),
        tegelik            NUMERIC(14, 2),
        tegelik_kbm        NUMERIC(14, 2),
        kassa              NUMERIC(14, 2),
        kassa_kbm          NUMERIC(14, 2),
        tegev              VARCHAR(20),
        allikas            VARCHAR(20),
        artikkel           VARCHAR(20),
        rahavoog           VARCHAR(20),
        tunnus             VARCHAR(20)
    ) AS
$BODY$
SELECT rekvid,
       sum(eelarve_kinni)      AS eelarve_kinni,
       sum(eelarve_parandatud) AS eelarve_parandatud,
       sum(tegelik)            AS tegelik,
       sum(tegelik_kbm)        AS tegelik_kbm,
       sum(kassa)              AS kassa,
       sum(kassa_kbm)          AS kassa_kbm,
       tegev,
       allikas,
       artikkel,
       rahavoog,
       tunnus
FROM (
         SELECT rekvid,
                summa        AS eelarve_kinni,
                0:: NUMERIC  AS eelarve_parandatud,
                0 :: NUMERIC AS tegelik,
                0 :: NUMERIC AS tegelik_kbm,
                0 :: NUMERIC AS kassa,
                0 :: NUMERIC AS kassa_kbm,
                kood1        AS tegev,
                kood2        AS allikas,
                kood5        AS artikkel,
                kood3        AS rahavoog,
                tunnus
         FROM eelarve.kulud e
         WHERE rekvid = (CASE
                             WHEN l_kond = 1
                                 THEN rekvid
                             ELSE l_rekvid END)
           AND e.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND aasta = l_aasta
           AND e.kpv IS NULL
         UNION ALL
         SELECT rekvid,
                0 :: NUMERIC AS eelarve_kinni,
                summa        AS eelarve_parandatud,
                0 :: NUMERIC AS tegelik,
                0 :: NUMERIC AS tegelik_kbm,
                0 :: NUMERIC AS kassa,
                0 :: NUMERIC AS kassa_kbm,
                kood1        AS tegev,
                kood2        AS allikas,
                kood5        AS artikkel,
                kood3        AS rahavoog,
                tunnus
         FROM eelarve.kulud e
         WHERE rekvid = (CASE
                             WHEN l_kond = 1
                                 THEN rekvid
                             ELSE l_rekvid END)
           AND e.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND aasta = l_aasta
           AND e.kpv IS NOT NULL
           AND e.kpv <= l_kpv

         UNION ALL
         SELECT rekvid,
                0 :: NUMERIC           AS eelarve_kinni,
                0 :: NUMERIC           AS eelarve_parandatud,
                summa                  AS tegelik,
                kbm                    AS tegelik_kbm,
                0 :: NUMERIC           AS kassa,
                0 :: NUMERIC           AS kassa_kbm,
                COALESCE(tegev, '')    AS tegev,
                COALESCE(allikas, '')  AS allikas,
                COALESCE(artikkel, '') AS artikkel,
                COALESCE(rahavoog, '') AS rahavoog,
                COALESCE(tunnus, '')   AS tunnus
         FROM cur_kulude_taitmine ft
         WHERE ft.rekvid = (CASE
                                WHEN l_kond = 1
                                    THEN rekvid
                                ELSE l_rekvid END)
           AND ft.rekvid IN (SELECT rekv_id
                             FROM get_asutuse_struktuur(l_rekvid))
           AND ft.aasta = l_aasta
           AND ft.kuu <= MONTH(l_kpv)
           AND ft.artikkel IS NOT NULL
           AND NOT empty(ft.artikkel)
         UNION ALL
         SELECT rekvid,
                0 :: NUMERIC   AS eelarve_kinni,
                0 :: NUMERIC   AS eelarve_parandatud,
                0 :: NUMERIC   AS tegelik,
                0 :: NUMERIC   AS tegelik_kbm,
                summa          AS kassa,
                kbm :: NUMERIC AS kassa_kbm,
                tegev,
                allikas,
                artikkel,
                rahavoog,
                tunnus
         FROM cur_kulude_kassa_taitmine kt
         WHERE kt.rekvid = (CASE
                                WHEN l_kond = 1
                                    THEN rekvid
                                ELSE l_rekvid END)

           AND kt.rekvid IN (SELECT rekv_id
                             FROM get_asutuse_struktuur(l_rekvid))
           AND kt.aasta = l_aasta
           AND kt.kuu <= MONTH(l_kpv)
           AND kt.artikkel IS NOT NULL
           AND NOT empty(kt.artikkel)
     ) qry
GROUP BY rekvid, tegev, allikas, artikkel, rahavoog, tunnus;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER) TO dbvaatleja;
/*

SELECT *
    FROM eelarve.eelarve_taitmine_allikas_artikkel(2018::integer, '2018-12-31'::date,  63, 1)

*/