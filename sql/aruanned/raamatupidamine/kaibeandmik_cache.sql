DROP FUNCTION IF EXISTS docs.kaibeandmik_(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeandmik_(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeandmik_(DATE, DATE, INTEGER, INTEGER, TEXT);
DROP FUNCTION IF EXISTS docs.kaibeandmik_(DATE, DATE, INTEGER, INTEGER, TEXT, JSONB);


CREATE OR REPLACE FUNCTION docs.kaibeandmik_(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER DEFAULT 0,
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

     last_doc AS (
         SELECT max(lastupdate) AS timestamp
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id,
              params p
         WHERE d.status < 3
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND d.doc_type_id = 57 -- проводки
           AND j.kpv < p.kpv_1
     ),
     last_cache AS (
         SELECT max(d.lopp_kpv) AS lopp_kpv
         FROM cache_kaibeandmik d,
              params p,
              last_doc
         WHERE d.lopp_kpv < p.kpv_1
           AND rekv_id = l_rekvid
           AND d.timestamp > last_doc.timestamp
           AND empty(p.proj)
           AND empty(p.tunnus)
           AND empty(p.uritus)
           AND FALSE
     ),
     alg_docs AS (
         SELECT d.rekvid,
                -- уберем нач. сальдо для групп 8 и 9 с прошлых лет
                sum(j1.summa)                                     AS summa,
                j1.deebet                                         AS deebet,
                j1.kreedit                                        AS kreedit,
                j1.tunnus,
                j1.kood4,
                j1.proj,
                CASE
                    WHEN docs.get_alg_saldo_kpv(a.kpv, j.kpv, make_date(year(params.kpv_1), 01, 01), params.kpv_2) <
                         make_date(year(params.kpv_1), 01, 01) THEN make_date(year(params.kpv_1), 01, 01)
                    ELSE docs.get_alg_saldo_kpv(a.kpv, j.kpv, make_date(year(params.kpv_1), 01, 01),
                                                params.kpv_2) END AS kpv
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
              params,
              last_cache
         WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, make_date(year(params.kpv_1), 01, 01), params.kpv_2) < params.kpv_1
           AND d.status < 3
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND d.doc_type_id = 57 -- проводки
           AND d.status <> 3
           AND j.kpv > coalesce(last_cache.lopp_kpv, '2020-01-01'::DATE)
           AND (j1.deebet LIKE params.konto || '%' OR j1.kreedit LIKE params.konto || '%')
         GROUP BY d.rekvid, j1.deebet, j1.kreedit, j1.tunnus, j1.kood4, j1.proj, CASE
                                                                                     WHEN docs.get_alg_saldo_kpv(a.kpv,
                                                                                                                 j.kpv,
                                                                                                                 make_date(year(params.kpv_1), 01, 01),
                                                                                                                 params.kpv_2) <
                                                                                          make_date(year(params.kpv_1), 01, 01)
                                                                                         THEN make_date(year(params.kpv_1), 01, 01)
                                                                                     ELSE docs.get_alg_saldo_kpv(a.kpv,
                                                                                                                 j.kpv,
                                                                                                                 make_date(year(params.kpv_1), 01, 01),
                                                                                                                 params.kpv_2) END
     ),
     algsaldo AS (
         SELECT sum(deebet) - sum(kreedit) AS alg_saldo,
                konto,
                rekvid
         FROM (
-- ищем в кеше
                  SELECT d.rekv_id                            AS rekvid,
                         (d.alg_saldo + d.deebet - d.kreedit) AS deebet, -- считаем конечное сальдо
                         0                                    AS kreedit,
                         d.konto
                  FROM cache_kaibeandmik d,
                       params p,
                       last_doc
                  WHERE d.lopp_kpv < p.kpv_1
                    AND d.konto LIKE p.konto || '%' -- взяли готовые обороты
                    AND d.rekv_id IN (SELECT rekv_id FROM rekv_ids)
                    AND d.timestamp > last_doc.timestamp
                    AND empty(p.proj)
                    AND empty(p.tunnus)
                    AND empty(p.uritus)
                  UNION ALL
                  SELECT d.rekvid,
                         -- уберем нач. сальдо для групп 8 и 9 с прошлых лет
                         sum(CASE
                                 WHEN date_part('year', d.kpv) < date_part('year', params.kpv_1) AND
                                      lpad(d.deebet, 1) IN ('8', '9') THEN 0
                                 ELSE 1 END * d.summa) AS deebet,
                         0 :: NUMERIC(14, 2)           AS kreedit,
                         trim(d.deebet)::VARCHAR(20)   AS konto
                  FROM alg_docs d,
                       params
                  WHERE d.kpv < make_date(year(params.kpv_1), 01, 01)
                    AND left(d.deebet, 1) IN ('1', '2')
                    AND d.deebet LIKE params.konto || '%'
                    AND COALESCE(d.tunnus, '') ILIKE params.tunnus
                    AND COALESCE(d.proj, '') ILIKE params.proj
                    AND COALESCE(d.kood4, '') ILIKE params.uritus
                  GROUP BY d.deebet, d.rekvid
                  UNION ALL
                  SELECT d.rekvid,
                         -- уберем нач. сальдо для групп 8 и 9 с прошлых лет
                         sum(CASE
                                 WHEN date_part('year', d.kpv) < date_part('year', params.kpv_1) AND
                                      lpad(d.deebet, 1) IN ('8', '9') THEN 0
                                 ELSE 1 END * d.summa) AS deebet,
                         0 :: NUMERIC(14, 2)           AS kreedit,
                         trim(d.deebet)::VARCHAR(20)   AS konto
                  FROM alg_docs d,
                       params
                  WHERE d.kpv < make_date(year(params.kpv_1), 01, 01)
                    AND left(d.deebet, 1) NOT IN ('1', '2')
                    AND d.deebet LIKE params.konto || '%'
                  GROUP BY d.deebet, d.rekvid

                  UNION ALL
                  -- >= 2022-01-01
                  SELECT d.rekvid,
                         sum(CASE
                                 WHEN date_part('year', d.kpv) < date_part('year', params.kpv_1) AND
                                      lpad(d.deebet, 1) IN ('8', '9') THEN 0
                                 ELSE 1 END * d.summa) AS deebet,
                         0 :: NUMERIC(14, 2)           AS kreedit,
                         trim(d.deebet)::VARCHAR(20)   AS konto
                  FROM alg_docs d,
                       params
                  WHERE d.kpv >= make_date(year(params.kpv_1), 01, 01)
                    AND d.kpv < params.kpv_1
                    AND d.deebet LIKE params.konto || '%'
                    AND COALESCE(d.tunnus, '') ILIKE params.tunnus
                    AND COALESCE(d.proj, '') ILIKE params.proj
                    AND COALESCE(d.kood4, '') ILIKE params.uritus
                  GROUP BY d.deebet, d.rekvid
                  UNION ALL
                  -- < 2022-01-01
                  SELECT d.rekvid,
                         0 :: NUMERIC                  AS deebet,
                         sum(CASE
                                 WHEN date_part('year', d.kpv) < date_part('year', params.kpv_1) AND
                                      lpad(d.kreedit, 1) IN ('8', '9') THEN 0
                                 ELSE 1 END * d.summa) AS kreedit,
                         trim(d.kreedit)::VARCHAR(20)  AS konto
                  FROM alg_docs d,
                       params
                  WHERE d.kpv < make_date(year(params.kpv_1), 01, 01)
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND left(d.kreedit, 1) IN ('1', '2')
                    AND d.kreedit LIKE params.konto || '%'
                    AND COALESCE(d.tunnus, '') ILIKE params.tunnus
                    AND coalesce(d.proj, '') ILIKE params.proj
                    AND coalesce(d.kood4, '') ILIKE params.uritus

                  GROUP BY d.kreedit, d.rekvid
                  UNION ALL
                  -- < 2022-01-01
                  SELECT d.rekvid,
                         0 :: NUMERIC                  AS deebet,
                         sum(CASE
                                 WHEN date_part('year', d.kpv) < date_part('year', params.kpv_1) AND
                                      lpad(d.kreedit, 1) IN ('8', '9') THEN 0
                                 ELSE 1 END * d.summa) AS kreedit,
                         trim(d.kreedit)::VARCHAR(20)  AS konto
                  FROM alg_docs d,
                       params
                  WHERE d.kpv < make_date(year(params.kpv_1), 01, 01)
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND left(d.kreedit, 1) NOT IN ('1', '2')
                    AND d.kreedit LIKE params.konto || '%'
                  GROUP BY d.kreedit, d.rekvid
                  UNION ALL
                  -- >= 2022-01-01
                  SELECT d.rekvid,
                         0 :: NUMERIC                 AS deebet,
                         sum(d.summa)                 AS kreedit,
                         trim(d.kreedit)::VARCHAR(20) AS konto
                  FROM alg_docs d,
                       params
                  WHERE d.kpv >= make_date(year(params.kpv_1), 01, 01)
                    AND d.kpv < params.kpv_1
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.kreedit LIKE params.konto || '%'
                    AND COALESCE(d.tunnus, '') ILIKE params.tunnus
                    AND coalesce(d.proj, '') ILIKE params.proj
                    AND coalesce(d.kood4, '') ILIKE params.uritus

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
                    (j1.summa)                   AS deebet,
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
             UNION ALL
             SELECT d.rekvid,
                    0 :: NUMERIC(14, 2)           AS alg_saldo,
                    0 :: NUMERIC                  AS deebet,
                    (j1.summa)                    AS kreedit,
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
         )

         SELECT algsaldo.rekvid,
                sum(algsaldo.alg_saldo) AS alg_saldo,
                0 :: NUMERIC(14, 2)     AS deebet,
                0 :: NUMERIC(14, 2)     AS kreedit,
                algsaldo.konto
         FROM algsaldo
         GROUP BY rekvid, konto
         UNION ALL
         SELECT d.rekvid,
                0 :: NUMERIC(14, 2)              AS alg_saldo,
                sum(d.deebet)                    AS deebet,
                sum(d.kreedit) :: NUMERIC(14, 2) AS kreedit,
                trim(d.konto)::VARCHAR(20)       AS konto
         FROM docs d,
              params
         WHERE coalesce(d.tunnus, '') ILIKE params.tunnus
           AND (coalesce(d.proj, '')) ILIKE params.proj
           AND coalesce(d.kood4, '') ILIKE params.uritus
         GROUP BY d.rekvid, d.konto
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

GRANT EXECUTE ON FUNCTION docs.kaibeandmik_( DATE, DATE, INTEGER,INTEGER , TEXT, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik_( DATE, DATE, INTEGER, INTEGER, TEXT, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik_( DATE, DATE, INTEGER,INTEGER, TEXT, JSONB ) TO dbkasutaja;


/*
select  sum(alg_saldo) over() as alg,
        sum(deebet) over() as db,
        sum(kreedit) over() as kr,
*
FROM docs.kaibeandmik_('2024-01-01', '2024-01-31':: DATE, 63,1,'%','{"konto":"","tunnus":""}'::jsonb)

select sum(summa) over(), * from cur_journal where kpv >= '2022-01-01' and (deebet like '8%' or kreedit like '8%')

alg;db;kr
3118865.08;133669.91;133669.91
(execution: 2 m 37 s 101 ms, fetching: 60 ms

alg;db;kr
3118865.08;133669.91;133669.91
execution: 7 m 12 s 788 ms, fetching: 56 ms


12/2023
alg;db;kr
3118865.08;236438.01;236438.01
115 rows retrieved starting from 1 in 2 m 39 s 392 ms (execution: 2 m 39 s 341 ms, fetching: 51 ms)
115 rows retrieved starting from 1 in 2 m 36 s 582 ms (execution: 2 m 36 s 538 ms, fetching: 44 ms)

alg;db;kr
3118865.08;236438.01;236438.01
execution: 7 m 18 s 438 ms, fetching: 46 ms

'2023-12-01', '2023-12-31'
alg;db;kr
0;115340864.75;115340864.75
 591 rows retrieved starting from 1 in 1 m 19 s 17 ms (execution: 1 m 18 s 982 ms, fetching: 35 ms)

'2023-01-01', '2023-12-31'
completed in 1 m 23 s 816 ms
alg;db;kr
0;1113486588.15;1113486588.15
529

alg;db;kr
0;1113486588.15;1113486588.15

-- kb
'2024-01-01', '2024-01-31':
alg;db;kr
0;65022130.92;65022130.92
601 rows retrieved starting from 1 in 7 m 35 s 241 ms (execution: 7 m 35 s 155 ms, fetching: 86 ms)

kb_
alg;db;kr
0;65022822.83;65022822.83
329 rows retrieved starting from 1 in 1 m 15 s 34 ms (execution: 1 m 14 s 988 ms, fetching: 46 ms)
*/
