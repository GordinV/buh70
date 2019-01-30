DROP FUNCTION IF EXISTS docs.saldoandmik(DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.saldoandmik(TEXT, INTEGER, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kontosaldoandmik(TEXT, INTEGER, DATE, INTEGER);

CREATE OR REPLACE FUNCTION docs.kontosaldoandmik(l_konto TEXT, l_asutus INTEGER, l_kpv DATE, l_rekvid INTEGER)
  RETURNS TABLE(saldo NUMERIC(14, 2),
    konto VARCHAR(20),
    rekv_id INTEGER,
    asutus_id INTEGER
    ) AS
$BODY$
SELECT
  sum(deebet) - sum(kreedit) AS saldo,
  konto,
  rekvid                     AS rekv_id,
  asutusid                   AS asutus_id
FROM (
       SELECT
         d.rekvid,
         (j1.summa)                   AS deebet,
         0 :: NUMERIC(14, 2)          AS kreedit,
         trim(j1.deebet)::VARCHAR(20) AS konto,
         j.asutusid
       FROM docs.doc d
              INNER JOIN docs.journal j ON j.parentid = d.id
              INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
       WHERE j.kpv <= l_kpv
         AND j.asutusid IS NOT NULL
         AND (empty(l_asutus) OR j.asutusid = l_asutus)
         AND d.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
       UNION ALL
       SELECT
         d.rekvid,
         0 :: NUMERIC                  AS deebet,
         (j1.summa)                    AS kreedit,
         trim(j1.kreedit)::VARCHAR(20) AS konto,
         j.asutusid
       FROM docs.doc d
              INNER JOIN docs.journal j ON j.parentid = d.id
              INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
       WHERE j.kpv <= l_kpv
         AND j.asutusid IS NOT NULL
         AND (empty(l_asutus) OR j.asutusid = l_asutus)
         AND d.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
     ) qry
WHERE NOT empty(konto)
  AND konto LIKE coalesce(ltrim(rtrim(l_konto)), '') || '%'
GROUP BY konto, asutusid, rekvid;
$BODY$
  LANGUAGE SQL
  VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION docs.kontosaldoandmik( TEXT, INTEGER, DATE, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kontosaldoandmik( TEXT, INTEGER, DATE, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kontosaldoandmik( TEXT, INTEGER, DATE, INTEGER ) TO dbkasutaja;


/*
SELECT *
FROM docs.kontosaldoandmik('201000'::text, 23096,'20181231' :: DATE, 64)


select * from libs.asutus where REGKOOD ilike '10160868%'
*/