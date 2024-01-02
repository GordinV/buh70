DROP FUNCTION IF EXISTS eelarve.tekke_taitmine_detailne(DATE, DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.tekke_taitmine_detailne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                                           l_kond INTEGER, l_params JSONB DEFAULT '{}'::JSONB)
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
        objekt VARCHAR(20)
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
     params AS (
         SELECT l_kpv1                                               AS kpv1,
                l_kpv2                                               AS kpv2,
                l_rekvid                                             AS rekv_id,
                l_kond                                               AS kond,
                coalesce((l_params ->> 'artikkel')::TEXT, '') || '%' AS artikkel,
                coalesce((l_params ->> 'tegev')::TEXT, '') || '%'    AS tegev,
                coalesce((l_params ->> 'allikas')::TEXT, '') || '%'  AS allikas,
                coalesce((l_params ->> 'tunnus')::TEXT, '') || '%'   AS tunnus,
                coalesce((l_params ->> 'proj')::TEXT, '') || '%'     AS proj,
                coalesce((l_params ->> 'uritus')::TEXT, '') || '%'   AS uritus,
                coalesce((l_params ->> 'rahavoog')::TEXT, '') || '%' AS rahavoog,
                coalesce((l_params ->> 'objekt')::TEXT, '') || '%'   AS objekt
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
     ),
     docs_types AS (
         SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('JOURNAL')
     ),
     qryArt AS (SELECT kood
                FROM libs.library l
                WHERE l.tun5 = 2 --kulud
                  AND l.library = 'TULUDEALLIKAD'
                  AND status < 3)

SELECT qry.rekvid     AS rekv_id,
       sum(qry.summa) AS summa,
       qry.tegev,
       qry.allikas,
       qry.artikkel,
       qry.rahavoog,
       qry.tunnus,
       qry.proj,
       qry.uritus,
       qry.objekt
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
                j1.proj                    AS proj,
                j1.kood4                   AS uritus,
                j1.objekt,
                j.rekvid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontodKulud k ON k.kood = j1.deebet
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
              params

         WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
           AND coalesce(a.kpv, j.kpv) <= params.kpv2
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND d.status < 3
           AND d.doc_type_id IN (SELECT id FROM docs_types)
           AND j1.kood5 IN (SELECT kood FROM qryArt)
           AND NOT empty(j1.kood5)
         GROUP BY j1.kood1, j1.kood2, j1.kood3, j1.kood5, j1.tunnus, j.rekvid, j1.proj, j1.kood4, j1.objekt
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
                j1.proj,
                j1.kood4                          AS uritus,
                j1.objekt,
                j.rekvid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontodKulud k ON k.kood = j1.kreedit
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
              params
         WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
           AND coalesce(a.kpv, j.kpv) <= params.kpv2
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND d.status < 3
           AND d.doc_type_id IN (SELECT id FROM docs_types)
           AND j1.kood5 IN (SELECT kood FROM qryArt)
           AND NOT empty(j1.kood5)
         GROUP BY j1.kood1, j1.kood2, j1.kood3, j1.kood5, j1.tunnus, j.rekvid, j1.proj, j1.kood4, j1.objekt
     ) qry,
     params
WHERE NOT empty(qry.artikkel)
  AND coalesce(qry.artikkel,'') LIKE params.artikkel
  AND coalesce(qry.allikas,'') LIKE params.allikas
  AND coalesce(qry.tegev,'') LIKE params.tegev
  AND coalesce(qry.tunnus,'') LIKE params.tunnus
  AND coalesce(qry.proj,'') LIKE params.proj
  AND coalesce(qry.uritus,'') LIKE params.uritus
  AND coalesce(qry.rahavoog,'') LIKE params.rahavoog
  AND coalesce(qry.objekt,'') LIKE params.objekt
  AND qry.summa <> 0

GROUP BY qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, qry.tunnus, qry.rahavoog, qry.proj, qry.uritus, qry.objekt;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.tekke_taitmine_detailne( DATE, DATE, INTEGER, INTEGER,JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tekke_taitmine_detailne( DATE, DATE, INTEGER, INTEGER,JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tekke_taitmine_detailne( DATE,DATE, INTEGER, INTEGER,JSONB ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tekke_taitmine_detailne( DATE,DATE, INTEGER, INTEGER,JSONB ) TO dbvaatleja;
/*

select * from (
SELECT *
FROM eelarve.tekke_taitmine_detailne('2023-01-01', '2023-12-31', 132, 1, '{"allikas":"","artikkel":"", "proj":"","tunnus":""}'::jsonb)
) qry
where artikkel like '4502%'
*/