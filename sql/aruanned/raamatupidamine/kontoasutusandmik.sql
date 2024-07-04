DROP FUNCTION IF EXISTS docs.kontoasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kontoasutusandmik(TEXT, INTEGER, DATE, DATE, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.kontoasutusandmik(l_konto TEXT, l_asutus INTEGER, l_kpv1 DATE, l_kpv2 DATE,
                                                   l_rekvid INTEGER, l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
        rekv_id    INTEGER,
        asutus_id  INTEGER,
        kpv        DATE,
        deebet     NUMERIC(14, 2),
        kreedit    NUMERIC(14, 2),
        konto      VARCHAR(20),
        korr_konto VARCHAR(20),
        dok        VARCHAR(120),
        number     INTEGER,
        kood1      VARCHAR(20),
        kood2      VARCHAR(20),
        kood3      VARCHAR(20),
        kood4      VARCHAR(20),
        kood5      VARCHAR(20),
        proj       VARCHAR(20),
        tunnus     VARCHAR(20),
        objekt     VARCHAR(20)
    )
AS
$BODY$
WITH docs_types AS (
    SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('JOURNAL')
),
     params AS (
         SELECT coalesce(l_params::JSONB ->> 'tunnus', '')::TEXT || '%'     AS tunnus,
                coalesce(l_params::JSONB ->> 'proj', '')::TEXT || '%'       AS proj,
                coalesce(l_params::JSONB ->> 'uritus', '')::TEXT || '%'     AS uritus,
                coalesce(l_params::JSONB ->> 'objekt', '')::TEXT || '%'     AS objekt,
                coalesce(l_params::JSONB ->> 'tegevus', '')::TEXT || '%'    AS tegevus,
                coalesce(ltrim(rtrim(l_konto)), '')::TEXT || '%'            AS konto,
                coalesce((l_params::JSONB ->> 'kond')::INTEGER, 0)::INTEGER AS kond,
                l_kpv1                                                      AS kpv_1,
                l_kpv2                                                      AS kpv_2,
                CASE WHEN empty(l_asutus) THEN 0 ELSE l_asutus END          AS asutus_1,
                CASE WHEN empty(l_asutus) THEN 999999 ELSE l_asutus END     AS asutus_2
     ),
     rekv_ids AS (
         SELECT rekv_id
         FROM get_asutuse_struktuur(l_rekvid),
              params p
         WHERE rekv_id = CASE
                             WHEN p.kond = 1
                                 -- kond
                                 THEN rekv_id
                             ELSE l_rekvid END
     ),
     algsaldo AS (
         SELECT qry.rekv_id,
                sum(qry.deebet) - sum(qry.kreedit) AS alg_saldo,
                qry.asutus_id,
                qry.konto
         FROM (
                  SELECT D.rekvid                  AS rekv_id,
                         asutusid                  AS asutus_id,
                         TRIM(deebet)::VARCHAR(20) AS konto,
                         summa                     AS deebet,
                         0 :: NUMERIC(14, 2)       AS kreedit,
                         coalesce(j1.kood1, '')    AS tegev,
                         coalesce(j1.proj, '')     AS proj,
                         coalesce(j1.tunnus, '')   AS tunnus,
                         coalesce(j1.kood4, '')    AS uritus,
                         coalesce(j1.objekt, '')   AS objekt
                  FROM docs.doc D
                           INNER JOIN docs.journal j ON j.parentid = D.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                       params p
                  WHERE j.asutusid IS NOT NULL
                    AND D.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND j.asutusid >= p.asutus_1
                    AND j.asutusid <= p.asutus_2
                    AND j.kpv < p.kpv_1
                    AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND (date_part('year', coalesce(a.kpv, j.kpv)) = date_part('year', p.kpv_1::DATE) OR
                         ltrim(rtrim(j1.deebet)) IN (SELECT kood FROM com_kontoplaan WHERE tyyp IN (1, 2)))
                    AND j1.deebet ILIKE p.konto
                    AND COALESCE(j1.tunnus, '') ILIKE p.tunnus
                    AND coalesce(j1.proj, '') ILIKE p.proj
                    AND coalesce(j1.kood4, '') ILIKE p.uritus
                    AND coalesce(j1.kood1, '') LIKE p.tegevus
                    AND coalesce(j1.objekt, '') ILIKE p.objekt
                  UNION ALL
                  SELECT D.rekvid                   AS rekv_id,
                         asutusid                   AS asutus_id,
                         TRIM(kreedit)::VARCHAR(20) AS konto,
                         0 :: NUMERIC(14, 2)        AS deebet,
                         summa                      AS kreedit,
                         coalesce(j1.kood1, '')     AS tegev,
                         coalesce(j1.proj, '')      AS proj,
                         coalesce(j1.tunnus, '')    AS tunnus,
                         coalesce(j1.kood4, '')     AS uritus,
                         coalesce(j1.objekt, '')    AS objekt

                  FROM docs.doc D
                           INNER JOIN docs.journal j ON j.parentid = D.id
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                       params p
                  WHERE j.asutusid IS NOT NULL
                    AND D.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND j.asutusid >= p.asutus_1
                    AND j.asutusid <= p.asutus_2
                    AND j.kpv < p.kpv_1
                    AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND (date_part('year', coalesce(a.kpv, j.kpv)) = date_part('year', p.kpv_1::DATE) OR
                         ltrim(rtrim(j1.kreedit)) IN (SELECT kood FROM com_kontoplaan WHERE tyyp IN (1, 2)))
                    AND j1.kreedit ILIKE p.konto
              ) qry,
              params p
         WHERE (empty(l_konto) OR qry.konto LIKE ltrim(rtrim(l_konto)) || '%')
           AND qry.proj ILIKE p.proj
           AND qry.tunnus ILIKE p.tunnus
           AND qry.uritus ILIKE p.uritus
           AND qry.objekt ILIKE p.objekt
           AND qry.tegev ILIKE p.tegevus
         GROUP BY qry.rekv_id, qry.asutus_id, qry.konto)
SELECT a.rekv_id,
       a.asutus_id,
       NULL::DATE           AS kpv,
       a.alg_saldo          AS deebet,
       0 :: NUMERIC(14, 2)  AS kreedit,
       a.konto,
       NULL :: VARCHAR(20)  AS korr_konto,
       NULL :: VARCHAR(120) AS dok,
       NULL :: INTEGER      AS number,
       NULL :: VARCHAR(20)  AS kood1,
       NULL :: VARCHAR(20)  AS kood2,
       NULL :: VARCHAR(20)  AS kood3,
       NULL :: VARCHAR(20)  AS kood4,
       NULL :: VARCHAR(20)  AS kood5,
       NULL :: VARCHAR(20)  AS proj,
       NULL :: VARCHAR(20)  AS tunnus,
       NULL :: VARCHAR(20)  AS objekt
FROM algsaldo a
UNION ALL
SELECT qry.rekv_id,
       qry.asutus_id,
       qry.kpv,
       qry.deebet                        AS deebet,
       qry.kreedit                       AS kreedit,
       trim(qry.konto)::VARCHAR(20)      AS konto,
       trim(qry.korr_konto)::VARCHAR(20) AS korr_konto,
       qry.dok,
       qry.number,
       qry.kood1,
       qry.kood2,
       qry.kood3,
       qry.kood4,
       qry.kood5,
       qry.proj,
       qry.tunnus,
       qry.objekt
FROM (
         SELECT j.rekvid                             AS rekv_id,
                j.kpv,
                j1.summa                             AS deebet,
                0 :: NUMERIC                         AS kreedit,
                j1.deebet                            AS konto,
                j1.kreedit                           AS korr_konto,
                j.dok,
                jid.number,
                j.asutusid                           AS asutus_id,
                coalesce(j1.kood1, '')::VARCHAR(20)  AS kood1,
                j1.kood2,
                j1.kood3,
                coalesce(j1.kood4, '')::VARCHAR(20)  AS kood4,
                j1.kood5,
                coalesce(j1.proj, '')::VARCHAR(20)   AS proj,
                coalesce(j1.tunnus, '')::VARCHAR(20) AS tunnus,
                coalesce(j1.objekt, '')::VARCHAR(20) AS objekt
         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journalid jid ON j.id = jid.journalid
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
              params p
         WHERE j.asutusid IS NOT NULL
           AND j.asutusid >= p.asutus_1
           AND j.asutusid <= p.asutus_2
           AND coalesce(a.kpv, j.kpv) >= p.kpv_1
           AND j.kpv <= p.kpv_2
           AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND j1.deebet ILIKE p.konto
         UNION ALL
         SELECT j.rekvid                             AS rekv_id,
                j.kpv,
                0 :: NUMERIC                         AS deebet,
                j1.summa                             AS kreedit,
                j1.kreedit                           AS konto,
                j1.deebet                            AS korr_konto,
                j.dok,
                jid.number,
                j.asutusid                           AS asutus_id,
                coalesce(j1.kood1, '')::VARCHAR(20)  AS kood1,
                j1.kood2,
                j1.kood3,
                coalesce(j1.kood4, '')::VARCHAR(20)  AS kood4,
                j1.kood5,
                coalesce(j1.proj, '')::VARCHAR(20)   AS proj,
                coalesce(j1.tunnus, '')::VARCHAR(20) AS tunnus,
                coalesce(j1.objekt, '')::VARCHAR(20) AS objekt
         FROM docs.doc D
                  INNER JOIN docs.journal j ON j.parentid = D.id
                  INNER JOIN docs.journalid jid ON j.id = jid.journalid
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
              params p
         WHERE j.asutusid IS NOT NULL
           AND j.asutusid >= p.asutus_1
           AND j.asutusid <= p.asutus_2
           AND coalesce(a.kpv, j.kpv) >= p.kpv_1
           AND j.kpv <= p.kpv_2
           AND j.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND j1.kreedit ILIKE p.konto
     ) qry,
     params p
WHERE qry.konto LIKE p.konto
  AND qry.proj ILIKE p.proj
  AND qry.tunnus ILIKE p.tunnus
  AND qry.kood4 ILIKE p.uritus
  AND qry.objekt ILIKE p.objekt
  AND qry.kood1 ILIKE p.tegevus

    ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kontoasutusandmik( TEXT, INTEGER, DATE, DATE, INTEGER, JSONB ) TO dbkasutaja;


/*
SELECT sum(deebet) OVER (), sum(kreedit) OVER (), *
FROM docs.kontoasutusandmik('201000'::TEXT, null :: INTEGER, '2024-01-31', '2024-01-31' :: DATE, 119, '{
  "konto": "%",
  "tegevus": "%",
  "proj": "%",
"objekt":"Voidu17b-17g",
"kond":0
}')
sum;sum
122490.76;752619.41
execution: 1 m 34 s 794 ms


SELECT k1.*
FROM docs.kontosaldoandmik_('201000'::text, 0,'20240101' :: DATE, 119,0) k1

*/