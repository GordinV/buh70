DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER, INTEGER, TEXT);

CREATE OR REPLACE FUNCTION docs.kaibeandmik(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER DEFAULT 0,
                                            l_tunnus TEXT DEFAULT '%')
    RETURNS TABLE (
        alg_saldo NUMERIC(14, 2),
        deebet    NUMERIC(14, 2),
        kreedit   NUMERIC(14, 2),
        konto     VARCHAR(20)
    ) AS
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
               AND coalesce(j1.tunnus, '') ILIKE l_tunnus
               and d.status <> 3
             UNION ALL
             SELECT d.rekvid
                     ,
                    0 :: NUMERIC                  AS deebet
                     ,
                    (j1.summa)                    AS kreedit
                     ,
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
               AND coalesce(j1.tunnus, '') ILIKE l_tunnus
               and d.status <> 3
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
           and d.status <> 3
           AND coalesce(j1.tunnus, '') ILIKE l_tunnus
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
           and d.status <> 3
           AND coalesce(j1.tunnus, '') ILIKE l_tunnus
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

GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER,INTEGER , TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER, INTEGER, TEXT ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER,INTEGER, TEXT ) TO dbkasutaja;


/*
select * from (
select *
FROM docs.kaibeandmik('2020-01-01', current_date :: DATE, 63)
) qry
where konto like '100%'
and rekv_id = 63
*/