--DROP FUNCTION IF EXISTS eelarve.tekke_taitmine(DATE, DATE, INTEGER, INTEGER);

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
    )
AS
$BODY$

    -- kontod
WITH qryKontodKulud AS (
    SELECT l.kood, l.tun5
    FROM libs.library l
             INNER JOIN
         eelarve.fakt_kulud fakt_kulud
         ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((fakt_kulud.kood) :: TEXT))))
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
     ),
     qryArt AS (SELECT kood
                FROM libs.library l
                WHERE l.tun5 = 2 --kulud
                  AND l.library = 'TULUDEALLIKAD'
                  AND status < 3)

SELECT rekvid     AS rekv_id,
       sum(summa) AS summa,
       tegev,
       allikas,
       artikkel,
       rahavoog,
       tunnus
FROM (
         -- расходы
         SELECT 1                          AS kulud,
                sum(CASE
                        WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND j1.kood3 NOT IN ('01')
                            THEN 0
                        ELSE j1.summa END) AS summa,
                j1.kood1                   AS tegev,
                j1.kood2                   AS allikas,
                j1.kood3                   AS rahavoog,
                j1.kood5                   AS artikkel,
                j1.tunnus,
                j.rekvid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontodKulud k ON k.kood = j1.deebet
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id

         WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
           AND coalesce(a.kpv, j.kpv) <= l_kpv2
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND j1.kood5 IN (SELECT kood FROM qryArt)
           AND NOT empty(j1.kood5)
         GROUP BY j1.kood1, j1.kood2, j1.kood3, j1.kood5, j1.tunnus, j.rekvid

         UNION ALL
         -- востановление расходов
         SELECT 2                                 AS tulud,
                sum(-1 * (CASE
                              WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND j1.kood3 NOT IN ('01') THEN 0
                              ELSE j1.summa END)) AS summa,
                j1.kood1                          AS tegev,
                j1.kood2                          AS allikas,
                j1.kood3                          AS rahavoog,
                j1.kood5                          AS artikkel,
                j1.tunnus,
                j.rekvid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontodKulud k ON k.kood = j1.kreedit
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
         WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
           AND coalesce(a.kpv, j.kpv) <= l_kpv2
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND j1.kood5 IN (SELECT kood FROM qryArt)
           AND NOT empty(j1.kood5)
         GROUP BY j1.kood1, j1.kood2, j1.kood3, j1.kood5, j1.tunnus, j.rekvid
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
FROM eelarve.tekke_taitmine('2022-01-01', '2022-12-31', 130, 1)
) qry
where artikkel like '4502%'
*/