DROP FUNCTION IF EXISTS eelarve.tulu_taitmine(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.tulu_taitmine(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
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
             INNER JOIN eelarve.fakt_tulud tulud
                        ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((tulud.kood) :: TEXT))))
    WHERE l.library = 'KONTOD'
      AND L.status <> 3
      AND l.kood NOT IN ('381010')
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
         SELECT summa         AS summa,
                j.kood1::TEXT AS tegev,
                j.kood2::TEXT AS allikas,
                j.kood3::TEXT AS rahavoog,
                j.kood5::TEXT AS artikkel,
                j.tunnus::TEXT,
                j.rekvid,
                FALSE         AS kas_kulud,
                j.id          AS docs_ids,
                month(j.kpv)  AS kuu,
                year(j.kpv)   AS aasta

         FROM (SELECT j1.summa,
                      j1.kood1,
                      j1.kood2,
                      j1.kood3,
                      j1.kood5,
                      j1.tunnus,
                      d.rekvid,
                      d.id,
                      coalesce(a.kpv, j.kpv) AS kpv,
                      j1.kreedit
               FROM docs.doc D
                        INNER JOIN docs.journal j ON j.parentid = D.id
                        INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                   -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                        LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id

               WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
                 AND coalesce(a.kpv, j.kpv) <= l_kpv2
                 AND j.rekvid IN (SELECT rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid))
                 AND j.rekvid = CASE
                                    WHEN l_kond
                                        > 0 THEN j.rekvid
                                    ELSE l_rekvid END
                 --строка art 1532 в доходах может быть только с rahavoog 02, соответственно с rahavoog 23  быть не далжно
                 AND (CASE WHEN j1.kood5 = '1532' AND j1.kood3 = '23' THEN FALSE ELSE TRUE END)
                 AND d.status <> 3
              ) j
                  INNER JOIN qryKontod k ON k.kood = j.kreedit
                  INNER JOIN libs.library l ON l.kood = j.kood5
             AND l.tun5 = 1 --tulud
             AND l.status <> 3
             AND l.library = 'TULUDEALLIKAD'

         UNION ALL
         -- востановление
         SELECT -1 * j.summa  AS summa,
                j.kood1::TEXT AS tegev,
                j.kood2::TEXT AS allikas,
                j.kood3::TEXT AS rahavoog,
                j.kood5::TEXT AS artikkel,
                j.tunnus::TEXT,
                j.rekvid,
                FALSE         AS kas_kulud,
                j.id          AS docs_ids,
                month(j.kpv)  AS kuu,
                year(j.kpv)   AS aasta

         FROM (SELECT j1.summa,
                      j1.kood1,
                      j1.kood2,
                      j1.kood3,
                      j1.kood5,
                      j1.tunnus,
                      j1.deebet,
                      coalesce(a.kpv, j.kpv) AS kpv,
                      d.rekvid,
                      d.id
               FROM docs.doc D
                        INNER JOIN docs.journal j ON j.parentid = D.id
                        INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                   -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                        LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id

               WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
                 AND coalesce(a.kpv, j.kpv) <= l_kpv2
                 AND j.rekvid IN (SELECT rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid))
                 AND j.rekvid = CASE
                                    WHEN l_kond
                                        > 0 THEN j.rekvid
                                    ELSE l_rekvid END
                 --строка art 1532 в доходах может быть только с rahavoog 02, соответственно с rahavoog 23  быть не далжно
                 AND (CASE WHEN j1.kood5 = '1532' AND j1.kood3 = '23' THEN FALSE ELSE TRUE END)
                 AND d.status <> 3
              ) j
                  INNER JOIN qryKontod k ON k.kood = j.deebet
                  INNER JOIN libs.library l ON l.kood = j.kood5 AND l.tun5 = 1 --tulud
             AND l.library = 'TULUDEALLIKAD'
             AND l.status <> 3
     ) qry
WHERE NOT empty(artikkel)
  AND summa <> 0
  AND artikkel NOT IN ('2586')
GROUP BY rekvid, tegev, allikas, artikkel, tunnus, rahavoog, kuu, aasta
HAVING sum(summa) <> 0;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.tulu_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulu_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulu_taitmine( DATE,DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tulu_taitmine( DATE,DATE, INTEGER, INTEGER ) TO dbvaatleja;
/*

SELECT sum(summa) over(),*
FROM eelarve.tulu_taitmine('2021-01-01', '2021-12-31', 130, 0)
where artikkel like '3823%'
and allikas = '80'
and tegev = '01112'
and empty(rahavoog)


 SELECT l.kood, l.tun5 AS tyyp
    FROM libs.library l
             INNER JOIN eelarve.fakt_tulud tulud
                        ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((tulud.kood) :: TEXT))))
    WHERE l.library = 'KONTOD'
      AND L.status <> 3

*/