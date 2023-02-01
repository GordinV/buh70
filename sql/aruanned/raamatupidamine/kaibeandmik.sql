DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER, INTEGER, TEXT);
DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER, INTEGER, TEXT, JSONB);


CREATE OR REPLACE FUNCTION docs.kaibeandmik(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER DEFAULT 0,
                                            l_tunnus TEXT DEFAULT '%', l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
        alg_saldo NUMERIC(14, 2),
        deebet    NUMERIC(14, 2),
        kreedit   NUMERIC(14, 2),
        konto     VARCHAR(20)
    )
AS
$BODY$
WITH rekv_ids AS (
    SELECT rekv_id
    FROM public.get_asutuse_struktuur(l_rekvid) r
    WHERE CASE
              WHEN l_kond = 1 THEN TRUE
              ELSE l_rekvid = rekv_id END
),
     docs_types AS (
         SELECT id, kood
         FROM libs.library
         WHERE library.library = 'DOK'
           AND kood IN ('JOURNAL')
     ),
     algsaldo AS (
         SELECT sum(deebet) - sum(kreedit) AS alg_saldo,
                konto,
                rekvid
         FROM (
-- < 2022-01-02
                  SELECT d.rekvid,
                         -- уберем нач. сальдо для групп 8 и 9 с прошлых лет
                         sum(CASE
                                 WHEN date_part('year', j.kpv) < date_part('year', l_kpv1) AND
                                      lpad(j1.deebet, 1) IN ('8', '9') THEN 0
                                 ELSE 1 END * j1.summa) AS deebet,
                         0 :: NUMERIC(14, 2)            AS kreedit,
                         trim(j1.deebet)::VARCHAR(20)   AS konto
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, make_date(year(l_kpv1), 01, 01), l_kpv2) <
                        make_date(year(l_kpv1), 01, 01)
                    AND d.status < 3
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)

                    AND ((l_params::JSONB ->> 'konto') IS NULL OR
                         coalesce(j1.deebet, '') LIKE coalesce((l_params::JSONB ->> 'konto'), '') || '%')
                    AND (((CASE
                               WHEN left(j1.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'tunnus') IS NULL OR
                         COALESCE(j1.tunnus, '') ILIKE COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                    AND (((CASE
                               WHEN left(j1.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'proj') IS NULL OR
                         COALESCE(j1.proj, '') ILIKE COALESCE((l_params::JSONB ->> 'proj'), '') || '%')
                    AND (((CASE
                               WHEN left(j1.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'uritus') IS NULL OR
                         COALESCE(j1.kood4, '') ILIKE COALESCE((l_params::JSONB ->> 'uritus'), '') || '%')
                    AND d.status <> 3
                  GROUP BY j1.deebet, d.rekvid
                  UNION ALL
                  -- >= 2022-01-01
                  SELECT d.rekvid,
                         sum(j1.summa)                AS deebet,
                         0 :: NUMERIC(14, 2)          AS kreedit,
                         trim(j1.deebet)::VARCHAR(20) AS konto
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, make_date(year(l_kpv1), 01, 01), l_kpv2) >= make_date(year(l_kpv1), 01, 01)
                    AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) < l_kpv1
                    AND d.status < 3
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND ((l_params::JSONB ->> 'konto') IS NULL OR
                         coalesce(j1.deebet, '') LIKE coalesce((l_params::JSONB ->> 'konto'), '') || '%')
                    AND (l_params::JSONB ->> 'tunnus' IS NULL OR
                         COALESCE(j1.tunnus, '') ILIKE COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                    AND (l_params::JSONB ->> 'proj' IS NULL OR
                         COALESCE(j1.proj, '') ILIKE COALESCE((l_params::JSONB ->> 'proj'), '') || '%')
                    AND (l_params::JSONB ->> 'uritus' IS NULL OR
                         COALESCE(j1.kood4, '') ILIKE COALESCE((l_params::JSONB ->> 'uritus'), '') || '%')
                    AND d.status <> 3
                  GROUP BY j1.deebet, d.rekvid
                  UNION ALL
                  -- < 2022-01-01
                  SELECT d.rekvid,
                         0 :: NUMERIC                   AS deebet,
                         sum(CASE
                                 WHEN date_part('year', j.kpv) < date_part('year', l_kpv1) AND
                                      lpad(j1.kreedit, 1) IN ('8', '9') THEN 0
                                 ELSE 1 END * j1.summa) AS kreedit,
                         trim(j1.kreedit)::VARCHAR(20)  AS konto
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, make_date(year(l_kpv1), 01, 01), l_kpv2) <
                        make_date(year(l_kpv1), 01, 01)
                    AND d.status < 3
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND ((l_params::JSONB ->> 'konto') IS NULL OR
                         coalesce(j1.kreedit, '') LIKE coalesce((l_params::JSONB ->> 'konto'), '') || '%')
                    AND (((CASE
                               WHEN left(j1.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'tunnus') IS NULL OR
                         COALESCE(j1.tunnus, '') ILIKE COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                    AND (((CASE
                               WHEN left(j1.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'proj') IS NULL OR
                         coalesce(j1.proj, '') ILIKE coalesce((l_params::JSONB ->> 'proj'), '') || '%')
                    AND (((CASE
                               WHEN left(j1.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'uritus') IS NULL OR
                         left(j1.kreedit, 1) IN ('1', '2') OR
                         coalesce(j1.kood4, '') ILIKE coalesce((l_params::JSONB ->> 'uritus'), '') || '%')
                    AND d.status <> 3
                  GROUP BY j1.kreedit, d.rekvid
                  UNION ALL
                  -- >= 2022-01-01
                  SELECT d.rekvid,
                         0 :: NUMERIC                  AS deebet,
                         sum(j1.summa)                 AS kreedit,
                         trim(j1.kreedit)::VARCHAR(20) AS konto
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, make_date(year(l_kpv1), 01, 01), l_kpv2) >=
                        make_date(year(l_kpv1), 01, 01)
                    AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) < l_kpv1
                    AND d.status < 3
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND ((l_params::JSONB ->> 'konto') IS NULL OR
                         coalesce(j1.kreedit, '') LIKE coalesce((l_params::JSONB ->> 'konto'), '') || '%')
                    AND ((l_params::JSONB ->> 'tunnus') IS NULL OR
                         COALESCE(j1.tunnus, '') ILIKE COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                    AND ((l_params::JSONB ->>
                          'proj') IS NULL OR
                         coalesce(j1.proj, '') ILIKE coalesce((l_params::JSONB ->> 'proj'), '') || '%')
                    AND ((l_params::JSONB ->>
                          'uritus') IS NULL OR
                         coalesce(j1.kood4, '') ILIKE coalesce((l_params::JSONB ->> 'uritus'), '') || '%')
                    AND d.status <> 3
                  GROUP BY j1.kreedit, d.rekvid
              ) qry
         GROUP BY konto,
                  rekvid)

SELECT sum(qry.alg_saldo) AS alg_saldo,
       sum(qry.deebet)    AS deebet,
       sum(qry.kreedit)   AS kreedit,
       qry.konto
FROM (
         SELECT algsaldo.rekvid,
                algsaldo.alg_saldo,
                0 :: NUMERIC(14, 2) AS deebet,
                0 :: NUMERIC(14, 2) AS kreedit,
                algsaldo.konto
         FROM algsaldo
         UNION ALL
         SELECT d.rekvid,
                0 :: NUMERIC(14, 2)          AS alg_saldo,
                (j1.summa)                   AS deebet,
                0 :: NUMERIC(14, 2)          AS kreedit,
                trim(j1.deebet)::VARCHAR(20) AS konto
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
         WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) >= l_kpv1
           AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) <= l_kpv2
           AND d.status < 3
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND d.doc_type_id IN (SELECT id FROM docs_types)
           AND coalesce(j1.tunnus, '') ILIKE coalesce(l_tunnus, '%')
           AND (l_params ->> 'tunnus' IS NULL OR
                coalesce(j1.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus'), '') || '%')
           AND (l_params ->> 'konto' IS NULL OR
                coalesce(j1.deebet, '') LIKE coalesce((l_params ->> 'konto'), '') || '%')
           AND ((l_params ->> 'proj') IS NULL OR coalesce(j1.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
           AND ((l_params ->> 'uritus') IS NULL OR
                coalesce(j1.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')

         UNION ALL
         SELECT d.rekvid,
                0 :: NUMERIC(14, 2)           AS alg_saldo,
                0 :: NUMERIC                  AS deebet,
                (j1.summa)                    AS kreedit,
                trim(j1.kreedit)::VARCHAR(20) AS konto
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
         WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) >= l_kpv1
           AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) <= l_kpv2
           AND d.status < 3
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND d.doc_type_id IN (SELECT id FROM docs_types)
           AND coalesce(j1.tunnus, '') ILIKE coalesce(l_tunnus, '%')
           AND (l_params ->> 'tunnus' IS NULL OR
                coalesce(j1.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus'), '') || '%')
           AND (l_params ->> 'konto' IS NULL OR
                coalesce(j1.kreedit, '') LIKE coalesce((l_params ->> 'konto'), '') || '%')
           AND ((l_params ->> 'proj') IS NULL OR coalesce(j1.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
           AND ((l_params ->> 'uritus') IS NULL OR
                coalesce(j1.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')
     ) qry
WHERE NOT empty(qry.konto)
  --AND left(konto, 2) NOT IN ('90', '91', '92', '93', '94', '95', '96', '97', '98')
  AND left(konto, 1) NOT IN ('8', '9', '0')
  AND qry.konto NOT IN (SELECT kood
                        FROM com_kontoplaan
                        WHERE kas_virtual > 0)
GROUP BY konto;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER,INTEGER , TEXT, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER, INTEGER, TEXT, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER,INTEGER, TEXT, JSONB ) TO dbkasutaja;


/*
select  sum(alg_saldo) over() as alg,
        sum(deebet) over() as db,
        sum(kreedit) over() as kr,
*
FROM docs.kaibeandmik('2022-02-01', '2022-02-28':: DATE, 119,1,'%','{"konto":"","tunnus":""}'::jsonb)

select sum(summa) over(), * from cur_journal where kpv >= '2022-01-01' and (deebet like '8%' or kreedit like '8%')

-- 4915256.35
*/
