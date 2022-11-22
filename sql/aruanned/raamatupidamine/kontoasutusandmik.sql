DROP FUNCTION IF EXISTS docs.kontoasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kontoasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.kontoasutusandmik(l_konto TEXT, l_asutus INTEGER, l_kpv1 DATE, l_kpv2 DATE,
                                                   l_rekvid INTEGER, l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
        rekv_id    INTEGER,
        asutus_id  INTEGER,
        kpv        DATE,
        deebet     NUMERIC(14, 2),
        kreedit    NUMERIC(14, 2),
        konto      VARCHAR(20),
        korr_konto VARCHAR(20),
        dok        VARCHAR(120),
        number     INTEGER,
        kood1      VARCHAR(20),
        kood2      VARCHAR(20),
        kood3      VARCHAR(20),
        kood4      VARCHAR(20),
        kood5      VARCHAR(20),
        proj       VARCHAR(20),
        tunnus     VARCHAR(20)
    )
AS
$BODY$
WITH rekv_ids AS (
    SELECT rekv_id
    FROM get_asutuse_struktuur(l_rekvid)
),
     docs_types AS (
         SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('JOURNAL')
     ),
     algsaldo AS (
         SELECT rekv_id,
                sum(deebet) - sum(kreedit) AS alg_saldo,
                asutus_id,
                konto
         FROM (
                  SELECT D.rekvid                  AS rekv_id,
                         asutusid                  AS asutus_id,
                         TRIM(deebet)::VARCHAR(20) AS konto,
                         summa                     AS deebet,
                         0 :: NUMERIC(14, 2)       AS kreedit
                  FROM docs.doc D
                           INNER JOIN docs.journal j ON j.parentid = D.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  WHERE j.asutusid IS NOT NULL
                    AND D.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND (empty(l_asutus) OR j.asutusid = l_asutus)
                    AND j.kpv < l_kpv1
                    AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)

                    AND (date_part('year', coalesce(a.kpv, j.kpv)) = date_part('year', l_kpv1::DATE) OR
                         ltrim(rtrim(j1.deebet)) IN (SELECT kood FROM com_kontoplaan WHERE tyyp IN (1, 2)))

                    AND ((l_params ->>
                          'tunnus') IS NULL OR
                         COALESCE(j1.tunnus,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'tunnus'),
                                                     '') ||
                                            '%')
                    AND ((l_params ->>
                          'konto') IS NULL OR
                         COALESCE(j1.deebet,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'konto'),
                                                     '') ||
                                            '%')
                    AND ((l_params ->>
                          'proj') IS NULL OR
                         COALESCE(j1.proj,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'proj'),
                                                     '') ||
                                            '%')
                    AND ((l_params ->>
                          'uritus') IS NULL OR
                         COALESCE(j1.kood4,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'uritus'),
                                                     '') ||
                                            '%')
                    AND ((l_params ->>
                          'tegevus') IS NULL OR
                         COALESCE(j1.kood1,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'tegevus'),
                                                     '') ||
                                            '%')
                  UNION ALL
                  SELECT D.rekvid                   AS rekv_id,
                         asutusid                   AS asutus_id,
                         TRIM(kreedit)::VARCHAR(20) AS konto,
                         0 :: NUMERIC(14, 2)        AS deebet,
                         summa                      AS kreedit
                  FROM docs.doc D
                           INNER JOIN docs.journal j ON j.parentid = D.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                  WHERE j.asutusid IS NOT NULL
                    AND D.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND (empty(l_asutus) OR j.asutusid = l_asutus)
                    AND j.kpv < l_kpv1
                    AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)

                    AND (date_part('year', coalesce(a.kpv, j.kpv)) = date_part('year', l_kpv1::DATE) OR
                         ltrim(rtrim(j1.kreedit)) IN (SELECT kood FROM com_kontoplaan WHERE tyyp IN (1, 2)))

                    AND ((l_params ->>
                          'tunnus') IS NULL OR
                         COALESCE(j1.tunnus,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'tunnus'),
                                                     '') ||
                                            '%')
                    AND ((l_params ->>
                          'konto') IS NULL OR
                         COALESCE(j1.kreedit,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'konto'),
                                                     '') ||
                                            '%')
                    AND ((l_params ->>
                          'proj') IS NULL OR
                         COALESCE(j1.proj,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'proj'),
                                                     '') ||
                                            '%')
                    AND ((l_params ->>
                          'uritus') IS NULL OR
                         COALESCE(j1.kood4,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'uritus'),
                                                     '') ||
                                            '%')
                    AND ((l_params ->>
                          'tegevus') IS NULL OR
                         COALESCE(j1.kood1,
                                  '') ILIKE COALESCE((l_params ->>
                                                      'tegevus'),
                                                     '') ||
                                            '%')
              ) qry
         WHERE (empty(l_konto) OR qry.konto LIKE ltrim(rtrim(l_konto)) ||
                                                 '%')
         GROUP BY rekv_id, asutus_id, konto)
