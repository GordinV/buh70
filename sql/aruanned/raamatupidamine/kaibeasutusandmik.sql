DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, INTEGER, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, TEXT);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER);
DROP FUNCTION IF EXISTS docs.kaibeasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER, jsonb);

CREATE OR REPLACE FUNCTION docs.kaibeasutusandmik(l_konto TEXT, l_asutus INTEGER, l_kpv1 DATE, l_kpv2 DATE,
                                                  l_rekvid INTEGER, l_tunnus TEXT DEFAULT '%', l_kond INTEGER DEFAULT 0,
                                                  l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
        alg_saldo NUMERIC(14, 2),
        deebet    NUMERIC(14, 2),
        kreedit   NUMERIC(14, 2),
        konto     VARCHAR(20),
        asutus_id INTEGER,
        rekv_id   INTEGER
    )
AS
$BODY$

WITH params AS (
    SELECT l_params ->> 'proj'   AS proj,
           l_params ->> 'tunnus' AS tunnus,
           l_params ->> 'uritus' AS uritus
),
     rekv_ids AS (
         SELECT rekv_id
         FROM get_asutuse_struktuur(l_rekvid)
         WHERE rekv_id = CASE
                             WHEN l_kond = 1
                                 -- kond
                                 THEN rekv_id
                             ELSE l_rekvid END
     )
SELECT sum(qry.alg_saldo)     AS alg_saldo,
       sum(qry.deebet)        AS deebet,
       sum(qry.kreedit)       AS kreedit,
       qry.konto::VARCHAR(20) AS konto,
       qry.asutus_id          AS asutus_id,
--       qry.rekv_id            AS rekv_id
       l_rekvid               AS rekv_id
FROM (
         -- alg.db
         SELECT D.rekvid                                                                         AS rekv_id,
                CASE WHEN left(j1.deebet, 4) IN ('1001') THEN NULL ELSE j.asutusid END:: INTEGER AS asutus_id,
                (j1.summa)                                                                       AS alg_saldo,
                0 :: NUMERIC(14, 2)                                                              AS deebet,
                0 :: NUMERIC(14, 2)                                                              AS kreedit,
                trim(j1.deebet)::VARCHAR(20)                                                     AS konto
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
              params
         WHERE j.kpv < l_kpv1
           AND d.status <> 3
--           AND j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND (empty(l_konto) OR j1.deebet LIKE ltrim(rtrim(l_konto)) || '%')
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND coalesce(j1.tunnus, '') ILIKE l_tunnus
           -- V. B. 19.10.2022
           AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')

           -- поправка Калле 10.10.2022
           AND (year(j.kpv) = year(l_kpv1) OR
                ltrim(rtrim(j1.deebet)) IN (SELECT kood FROM com_kontoplaan WHERE tyyp IN (1, 2)))

         UNION ALL

         -- alg.kr
         SELECT j.rekvid                                                                          AS rekv_id,
                CASE WHEN left(j1.kreedit, 4) IN ('1001') THEN NULL ELSE j.asutusid END:: INTEGER AS asutus_id,
                -1 * (j1.summa)                                                                   AS alg_saldo,
                0 :: NUMERIC                                                                      AS deebet,
                0 :: NUMERIC                                                                      AS kreedit,
                trim(j1.kreedit)::VARCHAR(20)                                                     AS konto
         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
              params
         WHERE j.kpv < l_kpv1
           AND d.status <> 3
--           AND j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND (empty(l_konto) OR j1.kreedit LIKE ltrim(rtrim(l_konto)) || '%')
           AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
           -- V. B. 19.10.2022
           AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')

           AND coalesce(j1.tunnus, '') ILIKE l_tunnus
           -- поправка Калле 10.10.2022

           AND (year(j.kpv) = year(l_kpv1) OR
                ltrim(rtrim(j1.kreedit)) IN (SELECT kood FROM com_kontoplaan WHERE tyyp IN (1, 2)))

         UNION ALL
         -- db kaibed
         SELECT j.rekvid                                                                         AS rekv_id,
                CASE WHEN left(j1.deebet, 4) IN ('1001') THEN NULL ELSE j.asutusid END:: INTEGER AS asutus_id,
                0 :: NUMERIC(14, 2)                                                              AS alg_saldo,
                (j1.summa)                                                                       AS deebet,
                0 :: NUMERIC(14, 2)                                                              AS kreedit,
                trim(j1.deebet)                                                                  AS konto
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
              params
         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND d.status <> 3
--           AND j.asutusid IS NOT NULL
           AND (empty(l_konto) OR j1.deebet LIKE ltrim(rtrim(l_konto)) || '%')
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND coalesce(j1.tunnus, '') ILIKE l_tunnus
           -- V. B. 19.10.2022
           AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')

         UNION ALL
-- kr kaibed
         SELECT j.rekvid                                                                          AS rekv_id,
                CASE WHEN left(j1.kreedit, 4) IN ('1001') THEN NULL ELSE j.asutusid END:: INTEGER AS asutus_id,
                0 :: NUMERIC(14, 2)                                                               AS alg_saldo,
                0 :: NUMERIC                                                                      AS deebet,
                (j1.summa)                                                                        AS kreedit,
                trim(j1.kreedit)                                                                  AS konto
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
              params
         WHERE j.kpv >= l_kpv1
           AND j.kpv <= l_kpv2
           AND d.status <> 3
--           AND j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND (empty(l_konto) OR j1.kreedit LIKE ltrim(rtrim(l_konto)) || '%')
           AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')
           AND coalesce(j1.tunnus, '') ILIKE l_tunnus
     ) qry
GROUP BY konto, asutus_id;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER, jsonb ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER, jsonb ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kaibeasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, TEXT, INTEGER , jsonb) TO dbkasutaja;


/*
SELECT *
FROM docs.kaibeasutusandmik('201000',26901,'2022-01-01','2022-01-31', 3,'%',1)

-- 30.36,30.36

select * from libs.asutus where nimetus Ilike '%Infotark%'

select * from cur_journal where not empty(proj) order by id desc limit 10

-- proj 22065, 202000

select * from ou.rekv where id = 130



*/