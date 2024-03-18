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
     params AS (
         SELECT coalesce(l_params::JSONB ->> 'konto', '')::TEXT || '%'  AS konto,
                coalesce(l_params::JSONB ->> 'tunnus', '')::TEXT || '%' AS tunnus,
                coalesce(l_params::JSONB ->> 'proj', '')::TEXT || '%'   AS proj,
                coalesce(l_params::JSONB ->> 'uritus', '')::TEXT || '%' AS uritus,
                l_kpv1                                                  AS kpv_1,
                l_kpv2                                                  AS kpv_2
     ),

     docs_types AS (
         SELECT id, kood
         FROM libs.library
         WHERE library.library = 'DOK'
           AND kood IN ('JOURNAL')
     ),
     alg_docs AS (
         SELECT d.rekvid,
                -- уберем нач. сальдо для групп 8 и 9 с прошлых лет
                (j1.summa)                                                                                AS summa,
                j1.deebet                                                                                 AS deebet,
                j1.kreedit                                                                                AS kreedit,
                j1.tunnus,
                j1.kood4,
                j1.proj,
                docs.get_alg_saldo_kpv(a.kpv, j.kpv, make_date(year(params.kpv_1), 01, 01), params.kpv_2) AS kpv
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
              params
         WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, make_date(year(params.kpv_1), 01, 01), params.kpv_2) < params.kpv_1
           AND d.status < 3
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND d.doc_type_id = 57 -- проводки
           AND (j1.deebet LIKE params.konto || '%' OR j1.kreedit LIKE params.konto || '%')
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
                                 WHEN date_part('year', d.kpv) < date_part('year', l_kpv1) AND
                                      lpad(d.deebet, 1) IN ('8', '9') THEN 0
                                 ELSE 1 END * d.summa) AS deebet,
                         0 :: NUMERIC(14, 2)           AS kreedit,
                         trim(d.deebet)::VARCHAR(20)   AS konto
                  FROM alg_docs d
                  WHERE d.kpv < make_date(year(l_kpv1), 01, 01)
                    AND (((CASE
                               WHEN left(d.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'tunnus') IS NULL OR
                         COALESCE(d.tunnus, '') ILIKE COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                    AND (((CASE
                               WHEN left(d.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'proj') IS NULL OR
                         COALESCE(d.proj, '') ILIKE COALESCE((l_params::JSONB ->> 'proj'), '') || '%')
                    AND (((CASE
                               WHEN left(d.deebet, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'uritus') IS NULL OR
                         COALESCE(d.kood4, '') ILIKE COALESCE((l_params::JSONB ->> 'uritus'), '') || '%')
                  GROUP BY d.deebet, d.rekvid
                  UNION ALL
                  -- >= 2022-01-01
                  SELECT d.rekvid,
                         sum(d.summa)                AS deebet,
                         0 :: NUMERIC(14, 2)         AS kreedit,
                         trim(d.deebet)::VARCHAR(20) AS konto
                  FROM alg_docs d
                  WHERE d.kpv >= make_date(year(l_kpv1), 01, 01)
                    AND d.kpv < l_kpv1
/*                    AND ((l_params::JSONB ->> 'konto') IS NULL OR
                         coalesce(d.deebet, '') LIKE coalesce((l_params::JSONB ->> 'konto'), '') || '%')
*/
                    AND (l_params::JSONB ->> 'tunnus' IS NULL OR
                         COALESCE(d.tunnus, '') ILIKE COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                    AND (l_params::JSONB ->> 'proj' IS NULL OR
                         COALESCE(d.proj, '') ILIKE COALESCE((l_params::JSONB ->> 'proj'), '') || '%')
                    AND (l_params::JSONB ->> 'uritus' IS NULL OR
                         COALESCE(d.kood4, '') ILIKE COALESCE((l_params::JSONB ->> 'uritus'), '') || '%')
                  GROUP BY d.deebet, d.rekvid
                  UNION ALL
                  -- < 2022-01-01
                  SELECT d.rekvid,
                         0 :: NUMERIC                  AS deebet,
                         sum(CASE
                                 WHEN date_part('year', d.kpv) < date_part('year', l_kpv1) AND
                                      lpad(d.kreedit, 1) IN ('8', '9') THEN 0
                                 ELSE 1 END * d.summa) AS kreedit,
                         trim(d.kreedit)::VARCHAR(20)  AS konto
                  FROM alg_docs d
                  WHERE d.kpv < make_date(year(l_kpv1), 01, 01)
/*                    AND ((l_params::JSONB ->> 'konto') IS NULL OR
                         coalesce(d.kreedit, '') LIKE coalesce((l_params::JSONB ->> 'konto'), '') || '%')
*/
                    AND (((CASE
                               WHEN left(d.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'tunnus') IS NULL OR
                         COALESCE(d.tunnus, '') ILIKE COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                    AND (((CASE
                               WHEN left(d.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'proj') IS NULL OR
                         coalesce(d.proj, '') ILIKE coalesce((l_params::JSONB ->> 'proj'), '') || '%')
                    AND (((CASE
                               WHEN left(d.kreedit, 1) IN ('1', '2') THEN l_params::JSONB
                               ELSE '{}'::JSONB END) ->>
                          'uritus') IS NULL OR
                         left(d.kreedit, 1) IN ('1', '2') OR
                         coalesce(d.kood4, '') ILIKE coalesce((l_params::JSONB ->> 'uritus'), '') || '%')
                  GROUP BY d.kreedit, d.rekvid
                  UNION ALL
                  -- >= 2022-01-01
                  SELECT d.rekvid,
                         0 :: NUMERIC                 AS deebet,
                         sum(d.summa)                 AS kreedit,
                         trim(d.kreedit)::VARCHAR(20) AS konto
                  FROM alg_docs d
                  WHERE d.kpv >= make_date(year(l_kpv1), 01, 01)
                    AND d.kpv < l_kpv1
/*                    AND ((l_params::JSONB ->> 'konto') IS NULL OR
                         coalesce(d.kreedit, '') LIKE coalesce((l_params::JSONB ->> 'konto'), '') || '%')
*/
                    AND ((l_params::JSONB ->> 'tunnus') IS NULL OR
                         COALESCE(d.tunnus, '') ILIKE COALESCE((l_params::JSONB ->> 'tunnus'), '') || '%')
                    AND ((l_params::JSONB ->>
                          'proj') IS NULL OR
                         coalesce(d.proj, '') ILIKE coalesce((l_params::JSONB ->> 'proj'), '') || '%')
                    AND ((l_params::JSONB ->>
                          'uritus') IS NULL OR
                         coalesce(d.kood4, '') ILIKE coalesce((l_params::JSONB ->> 'uritus'), '') || '%')
                  GROUP BY d.kreedit, d.rekvid
              ) qry
         GROUP BY konto,
                  rekvid)

SELECT sum(qry.alg_saldo) AS alg_saldo,
       sum(qry.deebet)    AS deebet,
       sum(qry.kreedit)   AS kreedit,
       qry.konto
FROM (
         WITH docs AS (
             SELECT d.rekvid,
                    0 :: NUMERIC(14, 2)          AS alg_saldo,
                    sum(j1.summa)                AS deebet,
                    0 :: NUMERIC(14, 2)          AS kreedit,
                    trim(j1.deebet)::VARCHAR(20) AS konto,
                    j1.proj,
                    j1.tunnus,
                    j1.kood4
             FROM docs.doc d
                      INNER JOIN docs.journal j ON j.parentid = d.id
                      INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                 -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                      LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                  params
             WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, params.kpv_1, params.kpv_2) >= params.kpv_1
               AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, params.kpv_1, params.kpv_2) <= params.kpv_2
               AND d.status < 3
               AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
               AND d.doc_type_id = 57 -- проводки
               AND j1.deebet LIKE params.konto
             GROUP BY d.rekvid, j1.deebet, j1.proj, j1.tunnus, j1.kood4
             UNION ALL
             SELECT d.rekvid,
                    0 :: NUMERIC(14, 2)           AS alg_saldo,
                    0 :: NUMERIC                  AS deebet,
                    sum(j1.summa)                 AS kreedit,
                    trim(j1.kreedit)::VARCHAR(20) AS konto,
                    j1.proj,
                    j1.tunnus,
                    j1.kood4

             FROM docs.doc d
                      INNER JOIN docs.journal j ON j.parentid = d.id
                      INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                 -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                      LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                  params
             WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, params.kpv_1, params.kpv_2) >= params.kpv_1
               AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, params.kpv_1, params.kpv_2) <= params.kpv_2
               AND d.status < 3
               AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
               AND d.doc_type_id = 57 -- проводки
               AND j1.kreedit LIKE params.konto
             GROUP BY d.rekvid, j1.kreedit, j1.proj, j1.tunnus, j1.kood4
         )

         SELECT algsaldo.rekvid,
                algsaldo.alg_saldo,
                0 :: NUMERIC(14, 2) AS deebet,
                0 :: NUMERIC(14, 2) AS kreedit,
                algsaldo.konto
         FROM algsaldo
         UNION ALL
         -- обороты
         SELECT d.rekvid,
                0 :: NUMERIC(14, 2)  AS alg_saldo,
                (d.deebet)           AS deebet,
                0 :: NUMERIC(14, 2)  AS kreedit,
                d.konto::VARCHAR(20) AS konto
         FROM docs d
         WHERE coalesce(d.tunnus, '') ILIKE coalesce(l_tunnus, '%')
           AND (l_params ->> 'tunnus' IS NULL OR
                coalesce(d.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus'), '') || '%')
           AND ((l_params ->> 'proj') IS NULL OR coalesce(d.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
           AND ((l_params ->> 'uritus') IS NULL OR
                coalesce(d.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')

         UNION ALL
         SELECT d.rekvid,
                0 :: NUMERIC(14, 2)  AS alg_saldo,
                0 :: NUMERIC         AS deebet,
                (d.kreedit)          AS kreedit,
                d.konto::VARCHAR(20) AS konto
         FROM docs d
         WHERE coalesce(d.tunnus, '') ILIKE coalesce(l_tunnus, '%')
           AND (l_params ->> 'tunnus' IS NULL OR
                coalesce(d.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus'), '') || '%')
           AND ((l_params ->> 'proj') IS NULL OR coalesce(d.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
           AND ((l_params ->> 'uritus') IS NULL OR
                coalesce(d.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')
     ) qry, params
WHERE NOT empty(qry.konto)
  --AND left(konto, 2) NOT IN ('90', '91', '92', '93', '94', '95', '96', '97', '98')
  AND left(qry.konto, 1) NOT IN ('8', '9', '0')
  AND qry.konto NOT IN (SELECT kood
                        FROM com_kontoplaan
                        WHERE kas_virtual > 0)
  AND qry.konto LIKE params.konto
GROUP BY qry.konto;
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
FROM docs.kaibeandmik('2024-01-01':: DATE, '2024-01-31':: DATE, 63,0,'%','{"konto":"100100","tunnus":""}'::jsonb)

_ '2023-01-01':: DATE, '2023-01-31'
alg;db;kr
0;53747440.9;53747440.9
571 rows retrieved starting from 1 in 1 m 17 s 347 ms (execution: 1 m 17 s 274 ms, fetching: 73 ms)

kb
alg;db;kr
0;53747440.9;53747440.9
571 rows retrieved starting from 1 in 7 m 31 s 430 ms (execution: 7 m 31 s 373 ms, fetching: 57 ms)

*/
