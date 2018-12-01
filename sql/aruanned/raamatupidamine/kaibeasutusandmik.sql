DROP FUNCTION IF EXISTS docs.kaibeasutusandmik( TEXT, INTEGER, INTEGER, DATE, DATE, INTEGER );
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik( TEXT, INTEGER,  DATE, DATE, INTEGER );

CREATE OR REPLACE FUNCTION docs.kaibeasutusandmik(l_konto TEXT, l_asutus INTEGER, l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
  RETURNS TABLE(alg_saldo NUMERIC(14, 2),
                deebet    NUMERIC(14, 2),
                kreedit   NUMERIC(14, 2),
                konto     VARCHAR(20),
                asutus_id INTEGER,
                rekv_id   INTEGER
  ) AS
$BODY$
WITH algsaldo AS (
    SELECT
      sum(deebet) - sum(kreedit) AS alg_saldo,
      konto,
      asutus_id                   AS asutus_id,
      rekv_id                     AS rekv_id
    FROM (
           SELECT
             D.rekvid            AS rekv_id,
             j.asutusid          AS asutus_id,
             (j1.summa)          AS deebet,
             0 :: NUMERIC(14, 2) AS kreedit,
             j1.deebet           AS konto
           FROM docs.doc d
             INNER JOIN docs.journal j ON j.parentid = d.id
             INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
           WHERE j.kpv < l_kpv1
                 AND j.asutusid IS NOT NULL
                 AND D.rekvid IN (SELECT rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid))
           UNION ALL
           SELECT
             j.rekvid     AS rekv_id,
             j.asutusid   AS asutus_id,
             0 :: NUMERIC AS deebet,
             (j1.summa)   AS kreedit,
             j1.kreedit   AS konto
           FROM docs.doc D
             INNER JOIN docs.journal j ON j.parentid = D.id
             INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
           WHERE j.kpv < l_kpv1
                 AND j.asutusid IS NOT NULL
                 AND D.rekvid IN (SELECT rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid))
         ) qry
    WHERE (empty(l_konto) OR qry.konto LIKE ltrim(rtrim(l_konto)) || '%')
          AND (empty(l_asutus) OR qry.asutus_id = l_asutus)
    GROUP BY konto, rekv_id, asutus_id)

SELECT
  sum(qry.alg_saldo) AS alg_saldo,
  sum(qry.deebet)    AS deebet,
  sum(qry.kreedit)   AS kreedit,
  qry.konto,
  qry.asutus_id       AS asutus_id,
  qry.rekv_id         AS rekv_id
FROM (
       SELECT
         algsaldo.rekv_id,
         algsaldo.asutus_id,
         algsaldo.alg_saldo,
         0 :: NUMERIC(14, 2) AS deebet,
         0 :: NUMERIC(14, 2) AS kreedit,
         algsaldo.konto
       FROM algsaldo
       UNION ALL
       SELECT
         j.rekvid            AS rekv_id,
         j.asutusid          AS asutus_id,
         0 :: NUMERIC(14, 2) AS alg_saldo,
         (j1.summa)          AS deebet,
         0 :: NUMERIC(14, 2) AS kreedit,
         j1.deebet           AS konto
       FROM docs.doc d
         INNER JOIN docs.journal j ON j.parentid = d.id
         INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
       WHERE j.kpv >= l_kpv1
             AND j.kpv <= l_kpv2
             AND j.asutusid IS NOT NULL
             AND j.rekvid IN (SELECT rekv_id
                              FROM get_asutuse_struktuur(l_rekvid))
       UNION ALL
       SELECT
         j.rekvid            AS rekv_id,
         j.asutusid          AS asutus_id,
         0 :: NUMERIC(14, 2) AS alg_saldo,
         0 :: NUMERIC        AS deebet,
         (j1.summa)          AS kreedit,
         j1.kreedit          AS konto
       FROM docs.doc d
         INNER JOIN docs.journal j ON j.parentid = d.id
         INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
       WHERE j.kpv >= l_kpv1
             AND j.kpv <= l_kpv2
             AND j.asutusid IS NOT NULL
             AND j.rekvid IN (SELECT rekv_id
                              FROM get_asutuse_struktuur(l_rekvid))
     ) qry
WHERE NOT empty(qry.konto)
      AND (empty(l_konto) OR qry.konto LIKE ltrim(rtrim(l_konto)) || '%')
      AND (empty(l_asutus) OR qry.asutus_id = l_asutus)
GROUP BY konto, rekv_id, asutus_id;
$BODY$
LANGUAGE SQL VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER,  DATE, DATE, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER,  DATE, DATE, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER,  DATE, DATE, INTEGER ) TO dbkasutaja;


/*
SELECT *
FROM docs.kaibeasutusandmik('113',null,'2018-01-01', current_date :: DATE, 1)

*/