DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, INTEGER, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, TEXT);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.kaibeasutusandmik(l_konto TEXT, l_asutus INTEGER, l_kpv1 DATE, l_kpv2 DATE,
                                                   l_rekvid INTEGER, l_tunnus TEXT DEFAULT '%',
                                                   l_kond INTEGER DEFAULT 0,
                                                   l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
        alg_saldo NUMERIC(14, 2),
        deebet    NUMERIC(14, 2),
        kreedit   NUMERIC(14, 2),
        konto     VARCHAR(20),
        asutus_id INTEGER,
        rekv_id   INTEGER
    )
AS
$BODY$

WITH params AS (
    SELECT l_params ->> 'proj'   AS proj,
           l_params ->> 'tunnus' AS tunnus,
           l_params ->> 'uritus' AS uritus
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
     docs_types AS (
         SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('JOURNAL')
     ),
     report AS (
         SELECT sum(qry.alg_saldo)     AS alg_saldo,
                sum(qry.deebet)        AS deebet,
                sum(qry.kreedit)       AS kreedit,
                qry.konto::VARCHAR(20) AS konto,
                qry.asutus_id          AS asutus_id,
                qry.rekv_id            AS rekv_id
--                l_rekvid               AS rekv_id
         FROM (
                  -- alg.db
                  SELECT D.rekvid                                                                         AS rekv_id,
                         CASE WHEN left(j1.deebet, 4) IN ('1001') THEN NULL ELSE j.asutusid END:: INTEGER AS asutus_id,
                         (j1.summa)                                                                       AS alg_saldo,
                         0 :: NUMERIC(14, 2)                                                              AS deebet,
                         0 :: NUMERIC(14, 2)                                                              AS kreedit,
                         trim(j1.deebet)::VARCHAR(20)                                                     AS konto
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                       params
                  WHERE j.kpv < l_kpv1
                    AND d.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND CASE
                            WHEN (j1.kreedit = '650100' OR j1.deebet = '650100') THEN j.asutusid IS NOT NULL
                            ELSE TRUE END
                    AND (empty(l_asutus) OR j.asutusid = l_asutus)
                    AND (empty(l_konto) OR j1.deebet LIKE ltrim(rtrim(l_konto)) || '%')
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND coalesce(j1.tunnus, '') ILIKE l_tunnus
                    -- V. B. 19.10.2022
                    AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')

                    -- поправка Калле 10.10.2022
                    AND (date_part('year', coalesce(a.kpv, j.kpv)) = date_part('year', l_kpv1::DATE) OR
                         ltrim(rtrim(j1.deebet)) IN (SELECT kood
                                                     FROM com_kontoplaan
                                                     WHERE tyyp IN (1, 2)
                                                       -- J. Tsekanina 21.02.2023
                                                       AND left(kood, 3) NOT IN ('100')
                         )
                      )

                  UNION ALL

                  -- alg.kr
                  SELECT j.rekvid                                                                          AS rekv_id,
                         CASE WHEN left(j1.kreedit, 4) IN ('1001') THEN NULL ELSE j.asutusid END:: INTEGER AS asutus_id,
                         -1 * (j1.summa)                                                                   AS alg_saldo,
                         0 :: NUMERIC                                                                      AS deebet,
                         0 :: NUMERIC                                                                      AS kreedit,
                         trim(j1.kreedit)::VARCHAR(20)                                                     AS konto
                  FROM docs.doc D
                           INNER JOIN docs.journal j ON j.parentid = D.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                       params
                  WHERE j.kpv < l_kpv1
                    AND d.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
--           AND j.asutusid IS NOT NULL
                    AND (empty(l_asutus) OR j.asutusid = l_asutus)
                    AND (empty(l_konto) OR j1.kreedit LIKE ltrim(rtrim(l_konto)) || '%')
                    -- V. B. 19.10.2022
                    AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')
                    AND coalesce(j1.tunnus, '') ILIKE l_tunnus
                    -- поправка Калле 10.10.2022

                    AND (date_part('year', coalesce(a.kpv, j.kpv)) = date_part('year', l_kpv1::DATE) OR
                         ltrim(rtrim(j1.kreedit)) IN (SELECT kood
                                                      FROM com_kontoplaan
                                                      WHERE tyyp IN (1, 2)
                                                        -- J. Tsekanina 21.02.2023
                                                        AND left(kood, 3) NOT IN ('100')
                         ))
                  UNION ALL
                  -- db kaibed
                  SELECT j.rekvid                                                                         AS rekv_id,
                         CASE WHEN left(j1.deebet, 4) IN ('1001') THEN NULL ELSE j.asutusid END:: INTEGER AS asutus_id,
                         0 :: NUMERIC(14, 2)                                                              AS alg_saldo,
                         (j1.summa)                                                                       AS deebet,
                         0 :: NUMERIC(14, 2)                                                              AS kreedit,
                         trim(j1.deebet)                                                                  AS konto
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                       params
                  WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
                    AND j.kpv <= l_kpv2
                    AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)

--           AND j.asutusid IS NOT NULL
                    AND (empty(l_konto) OR j1.deebet LIKE ltrim(rtrim(l_konto)) || '%')
                    AND (empty(l_asutus) OR j.asutusid = l_asutus)
                    AND coalesce(j1.tunnus, '') ILIKE l_tunnus
                    -- V. B. 19.10.2022
                    AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')

                  UNION ALL
-- kr kaibed
                  SELECT j.rekvid                                                                          AS rekv_id,
                         CASE WHEN left(j1.kreedit, 4) IN ('1001') THEN NULL ELSE j.asutusid END:: INTEGER AS asutus_id,
                         0 :: NUMERIC(14, 2)                                                               AS alg_saldo,
                         0 :: NUMERIC                                                                      AS deebet,
                         (j1.summa)                                                                        AS kreedit,
                         trim(j1.kreedit)                                                                  AS konto
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                       params
                  WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
                    AND j.kpv <= l_kpv2
                    AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)

--           AND j.asutusid IS NOT NULL
                    AND (empty(l_asutus) OR j.asutusid = l_asutus)
                    AND (empty(l_konto) OR j1.kreedit LIKE ltrim(rtrim(l_konto)) || '%')
                    AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')
                    AND coalesce(j1.tunnus, '') ILIKE l_tunnus
              ) qry
         GROUP BY konto, asutus_id, rekv_id)
SELECT alg_saldo,
       deebet,
       kreedit,
       konto,
       asutus_id,
       rekv_id
FROM report
UNION ALL
SELECT sum(alg_saldo) AS alg_saldo,
       sum(deebet)    AS deebet,
       sum(kreedit)   AS kreedit,
       konto,
       asutus_id,
       999999         AS rekv_id
FROM report
WHERE l_kond > 0
GROUP BY konto, asutus_id

    ;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER, JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER , JSONB) TO dbkasutaja;


/*
select * from (
SELECT  a.nimetus, a.id, a.staatus, a.properties->>'kehtivus' as kehtivus, a.tp, rep.*
FROM docs.kaibeasutusandmik('%',0,'2023-01-01','2023-01-01', 119,'%',1) rep
left outer join libs.asutus a on a.id = rep.asutus_id
where kreedit = 37.90

) qry
where kehtivus is not null
order by kehtivus
*/

