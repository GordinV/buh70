DROP FUNCTION IF EXISTS eelarve.kulu_taitmine(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.kulu_taitmine(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                 l_kond INTEGER)
    RETURNS TABLE (
        rekv_id  INTEGER,
        summa    NUMERIC(14, 2),
        tegev    VARCHAR(20),
        allikas  VARCHAR(20),
        artikkel VARCHAR(20),
        rahavoog VARCHAR(20),
        tunnus   VARCHAR(20),
        docs_ids INTEGER[],
        kuu      INTEGER,
        aasta    INTEGER

    )
AS
$BODY$

    -- kontod
WITH qryKontod AS (
    SELECT l.kood, l.tun5 AS tyyp
    FROM libs.library l
             INNER JOIN eelarve.FAKT_kulud kulud
                        ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((kulud.kood) :: TEXT))))
    WHERE l.library = 'KONTOD'
      AND L.status <> 3
),
     rekv_ids AS (
         SELECT rekv_id
         FROM get_asutuse_struktuur(l_rekvid)
         WHERE rekv_id = CASE
                             WHEN l_kond = 1
                                 -- kond
                                 THEN rekv_id
                             ELSE l_rekvid END
     )
SELECT rekvid              AS rekv_id,
       sum(summa)          AS summa,
       tegev,
       allikas,
       artikkel,
       rahavoog,
       tunnus,
       array_agg(docs_ids) AS docs_ids,
       kuu,
       aasta
FROM (
         -- доход
         SELECT CASE
                    WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND j1.kood3 NOT IN ('01') THEN 0
                    ELSE j1.summa END AS summa,
                j1.kood1::TEXT        AS tegev,
                j1.kood2::TEXT        AS allikas,
                j1.kood3::TEXT        AS rahavoog,
                j1.kood5::TEXT        AS artikkel,
                j1.tunnus::TEXT,
                j.rekvid,
                TRUE                  AS kas_kulud,
                d.id                  AS docs_ids,
                month(j.kpv)          AS kuu,
                year(j.kpv)           AS aasta
         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontod k ON k.kood = j1.deebet
         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
         UNION ALL
         -- востановление
         SELECT -1 *
                (CASE
                     WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND j1.kood3 NOT IN ('01') THEN 0
                     ELSE j1.summa END) AS summa,
                j1.kood1::TEXT          AS tegev,
                j1.kood2::TEXT          AS allikas,
                j1.kood3::TEXT          AS rahavoog,
                j1.kood5::TEXT          AS artikkel,
                j1.tunnus::TEXT,
                j.rekvid,
                FALSE                   AS kas_kulud,
                d.id                    AS docs_ids,
                month(j.kpv)            AS kuu,
                year(j.kpv)             AS aasta

         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontod k ON k.kood = j1.kreedit
                  INNER JOIN libs.library l ON l.kood = j1.kood5 AND l.tun5 = 2 --kulud

         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
     ) qry
WHERE NOT empty(artikkel)
  AND summa <> 0
GROUP BY rekvid, tegev, allikas, artikkel, tunnus, rahavoog, kuu, aasta
HAVING sum(summa) <> 0;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.kulu_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kulu_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kulu_taitmine( DATE,DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.kulu_taitmine( DATE,DATE, INTEGER, INTEGER ) TO dbvaatleja;
/*

SELECT *
FROM eelarve.kulu_taitmine('2022-01-01', '2022-12-31', 63, 1)
where artikkel like '15%'

 SELECT l.kood, l.tun5 AS tyyp
    FROM libs.library l
             INNER JOIN eelarve.fakt_tulud tulud
                        ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((tulud.kood) :: TEXT))))
    WHERE l.library = 'KONTOD'
      AND L.status <> 3

*/