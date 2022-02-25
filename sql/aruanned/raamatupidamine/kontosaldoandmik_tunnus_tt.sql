DROP FUNCTION IF EXISTS docs.kontosaldoandmik_tunnus_tt(TEXT, INTEGER, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kontosaldoandmik_tunnus_tt(TEXT, INTEGER, DATE, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.kontosaldoandmik_tunnus_tt(l_konto TEXT, l_asutus INTEGER, l_kpv DATE, l_rekvid INTEGER,
                                                           l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
        saldo     NUMERIC(14, 2),
        konto     VARCHAR(20),
        tegev     VARCHAR(20),
        tunnus    VARCHAR(20),
        rekv_id   INTEGER,
        asutus_id INTEGER
    )
AS
$BODY$
SELECT sum(deebet) - sum(kreedit) AS saldo,
       konto,
       tegev,
       tunnus,
       rekvid                     AS rekv_id,
       asutusid                   AS asutus_id
FROM (
         SELECT d.rekvid,
                (j1.summa)                   AS deebet,
                0 :: NUMERIC(14, 2)          AS kreedit,
                trim(j1.deebet)::VARCHAR(20) AS konto,
                trim(j1.tunnus)::VARCHAR(20) AS tunnus,
                trim(j1.kood1)::VARCHAR(20)  AS tegev,
                j.asutusid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
         WHERE j.kpv <= coalesce(l_kpv, current_date)
           AND j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND d.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND d.status <> 3
           AND ((l_params ->> 'tunnus') IS NULL OR
                coalesce(j1.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus'), '') || '%')
           AND ((l_params ->> 'konto') IS NULL OR
                coalesce(j1.deebet, '') ILIKE coalesce((l_params ->> 'konto'), '') || '%')
           AND ((l_params ->> 'proj') IS NULL OR coalesce(j1.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
           AND ((l_params ->> 'uritus') IS NULL OR
                coalesce(j1.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')
           AND ((l_params ->> 'tegevus') IS NULL OR
                coalesce(j1.kood1, '') ILIKE coalesce((l_params ->> 'tegevus'), '') || '%')

         UNION ALL
         SELECT d.rekvid,
                0 :: NUMERIC                  AS deebet,
                (j1.summa)                    AS kreedit,
                trim(j1.kreedit)::VARCHAR(20) AS konto,
                trim(j1.tunnus)::VARCHAR(20)  AS tunnus,
                trim(j1.kood1)::VARCHAR(20)   AS tegev,
                j.asutusid
         FROM docs.doc d
                  INNER JOIN docs.journal j ON j.parentid = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
         WHERE j.kpv <= coalesce(l_kpv, current_date)
           AND j.asutusid IS NOT NULL
           AND (empty(l_asutus) OR j.asutusid = l_asutus)
           AND d.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND d.status <> 3
           AND ((l_params ->> 'tunnus') IS NULL OR
                coalesce(j1.tunnus, '') ILIKE trim(coalesce((l_params ->> 'tunnus'), '')) || '%')
           AND ((l_params ->> 'konto') IS NULL OR
                coalesce(j1.kreedit, '') ILIKE coalesce((l_params ->> 'konto'), '') || '%')
           AND ((l_params ->> 'proj') IS NULL OR coalesce(j1.proj, '') ILIKE coalesce((l_params ->> 'proj'), '') || '%')
           AND ((l_params ->> 'uritus') IS NULL OR
                coalesce(j1.kood4, '') ILIKE coalesce((l_params ->> 'uritus'), '') || '%')
           AND ((l_params ->> 'tegevus') IS NULL OR
                coalesce(j1.kood1, '') ILIKE coalesce((l_params ->> 'tegevus'), '') || '%')
     ) qry
WHERE NOT empty(konto)
  AND konto LIKE coalesce(ltrim(rtrim(l_konto)), '') || '%'
GROUP BY konto, tunnus, tegev, asutusid, rekvid;
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kontosaldoandmik_tunnus_tt( TEXT, INTEGER, DATE, INTEGER, JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kontosaldoandmik_tunnus_tt( TEXT, INTEGER, DATE, INTEGER, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kontosaldoandmik_tunnus_tt( TEXT, INTEGER, DATE, INTEGER, JSONB ) TO dbkasutaja;


/*
SELECT *
FROM docs.kontosaldoandmik_tunnus_tt('201000'::text, 2178,'2022-02-21' :: DATE, 28,'{"tunnus":"1."}')


select * from libs.asutus where REGKOOD ilike '10160868%'
*/