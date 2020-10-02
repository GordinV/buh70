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
WITH qryReport AS (
    (
        -- eelarve, kulud
        SELECT rekvid,
               summa                                                               AS eelarve,
               0 :: NUMERIC                                                        AS tegelik,
               0 :: NUMERIC                                                        AS kassa,
               kood1                                                               AS tegev,
               kood2                                                               AS allikas,
               CASE WHEN kood5 LIKE '320%' THEN '320' ELSE COALESCE(kood5, '') END AS artikkel,
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
          AND e.status <> 3
        UNION ALL
        -- tekke taitmine
        SELECT rekv_id,
               0 :: NUMERIC                                                              AS eelarve,
               summa                                                                     AS tegelik,
               0 :: NUMERIC                                                              AS kassa,
               COALESCE(tegev, '')                                                       AS tegev,
               COALESCE(allikas, '')                                                     AS allikas,
               CASE WHEN artikkel LIKE '320%' THEN '320' ELSE COALESCE(artikkel, '') END AS artikkel,
               COALESCE(tunnus, '')                                                      AS tunnus
        FROM eelarve.tekke_taitmine(l_kpv1, l_kpv2, l_rekvid, l_kond) k
                 INNER JOIN libs.library l ON l.kood = k.artikkel
            AND l.library = 'TULUDEALLIKAD'
--            AND l.tun5 = 2
            AND l.status <> 3
            AND k.summa <> 0
        UNION ALL
        SELECT rekv_id,
               0 :: NUMERIC AS eelarve,
               0 :: NUMERIC AS tegelik,
               summa        AS kassa,
               tegev,
               allikas,
               artikkel,
               tunnus
        FROM eelarve.uus_kassa_taitmine(l_kpv1, l_kpv2, l_rekvid, l_kond) kt
                 INNER JOIN libs.library l ON l.kood = kt.artikkel
            AND l.library = 'TULUDEALLIKAD'
--            AND l.tun5 = 2
            AND l.status <> 3
            AND kt.summa <> 0
    )
)
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
FROM qryReport
GROUP BY rekvid, tegev, allikas, artikkel, tunnus
UNION ALL
SELECT 999999,
       sum(eelarve)                                                 AS eelarve,
       sum(tegelik)                                                 AS tegelik,
       sum(kassa)                                                   AS kassa,
       coalesce(sum(eelarve)
                    FILTER (WHERE allikas = 'LE-LA'), 0) :: NUMERIC AS laen,
       tegev,
       allikas,
       artikkel,
       tunnus
FROM qryReport
WHERE l_kond > 0
GROUP BY tegev, allikas, artikkel, tunnus


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.eelarve_kulud(INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_kulud(INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_kulud(INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_kulud(INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER) TO dbvaatleja;
/*

select *  from (
SELECT *
FROM eelarve.eelarve_kulud(2020::integer, '2020-01-01'::date,'2020-03-31'::date, true, 63, 1)
) qry
where artikkel like '38250%'
*/