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
WITH algsaldo AS (
    SELECT sum(deebet) - sum(kreedit) AS alg_saldo,
           konto,
           rekvid
    FROM (
             SELECT d.rekvid,
                    (j1.summa)                   AS deebet,
                    0 :: NUMERIC(14, 2)          AS kreedit,
                    trim(j1.deebet)::VARCHAR(20) AS konto
             FROM docs.doc d
                      INNER JOIN docs.journal j ON j.parentid = d.id
                      INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                 -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                      LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
             WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) < l_kpv1
               AND d.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND (d.rekvid = l_rekvid OR l_kond = 1)
               AND ((l_params ->> 'konto') IS NULL OR
                    coalesce(j1.deebet, '') LIKE coalesce((l_params ->> 'konto'), '') || '%')
               AND (((CASE WHEN left(j1.deebet, 1) IN ('1', '2') THEN l_params ELSE '{}'::JSONB END) ->>
                     'tunnus') IS NULL OR
                    COALESCE(j1.tunnus, '') ILIKE COALESCE((l_params ->> 'tunnus'), '') || '%')
               AND (((CASE WHEN left(j1.deebet, 1) IN ('1', '2') THEN l_params ELSE '{}'::JSONB END) ->>
                     'proj') IS NULL OR
                    COALESCE(j1.proj, '') ILIKE COALESCE((l_params ->> 'proj'), '') || '%')
               AND (((CASE WHEN left(j1.deebet, 1) IN ('1', '2') THEN l_params ELSE '{}'::JSONB END) ->>
                     'uritus') IS NULL OR
                    COALESCE(j1.kood4, '') ILIKE COALESCE((l_params ->> 'uritus'), '') || '%')
               AND d.status <> 3
             UNION ALL
             SELECT d.rekvid,
                    0 :: NUMERIC                  AS deebet,
                    (j1.summa)                    AS kreedit,
                    trim(j1.kreedit)::VARCHAR(20) AS konto
             FROM docs.doc d
                      INNER JOIN docs.journal j ON j.parentid = d.id
                      INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                 -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                      LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
             WHERE docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) < l_kpv1
               AND d.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND (d.rekvid = l_rekvid OR l_kond = 1)
               AND ((l_params ->> 'konto') IS NULL OR
                    coalesce(j1.kreedit, '') LIKE coalesce((l_params ->> 'konto'), '') || '%')
               AND (((CASE WHEN left(j1.kreedit, 1) IN ('1', '2') THEN l_params ELSE '{}'::JSONB END) ->>
                     'tunnus') IS NULL OR
                    COALESCE(j1.tunnus, '') ILIKE COALESCE((l_params ->> 'tunnus'), '') || '%')
               AND (((CASE WHEN left(j1.kreedit, 1) IN ('1', '2') THEN l_params ELSE '{}'::JSONB END) ->>
                     'proj') IS NULL OR
                    left(j1.kreedit, 1) IN ('1', '2') OR
                    coalesce(j1.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
               AND (((CASE WHEN left(j1.kreedit, 1) IN ('1', '2') THEN l_params ELSE '{}'::JSONB END) ->>
                     'uritus') IS NULL OR
                    left(j1.kreedit, 1) IN ('1', '2') OR
                    coalesce(j1.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')

               AND d.status <> 3
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
           AND d.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND (d.rekvid = l_rekvid OR l_kond = 1)
           AND d.status <> 3
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
           AND d.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND (d.rekvid = l_rekvid OR l_kond = 1)
           AND d.status <> 3
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
  AND left(konto, 2) NOT IN ('90', '91', '92', '93', '94', '95', '96', '97', '98')
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
select * from (
select *
FROM docs.kaibeandmik_('2022-01-01', current_date :: DATE, 28,0,null,'{"konto":"103100","tunnus":"12"}'::jsonb)
) qry
where konto like '10010007%'

'{"tunnus":"EEL","konto":"100"}'

*/