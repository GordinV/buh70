DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, INTEGER, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, TEXT);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER);

CREATE OR REPLACE FUNCTION docs.kaibeasutusandmik(l_konto TEXT, l_asutus INTEGER, l_kpv1 DATE, l_kpv2 DATE,
                                                  l_rekvid INTEGER, l_tunnus TEXT DEFAULT '%', l_kond INTEGER DEFAULT 0)
    RETURNS TABLE (
        alg_saldo NUMERIC(14, 2),
        deebet    NUMERIC(14, 2),
        kreedit   NUMERIC(14, 2),
        konto     VARCHAR(20),
        asutus_id INTEGER,
        rekv_id   INTEGER
    ) AS
$BODY$

SELECT sum(qry.alg_saldo)     AS alg_saldo,
       sum(qry.deebet)        AS deebet,
       sum(qry.kreedit)       AS kreedit,
       qry.konto::VARCHAR(20) AS konto,
       qry.asutus_id          AS asutus_id,
--       qry.rekv_id            AS rekv_id
       l_rekvid               AS rekv_id
FROM (
         SELECT D.rekvid                     AS rekv_id,
                j.asutusid                   AS asutus_id,
                (j1.summa)                   AS alg_saldo,
                0 :: NUMERIC(14, 2)          AS deebet,
                0 :: NUMERIC(14, 2)          AS kreedit,
                trim(j1.deebet)::VARCHAR(20) AS konto
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
         WHERE j.kpv < l_kpv1
           AND d.status <> 3
           AND j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND (empty(l_konto) OR j1.deebet LIKE ltrim(rtrim(l_konto)) || '%')
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND (j.rekvid = l_rekvid OR l_kond = 1)
           AND coalesce(j1.tunnus, '') ILIKE l_tunnus

         UNION ALL

         SELECT j.rekvid                      AS rekv_id,
                j.asutusid                    AS asutus_id,
                -1 * (j1.summa)               AS alg_saldo,
                0 :: NUMERIC                  AS deebet,
                0 :: NUMERIC                  AS kreedit,
                trim(j1.kreedit)::VARCHAR(20) AS konto
         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
         WHERE j.kpv < l_kpv1
           AND d.status <> 3
           AND j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND (empty(l_konto) OR j1.kreedit LIKE ltrim(rtrim(l_konto)) || '%')
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND (j.rekvid = l_rekvid OR l_kond = 1)
           AND coalesce(j1.tunnus, '') ILIKE l_tunnus

         UNION ALL

         SELECT j.rekvid            AS rekv_id,
                j.asutusid          AS asutus_id,
                0 :: NUMERIC(14, 2) AS alg_saldo,
                (j1.summa)          AS deebet,
                0 :: NUMERIC(14, 2) AS kreedit,
                trim(j1.deebet)     AS konto
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND d.status <> 3
           AND j.asutusid IS NOT NULL
           AND (empty(l_konto) OR j1.deebet LIKE ltrim(rtrim(l_konto)) || '%')
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND (j.rekvid = l_rekvid OR l_kond = 1)
           AND coalesce(j1.tunnus, '') ILIKE l_tunnus

         UNION ALL

         SELECT j.rekvid            AS rekv_id,
                j.asutusid          AS asutus_id,
                0 :: NUMERIC(14, 2) AS alg_saldo,
                0 :: NUMERIC        AS deebet,
                (j1.summa)          AS kreedit,
                trim(j1.kreedit)    AS konto
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND d.status <> 3
           AND j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND (empty(l_konto) OR j1.kreedit LIKE ltrim(rtrim(l_konto)) || '%')
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND (j.rekvid = l_rekvid OR l_kond = 1)
           AND coalesce(j1.tunnus, '') ILIKE l_tunnus
     ) qry
GROUP BY konto, asutus_id;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER ) TO dbkasutaja;


/*
SELECT *
FROM docs.kaibeasutusandmik('113',null,'2018-01-01', current_date :: DATE, 1)

*/