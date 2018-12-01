DROP FUNCTION IF EXISTS docs.pearaamat(TEXT, INTEGER, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.pearaamat(TEXT, DATE, DATE, INTEGER);

CREATE OR REPLACE FUNCTION docs.pearaamat(l_konto TEXT, l_kpv1 DATE, l_kpv2 DATE,
                                          l_rekvid INTEGER)
  RETURNS TABLE(
    rekv_id INTEGER,
    deebet NUMERIC(14, 2),
    kreedit NUMERIC(14, 2),
    konto VARCHAR(20),
    korr_konto VARCHAR(20)

    ) AS
$BODY$
WITH algsaldo AS (
  SELECT
      coalesce(sum(deebet), 0) - coalesce(sum(kreedit), 0) :: NUMERIC(12, 2) AS alg_saldo,
      konto,
      rekv_id                                                                AS rekv_id
  FROM (
         SELECT
           D.rekvid            AS rekv_id,
           (j1.summa)          AS deebet,
           0 :: NUMERIC(14, 2) AS kreedit,
           j1.deebet           AS konto
         FROM docs.doc d
                INNER JOIN docs.journal j ON j.parentid = d.id
                INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
         WHERE j.kpv < l_kpv1
           AND D.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
         UNION ALL
         SELECT
           D.rekvid     AS rekv_id,
           0 :: NUMERIC AS deebet,
           (j1.summa)   AS kreedit,
           j1.kreedit   AS konto
         FROM docs.doc D
                INNER JOIN docs.journal j ON j.parentid = D.id
                INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
         WHERE j.kpv < l_kpv1
           AND D.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
       ) qry
  WHERE (empty(l_konto) OR qry.konto LIKE ltrim(rtrim(l_konto)) || '%')
  GROUP BY konto, rekv_id)
     -- kaibed
SELECT
  rekv_id,
  sum(deebet)  AS deebet,
  sum(kreedit) AS kreedit,
  konto,
  korr_konto
FROM (
       SELECT
         a.rekv_id,
         a.konto,
         NULL :: VARCHAR(20) AS korr_konto,
         a.alg_saldo         AS deebet,
         0 :: NUMERIC(14, 2) AS kreedit
       FROM algsaldo a
       UNION ALL
       SELECT
         d.rekvid   AS rekv_id,
         j1.deebet  AS konto,
         j1.kreedit AS korr_konto,
         (j1.summa) AS deebet,
         0          AS kreedit
       FROM docs.doc d
              INNER JOIN docs.journal j ON j.parentid = d.id
              INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
       WHERE j.kpv >= l_kpv1
         AND j.kpv <= l_kpv2
         AND D.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))

       UNION ALL
       SELECT
         d.rekvid   AS rekv_id,
         j1.kreedit AS konto,
         j1.deebet  AS korr_konto,
         0          AS deebet,
         (j1.summa) AS kreedit
       FROM docs.doc d
              INNER JOIN docs.journal j ON j.parentid = d.id
              INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
       WHERE j.kpv >= l_kpv1
         AND j.kpv <= l_kpv2
         AND D.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
     ) qry
WHERE (empty(l_konto) OR qry.konto LIKE ltrim(rtrim(l_konto)) || '%')
GROUP BY rekv_id, konto, korr_konto;
$BODY$
  LANGUAGE SQL
  VOLATILE
  COST 100;


GRANT EXECUTE ON FUNCTION docs.pearaamat( TEXT, DATE, DATE, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.pearaamat( TEXT, DATE, DATE, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.pearaamat( TEXT, DATE, DATE, INTEGER ) TO dbkasutaja;

/*
SELECT *
FROM docs.pearaamat('113','2018-01-01', current_date :: DATE, 1)

*/