SELECT a.rekv_id,
       a.asutus_id,
       NULL::DATE           AS kpv,
       a.alg_saldo          AS deebet,
       0 :: NUMERIC(14, 2)  AS kreedit,
       a.konto,
       NULL :: VARCHAR(20)  AS korr_konto,
       NULL :: VARCHAR(120) AS dok,
       NULL :: INTEGER      AS number,
       NULL :: VARCHAR(20)  AS kood1,
       NULL :: VARCHAR(20)  AS kood2,
       NULL :: VARCHAR(20)  AS kood3,
       NULL :: VARCHAR(20)  AS kood4,
       NULL :: VARCHAR(20)  AS kood5,
       NULL :: VARCHAR(20)  AS proj,
       NULL :: VARCHAR(20)  AS tunnus
FROM algsaldo a
UNION ALL
SELECT qry.rekv_id,
       qry.asutus_id,
       qry.kpv,
       qry.deebet                        AS deebet,
       qry.kreedit                       AS kreedit,
       trim(qry.konto)::VARCHAR(20)      AS konto,
       trim(qry.korr_konto)::VARCHAR(20) AS korr_konto,
       qry.dok,
       qry.number,
       qry.kood1,
       qry.kood2,
       qry.kood3,
       qry.kood4,
       qry.kood5,
       qry.proj,
       qry.tunnus
FROM (
         SELECT j.rekvid     AS rekv_id,
                j.kpv,
                j.summa      AS deebet,
                0 :: NUMERIC AS kreedit,
                j.deebet     AS konto,
                j.kreedit    AS korr_konto,
                j.dok,
                j.number,
                j.asutusid   AS asutus_id,
                j.kood1,
                j.kood2,
                j.kood3,
                j.kood4,
                j.kood5,
                j.proj,
                j.tunnus
         FROM cur_journal j
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = j.id
         WHERE j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND coalesce(a.kpv, j.kpv) >= l_kpv1
           AND j.kpv <= l_kpv2
           AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND ((l_params ->> 'tunnus') IS NULL OR
                coalesce(j.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus'), '') || '%')
           AND ((l_params ->> 'konto') IS NULL OR
                coalesce(j.deebet, '') ILIKE coalesce((l_params ->> 'konto'), '') || '%')
           AND ((l_params ->> 'proj') IS NULL OR coalesce(j.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
           AND ((l_params ->> 'uritus') IS NULL OR
                coalesce(j.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')
           AND ((l_params ->> 'tegevus') IS NULL OR
                coalesce(j.kood1, '') ILIKE coalesce((l_params ->> 'tegevus'), '') || '%')
         UNION ALL
         SELECT j.rekvid     AS rekv_id,
                j.kpv,
                0 :: NUMERIC AS deebet,
                j.summa      AS kreedit,
                j.kreedit    AS konto,
                j.deebet     AS korr_konto,
                j.dok,
                j.number,
                j.asutusid   AS asutus_id,
                j.kood1,
                j.kood2,
                j.kood3,
                j.kood4,
                j.kood5,
                j.proj,
                j.tunnus
         FROM cur_journal j
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = j.id
         WHERE j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND coalesce(a.kpv, j.kpv) >= l_kpv1
           AND j.kpv <= l_kpv2
           AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND ((l_params ->> 'tunnus') IS NULL OR
                coalesce(j.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus'), '') || '%')
           AND ((l_params ->> 'konto') IS NULL OR
                coalesce(j.kreedit, '') ILIKE coalesce((l_params ->> 'konto'), '') || '%')
           AND ((l_params ->> 'proj') IS NULL OR coalesce(j.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
           AND ((l_params ->> 'uritus') IS NULL OR
                coalesce(j.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')
           AND ((l_params ->> 'tegevus') IS NULL OR
                coalesce(j.kood1, '') ILIKE coalesce((l_params ->> 'tegevus'), '') || '%')
     ) qry
WHERE (empty(l_konto) OR qry.konto LIKE ltrim(rtrim(l_konto)) || '%');

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, JSONB ) TO dbkasutaja;


/*
  SELECT
    sum(deebet)
      FILTER (WHERE kpv is null) OVER (
      PARTITION BY rekv_id, asutus_id, konto ) AS alg_saldo,
    CASE WHEN kpv is not null
      THEN deebet
    ELSE 0 END                                 AS deebet,
    kreedit,
    sum(deebet - kreedit)
    OVER (
      PARTITION BY rekv_id, asutus_id, konto ) AS lopp_saldo,
    kpv,
    rekv_id,
    asutus_id,
    konto,
    korr_konto,
    dok,
    number,
    kood1,
    kood2,
    kood3,
    kood4,
    kood5,
    proj,
    tunnus
  FROM docs.kontoasutusandmik(null::text, NULL :: INTEGER, '2018-06-10', current_date :: DATE, 1)
*/

-- 156094.56, 0

SELECT sum(deebet) OVER (), sum(kreedit) OVER (), *
FROM docs.kontoasutusandmik('650100'::TEXT, NULL :: INTEGER, '2022-01-01', '2022-10-30' :: DATE, 63, '{
  "konto": "%",
  "tegevus": "%",
  "proj": "%"
}')
