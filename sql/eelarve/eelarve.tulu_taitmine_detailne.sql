DROP FUNCTION IF EXISTS eelarve.tulu_taitmine_detailne(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.tulu_taitmine_detailne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                          l_kond INTEGER)
    RETURNS TABLE (
        rekv_id  INTEGER,
        summa    NUMERIC(14, 2),
        tegev    VARCHAR(20),
        allikas  VARCHAR(20),
        artikkel VARCHAR(20),
        rahavoog VARCHAR(20),
        tunnus   VARCHAR(20),
        proj     VARCHAR(20),
        uritus   VARCHAR(20),
        objekt   VARCHAR(20),
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
),
     params AS (
         SELECT l_kpv1   AS kpv1,
                l_kpv2   AS kpv2,
                l_rekvid AS rekv_id,
                l_kond   AS kond
     ),
     qryArtiklid AS (
         SELECT kood
         FROM libs.library l
         WHERE l.tun5 = 1 --tulud
           AND l.library = 'TULUDEALLIKAD'
           AND l.status <> 3
     ),
     rekv_ids AS (
         SELECT a.rekv_id
         FROM params,
              get_asutuse_struktuur(params.rekv_id) a
         WHERE a.rekv_id = CASE
                               WHEN params.kond = 1
                                   -- kond
                                   THEN a.rekv_id
                               ELSE params.rekv_id END
     )
SELECT qry.rekvid              AS rekv_id,
       sum(qry.summa)          AS summa,
       qry.tegev,
       qry.allikas,
       qry.artikkel,
       qry.rahavoog,
       qry.tunnus,
       qry.proj,
       qry.uritus,
       qry.objekt,
       array_agg(qry.docs_ids) AS docs_ids,
       qry.kuu,
       qry.aasta
FROM (
         -- доход
         SELECT summa         AS summa,
                j.kood1::TEXT AS tegev,
                j.kood2::TEXT AS allikas,
                j.kood3::TEXT AS rahavoog,
                j.kood5::TEXT AS artikkel,
                j.tunnus::TEXT,
                j.proj::TEXT,
                j.uritus::TEXT,
                j.objekt::TEXT,
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
                      j1.proj,
                      j1.kood4               AS uritus,
                      j1.objekt,
                      d.rekvid,
                      d.id,
                      coalesce(a.kpv, j.kpv) AS kpv,
                      j1.kreedit
               FROM docs.doc D
                        INNER JOIN docs.journal j ON j.parentid = D.id
                        INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                   -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                        LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                    params

               WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
                 AND coalesce(a.kpv, j.kpv) <= params.kpv2
                 AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                 --строка art 1532 в доходах может быть только с rahavoog 02, соответственно с rahavoog 23  быть не далжно
                 AND (CASE WHEN j1.kood5 = '1532' AND j1.kood3 = '23' THEN FALSE ELSE TRUE END)
                 AND d.status <> 3
                 AND j1.kood5 IN (SELECT kood FROM qryArtiklid)
              ) j
                  INNER JOIN qryKontod k ON k.kood = j.kreedit
         UNION ALL
         -- востановление
         SELECT -1 * j.summa  AS summa,
                j.kood1::TEXT AS tegev,
                j.kood2::TEXT AS allikas,
                j.kood3::TEXT AS rahavoog,
                j.kood5::TEXT AS artikkel,
                j.tunnus::TEXT,
                j.proj::TEXT,
                j.uritus::TEXT,
                j.objekt::TEXT,
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
                      j1.proj,
                      j1.kood4               AS uritus,
                      j1.objekt,
                      j1.deebet,
                      coalesce(a.kpv, j.kpv) AS kpv,
                      d.rekvid,
                      d.id
               FROM docs.doc D
                        INNER JOIN docs.journal j ON j.parentid = D.id
                        INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                   -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                        LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                    params

               WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
                 AND coalesce(a.kpv, j.kpv) <= params.kpv2
                 AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                 --строка art 1532 в доходах может быть только с rahavoog 02, соответственно с rahavoog 23  быть не далжно
                 AND (CASE WHEN j1.kood5 = '1532' AND j1.kood3 = '23' THEN FALSE ELSE TRUE END)
                 AND d.status <> 3
                 AND j1.kood5 IN (SELECT kood FROM qryArtiklid)
              ) j
                  INNER JOIN qryKontod k ON k.kood = j.deebet
     ) qry
WHERE NOT empty(qry.artikkel)
  AND qry.summa <> 0
  AND qry.artikkel NOT IN ('2586')
GROUP BY qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, qry.tunnus, qry.proj, qry.uritus, qry.objekt, qry.rahavoog,
         qry.kuu,
         qry.aasta
HAVING sum(qry.summa) <> 0;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.tulu_taitmine_detailne( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulu_taitmine_detailne( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulu_taitmine_detailne( DATE,DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tulu_taitmine_detailne( DATE,DATE, INTEGER, INTEGER ) TO dbvaatleja;
/*

SELECT sum(summa) over(),*
FROM eelarve.tulu_taitmine_detailne('2023-01-01', '2023-12-31', 132, 1)
where artikkel like '3224%'
and allikas = '80'
and tegev = '01112'
and empty(rahavoog)

50527445.92

 SELECT l.kood, l.tun5 AS tyyp
    FROM libs.library l
             INNER JOIN eelarve.fakt_tulud tulud
                        ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((tulud.kood) :: TEXT))))
    WHERE l.library = 'KONTOD'
      AND L.status <> 3

*/