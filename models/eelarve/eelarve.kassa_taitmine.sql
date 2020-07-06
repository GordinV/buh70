DROP FUNCTION IF EXISTS eelarve.kassa_taitmine(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.kassa_taitmine(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
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

SELECT rekvid     AS rekv_id,
       sum(summa) AS summa,
       tegev,
       allikas,
       artikkel,
       rahavoog,
       tunnus
FROM (
         -- kulud
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
                  JOIN eelarve.kassa_kulud kassakulud
                       ON ltrim(rtrim(j1.deebet)) ~~ ltrim(rtrim(kassakulud.kood))
                  JOIN eelarve.kassa_kontod kassakontod
                       ON ltrim(rtrim(j1.kreedit)) ~~ ltrim(rtrim(kassakontod.kood))
         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN l_kond > 0 THEN j.rekvid ELSE l_rekvid END
         UNION ALL
         SELECT -j1.summa AS summa,
                j1.kood1  AS tegev,
                j1.kood2  AS allikas,
                j1.kood3  AS rahavoog,
                j1.kood5  AS artikkel,
                j1.tunnus,
                j.rekvid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  JOIN eelarve.kassa_kulud kassakulud
                       ON ltrim(rtrim(j1.kreedit)) ~~ ltrim(rtrim(kassakulud.kood))
                  JOIN eelarve.kassa_kontod kassakontod
                       ON ltrim(rtrim(j1.deebet)) ~~ ltrim(rtrim(kassakontod.kood))

         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN l_kond > 0 THEN j.rekvid ELSE l_rekvid END
         UNION ALL
         -- tulud
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
                  JOIN eelarve.kassa_tulud AS kassatulud ON ltrim(rtrim(j1.kreedit)) ~~ ltrim(rtrim(kassatulud.kood))
                  JOIN eelarve.kassa_kontod kassakontod
                       ON ltrim(rtrim((j1.deebet) :: TEXT)) ~~ ltrim(rtrim(kassakontod.kood))
         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN l_kond > 0 THEN j.rekvid ELSE l_rekvid END
         UNION ALL
         SELECT -j1.summa AS summa,
                j1.kood1  AS tegev,
                j1.kood2  AS allikas,
                j1.kood3  AS rahavoog,
                j1.kood5  AS artikkel,
                j1.tunnus,
                j.rekvid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  JOIN eelarve.kassa_tulud AS kassatulud ON ltrim(rtrim(j1.deebet)) ~~ ltrim(rtrim(kassatulud.kood))
                  JOIN eelarve.kassa_kontod kassakontod
                       ON ltrim(rtrim((j1.kreedit) :: TEXT)) ~~ ltrim(rtrim(kassakontod.kood))

         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN l_kond > 0 THEN j.rekvid ELSE l_rekvid END
     ) qry
WHERE NOT empty(artikkel)
  AND summa <> 0
GROUP BY rekvid, tegev, allikas, artikkel, tunnus, rahavoog;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.kassa_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kassa_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kassa_taitmine( DATE,DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.kassa_taitmine( DATE,DATE, INTEGER, INTEGER ) TO dbvaatleja;
/*

SELECT *
FROM eelarve.kassa_taitmine('2020-01-01', '2020-03-31', 3, 0)

*/