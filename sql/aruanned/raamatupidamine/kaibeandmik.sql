DROP FUNCTION IF EXISTS docs.kaibeandmik(DATE, DATE, INTEGER);

CREATE OR REPLACE FUNCTION docs.kaibeandmik(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
    RETURNS TABLE (
        alg_saldo NUMERIC(14, 2),
        deebet    NUMERIC(14, 2),
        kreedit   NUMERIC(14, 2),
        konto     VARCHAR(20),
        rekv_id   INTEGER,
        rekv_nimi VARCHAR(254)
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

             WHERE coalesce(a.kpv, j.kpv) < l_kpv1
               AND d.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
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
             WHERE coalesce(a.kpv, j.kpv) < l_kpv1
               AND d.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
         ) qry
    GROUP BY konto, rekvid)

SELECT sum(qry.alg_saldo)      AS alg_saldo,
       sum(qry.deebet)         AS deebet,
       sum(qry.kreedit)        AS kreedit,
       qry.konto,
       qry.rekvid              AS rekv_id,
       r.nimetus::VARCHAR(254) AS rekv_nimi
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

         WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
           AND coalesce(a.kpv, j.kpv) <= l_kpv2
           AND d.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
         UNION ALL
         SELECT d.rekvid
                 ,
                0 :: NUMERIC(14, 2)           AS alg_saldo
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
         WHERE coalesce(a.kpv, j.kpv) >= l_kpv1
           AND coalesce(a.kpv, j.kpv) <= l_kpv2
           AND d.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
     ) qry
         INNER JOIN ou.rekv r ON r.id = qry.rekvid

WHERE NOT empty(qry.konto)
  AND left(konto, 2) NOT IN ('90', '91', '92', '93', '94', '95', '96', '97', '98')
GROUP BY konto, rekvid, r.nimetus;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kaibeandmik( DATE, DATE, INTEGER ) TO dbkasutaja;


/*
select * from (
select *
FROM docs.kaibeandmik('2020-01-01', current_date :: DATE, 63)
) qry
where konto like '100%'
and rekv_id = 63
*/