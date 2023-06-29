DROP FUNCTION IF EXISTS eelarve.uus_kassa_tulu_taitmine_detailne(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.uus_kassa_tulu_taitmine_detailne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
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
        docs_ids INTEGER[],
        kuu      INTEGER,
        aasta    INTEGER
    )
AS
$BODY$

    -- kontod
WITH qryKontod AS (
    SELECT DISTINCT l.kood, l.tun5 AS tyyp
    FROM libs.library l
             INNER JOIN eelarve.kassa_tulud kassatulud
                        ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((kassatulud.kood) :: TEXT))))
    WHERE l.library = 'KONTOD'
      AND L.status <> 3
),
     qryKassaKontod AS (
         SELECT DISTINCT l.kood, l.tun5 AS tyyp
         FROM libs.library l
                  INNER JOIN
              eelarve.kassa_kontod kassakontod
              ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((kassakontod.kood) :: TEXT))))
         WHERE l.library = 'KONTOD'
           AND L.status <> 3
     ),
     qryTuludeKontod AS (
         SELECT kood
         FROM libs.library l
         WHERE l.tun5 = 1
           AND l.library = 'TULUDEALLIKAD'
           AND l.status < 3
     ),
     params AS (
         SELECT l_kpv1   AS kpv1,
                l_kpv2   AS kpv2,
                l_rekvid AS rekv_id,
                l_kond   AS kond
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
       array_agg(qry.docs_ids) AS docs_ids,
       qry.kuu,
       qry.aasta
FROM (
         -- доход
         SELECT summa                         AS summa,
                j1.kood1::TEXT                AS tegev,
                j1.kood2::TEXT                AS allikas,
                j1.kood3::TEXT                AS rahavoog,
                j1.kood5::TEXT                AS artikkel,
                j1.tunnus::TEXT,
                j1.proj::TEXT                 AS proj,
                j1.kood4::TEXT                AS uritus,
                j.rekvid,
                FALSE                         AS kas_kulud,
                d.id                          AS docs_ids,
                month(coalesce(a.kpv, j.kpv)) AS kuu,
                year(coalesce(a.kpv, j.kpv))  AS aasta
         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontod k ON k.kood = j1.kreedit
                  INNER JOIN qryKassaKontod kassa ON kassa.kood = j1.deebet
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
              params
         WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
           AND coalesce(a.kpv, j.kpv) <= params.kpv2
           AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND j1.kood5 IN (SELECT kood FROM qryTuludeKontod)
         UNION ALL
         -- востановление
         SELECT -1 * j1.summa                 AS summa,
                j1.kood1::TEXT                AS tegev,
                j1.kood2::TEXT                AS allikas,
                j1.kood3::TEXT                AS rahavoog,
                j1.kood5::TEXT                AS artikkel,
                j1.tunnus::TEXT,
                j1.proj::TEXT                 AS proj,
                j1.kood4::TEXT                AS uritus,
                j.rekvid,
                FALSE                         AS kas_kulud,
                d.id                          AS docs_ids,
                month(coalesce(a.kpv, j.kpv)) AS kuu,
                year(coalesce(a.kpv, j.kpv))  AS aasta

         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontod k ON k.kood = j1.deebet
                  INNER JOIN qryKassaKontod kassa ON kassa.kood = j1.kreedit
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
              params

         WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
           AND coalesce(a.kpv, j.kpv) <= params.kpv2
           AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND j1.kood5 IN (SELECT kood FROM qryTuludeKontod)
     ) qry
WHERE NOT empty(qry.artikkel)
  AND qry.summa <> 0
  AND qry.artikkel NOT IN ('2586')
GROUP BY qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, qry.tunnus, qry.proj, qry.uritus, qry.rahavoog, qry.kuu,
         qry.aasta
HAVING sum(qry.summa) <> 0;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_tulu_taitmine_detailne( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_tulu_taitmine_detailne( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_tulu_taitmine_detailne( DATE,DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_tulu_taitmine_detailne( DATE,DATE, INTEGER, INTEGER ) TO dbvaatleja;
/*

SELECT sum(summa) over(), *
FROM eelarve.uus_kassa_tulu_taitmine_detailne('2023-01-01', '2023-12-31', 63, 0)
where artikkel = '3501'

44761121.71

*/