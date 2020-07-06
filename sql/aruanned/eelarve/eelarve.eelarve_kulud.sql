DROP FUNCTION IF EXISTS eelarve.eelarve_kulud(INTEGER, DATE, BOOLEAN, INTEGER);
DROP FUNCTION IF EXISTS eelarve.eelarve_kulud(INTEGER, DATE, BOOLEAN, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.eelarve_kulud(INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.eelarve_kulud(l_aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, is_parandus BOOLEAN,
                                                 l_rekvid INTEGER,
                                                 l_kond INTEGER)
    RETURNS TABLE (
        rekv_id  INTEGER,
        eelarve  NUMERIC(14, 2),
        tegelik  NUMERIC(14, 2),
        kassa    NUMERIC(14, 2),
        laen     NUMERIC(14, 2),
        tegev    VARCHAR(20),
        allikas  VARCHAR(20),
        artikkel VARCHAR(20),
        tunnus   VARCHAR(20)
    ) AS
$BODY$
SELECT rekvid,
       sum(eelarve)                                                 AS eelarve,
       sum(tegelik)                                                 AS tegelik,
       sum(kassa)                                                   AS kassa,
       coalesce(sum(eelarve)
                    FILTER (WHERE allikas = 'LE-LA'), 0) :: NUMERIC AS laen,
       tegev,
       allikas,
       artikkel,
       tunnus
FROM (
         SELECT rekvid,
                summa        AS eelarve,
                0 :: NUMERIC AS tegelik,
                0 :: NUMERIC AS kassa,
                kood1        AS tegev,
                kood2        AS allikas,
                kood5        AS artikkel,
                tunnus
         FROM eelarve.kulud e
         WHERE rekvid = (CASE
                             WHEN l_kond = 1
                                 THEN rekvid
                             ELSE l_rekvid END)
           AND e.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND aasta = l_aasta
           AND (empty(is_parandus) OR (e.kpv IS NULL OR e.kpv <= l_kpv2))
         UNION ALL
/*       SELECT
         rekvid,
         0 :: NUMERIC           AS eelarve,
         summa                  AS tegelik,
         0 :: NUMERIC           AS kassa,
         COALESCE(tegev, '')    AS tegev,
         COALESCE(allikas, '')  AS allikas,
         COALESCE(artikkel, '') AS artikkel,
         COALESCE(tunnus, '')   AS tunnus
       FROM cur_kulude_taitmine ft
       WHERE
         ft.rekvid = (CASE WHEN l_kond = 1
           THEN rekvid
                      ELSE l_rekvid END)
         AND ft.rekvid IN (SELECT rekv_id
                           FROM get_asutuse_struktuur(l_rekvid))
         AND ft.aasta = l_aasta
         AND ft.kuu >= MONTH(l_kpv1)
         AND ft.kuu <= MONTH(l_kpv2)
         AND ft.artikkel IS NOT NULL AND NOT empty(ft.artikkel)
*/
         SELECT rekv_id,
                0 :: NUMERIC           AS eelarve,
                summa                  AS tegelik,
                0 :: NUMERIC           AS kassa,
                COALESCE(tegev, '')    AS tegev,
                COALESCE(allikas, '')  AS allikas,
                COALESCE(artikkel, '') AS artikkel,
                COALESCE(tunnus, '')   AS tunnus
         FROM eelarve.tekke_taitmine(l_kpv1, l_kpv2, l_rekvid, l_kond) k
                  INNER JOIN libs.library l ON l.kood = k.artikkel
             AND l.library = 'TULUDEALLIKAD'
             AND l.tun5 = 2
             AND l.status <> 3
             AND k.summa <> 0
         UNION ALL
/*         SELECT rekvid,
                0 :: NUMERIC AS eelarve,
                0 :: NUMERIC AS tegelik,
                summa        AS kassa,
                tegev,
                allikas,
                artikkel,
                tunnus
         FROM cur_kulude_kassa_taitmine kt
         WHERE kt.rekvid = (CASE
                                WHEN l_kond = 1
                                    THEN rekvid
                                ELSE l_rekvid END)

           AND kt.rekvid IN (SELECT rekv_id
                             FROM get_asutuse_struktuur(l_rekvid))
           AND kt.aasta = l_aasta
           AND kt.kuu >= MONTH(l_kpv1)
           AND kt.kuu <= MONTH(l_kpv2)
           AND kt.artikkel IS NOT NULL
           AND NOT empty(kt.artikkel)
*/
         SELECT rekv_id,
                0 :: NUMERIC           AS eelarve,
                0:: NUMERIC            AS tegelik,
                summa :: NUMERIC       AS kassa,
                COALESCE(tegev, '')    AS tegev,
                COALESCE(allikas, '')  AS allikas,
                COALESCE(artikkel, '') AS artikkel,
                COALESCE(tunnus, '')   AS tunnus
         FROM eelarve.kassa_taitmine(l_kpv1, l_kpv2, l_rekvid, l_kond) k
                  INNER JOIN libs.library l ON l.kood = k.artikkel
             AND l.library = 'TULUDEALLIKAD'
             AND l.tun5 = 2
             AND l.status <> 3
             AND k.summa <> 0
     ) qry
GROUP BY rekvid, tegev, allikas, artikkel, tunnus;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.eelarve_kulud(INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_kulud(INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_kulud(INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_kulud(INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER) TO dbvaatleja;
/*

SELECT *
FROM eelarve.eelarve_kulud(2020::integer, '2020-01-01'::date,'2020-03-31'::date, true, 3, 0)

*/