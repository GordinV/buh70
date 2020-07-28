DROP FUNCTION IF EXISTS eelarve.tekke_taitmine(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.tekke_taitmine(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                  l_kond INTEGER)
    RETURNS TABLE (
        rekv_id  INTEGER,
        summa    NUMERIC(14, 2),
        tegev    VARCHAR(20),
        allikas  VARCHAR(20),
        artikkel VARCHAR(20),
        rahavoog VARCHAR(20),
        tunnus   VARCHAR(20)
    ) AS
$BODY$

    -- kontod
WITH /*qryKontodTulud AS (
    SELECT l.kood, l.tun5 AS tyyp
    FROM libs.library l
             INNER JOIN
         eelarve.fakt_tulud fakttulud
         ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((fakttulud.kood) :: TEXT))))
    WHERE l.library = 'KONTOD'
      AND L.status <> 3
),*/
    qryKontodKulud AS (
        SELECT l.kood, l.tun5
        FROM libs.library l
                 INNER JOIN
             eelarve.fakt_kulud fakt_kulud
             ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((fakt_kulud.kood) :: TEXT))))
        WHERE l.library = 'KONTOD'
          AND L.status <> 3
    )
SELECT rekvid     AS rekv_id,
       sum(summa) AS summa,
       tegev,
       allikas,
       artikkel,
       rahavoog,
       tunnus
FROM (
         -- расходы
         SELECT j1.summa AS summa,
                j1.kood1 AS tegev,
                j1.kood2 AS allikas,
                j1.kood3 AS rahavoog,
                j1.kood5 AS artikkel,
                j1.tunnus,
                j.rekvid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontodKulud k ON k.kood = j1.deebet
         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN l_kond > 0 THEN j.rekvid ELSE l_rekvid END
           AND left(j1.kood5, 3) NOT IN ('611', '613', '608')

         UNION ALL
         -- востановление расходов
         SELECT -1 * j1.summa AS summa,
                j1.kood1      AS tegev,
                j1.kood2      AS allikas,
                j1.kood3      AS rahavoog,
                j1.kood5      AS artikkel,
                j1.tunnus,
                j.rekvid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontodKulud k ON k.kood = j1.kreedit
         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN l_kond > 0 THEN j.rekvid ELSE l_rekvid END
           AND left(j1.kood5, 3) NOT IN ('611', '613', '608')
     ) qry
WHERE NOT empty(artikkel)
  AND summa <> 0
GROUP BY rekvid, tegev, allikas, artikkel, tunnus, rahavoog;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.tekke_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tekke_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tekke_taitmine( DATE,DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tekke_taitmine( DATE,DATE, INTEGER, INTEGER ) TO dbvaatleja;
/*

select * from (
SELECT *
FROM eelarve.tekke_taitmine('2020-01-01', '2020-03-31', 3, 0)
) qry
where artikkel = '2586'
*/