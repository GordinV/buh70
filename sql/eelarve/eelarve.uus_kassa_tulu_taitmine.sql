DROP FUNCTION IF EXISTS eelarve.uus_kassa_tulu_taitmine(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.uus_kassa_tulu_taitmine(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
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
         SELECT summa                         AS summa,
                j1.kood1::TEXT                AS tegev,
                j1.kood2::TEXT                AS allikas,
                j1.kood3::TEXT                AS rahavoog,
                j1.kood5::TEXT                AS artikkel,
                j1.tunnus::TEXT,
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
                  INNER JOIN libs.library l ON l.kood = j1.kood5
             AND l.tun5 = 1
             AND l.library = 'TULUDEALLIKAD' --tulud
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
           AND l.status <> 3
         UNION ALL
         -- востановление
         SELECT -1 * j1.summa                 AS summa,
                j1.kood1::TEXT                AS tegev,
                j1.kood2::TEXT                AS allikas,
                j1.kood3::TEXT                AS rahavoog,
                j1.kood5::TEXT                AS artikkel,
                j1.tunnus::TEXT,
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
                  INNER JOIN libs.library l ON l.kood = j1.kood5 AND l.tun5 = 1 AND l.library = 'TULUDEALLIKAD' --tulud
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
           AND l.status <> 3
     ) qry
WHERE NOT empty(artikkel)
  AND summa <> 0
  AND artikkel NOT IN ('2586')
  AND (CASE
           WHEN artikkel = '2585' AND allikas = '80' THEN TRUE
           WHEN artikkel = '2585' AND rahavoog <> '05' THEN FALSE
           ELSE TRUE END) -- V.B. 13.02.2024

GROUP BY rekvid, tegev, allikas, artikkel, tunnus, rahavoog, kuu, aasta
HAVING sum(summa) <> 0;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_tulu_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_tulu_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_tulu_taitmine( DATE,DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_tulu_taitmine( DATE,DATE, INTEGER, INTEGER ) TO dbvaatleja;
/*

SELECT *
FROM eelarve.uus_kassa_tulu_taitmine('2021-01-01', '2021-12-31', 63, 0)
where artikkel = '3501'

*/