DROP FUNCTION IF EXISTS eelarve.uus_kassa_taitmine(DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.uus_kassa_taitmine(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
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
WITH qryKontodKulud AS (
    SELECT l.kood, l.tun5 AS tyyp
    FROM libs.library l
             INNER JOIN eelarve.kassa_kulud kassakulud
                        ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((kassakulud.kood) :: TEXT))))
    WHERE l.library = 'KONTOD'
      AND L.status <> 3
),
     qryKassaKontod AS (
         SELECT l.kood, l.tun5 AS tyyp
         FROM libs.library l
                  INNER JOIN
              eelarve.kassa_kontod kassakontod
              ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((kassakontod.kood) :: TEXT))))
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

         -- расход
         SELECT (summa)                       AS summa,
                j1.kood1::TEXT                AS tegev,
                j1.kood2::TEXT                AS allikas,
                j1.kood3::TEXT                AS rahavoog,
                j1.kood5::TEXT                AS artikkel,
                j1.tunnus::TEXT,
                j.rekvid,
                TRUE                          AS kas_kulud,
                (d.id)                        AS docs_ids,
                month(coalesce(a.kpv, j.kpv)) AS kuu,
                year(coalesce(a.kpv, j.kpv))  AS aasta
         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontodKulud k ON k.kood = j1.deebet
                  INNER JOIN qryKassaKontod kassa ON kassa.kood = j1.kreedit
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
         WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
           AND coalesce(a.kpv, j.kpv) <= l_kpv2
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
/*         GROUP BY j1.kood1, j1.kood2, j1.kood3, j1.kood5, j1.tunnus, j.rekvid, month(coalesce(a.kpv, j.kpv)),
                  year(coalesce(a.kpv, j.kpv))
*/
         UNION ALL
         -- востановление расходов
         SELECT  (-1 * j1.summa)            AS summa,
                         j1.kood1::TEXT                AS tegev,
                         j1.kood2::TEXT                AS allikas,
                         j1.kood3::TEXT                AS rahavoog,
                         j1.kood5::TEXT                AS artikkel,
                         j1.tunnus::TEXT,
                         j.rekvid,
                         TRUE                          AS kas_kulud,
                         (d.id)               AS docs_ids,
                         month(coalesce(a.kpv, j.kpv)) AS kuu,
                         year(coalesce(a.kpv, j.kpv))  AS aasta
         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  INNER JOIN qryKontodKulud k ON k.kood = j1.kreedit
                  INNER JOIN qryKassaKontod kassa ON kassa.kood = j1.deebet
                  INNER JOIN libs.library l ON l.kood = j1.kood5 AND l.tun5 = 2 AND library = 'TULUDEALLIKAD' --kulud
         -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id

         WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
           AND coalesce(a.kpv, j.kpv) <= l_kpv2
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
 ) qry
WHERE NOT empty(artikkel)
--  and artikkel not in ('655')
  AND summa <> 0
GROUP BY rekvid, tegev, allikas, artikkel, tunnus, rahavoog, kuu, aasta
HAVING sum(summa) <> 0;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_taitmine( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_taitmine( DATE,DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.uus_kassa_taitmine( DATE,DATE, INTEGER, INTEGER ) TO dbvaatleja;
/*

SELECT *
FROM eelarve.uus_kassa_taitmine('2022-01-01', '2022-03-31', 29, 1)
where artikkel = '655'

select *

*/