/*DROP FUNCTION IF EXISTS docs.kontoandmik_(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kontoandmik_(TEXT, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kontoandmik_(TEXT, DATE, DATE, INTEGER, TEXT);
DROP FUNCTION IF EXISTS docs.kontoandmik_(TEXT, DATE, DATE, INTEGER, TEXT, JSONB);
*/
DROP FUNCTION IF EXISTS docs.kontoandmik(TEXT, DATE, DATE, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.kontoandmik(l_konto TEXT, l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                             l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
        alg_saldo  NUMERIC(14, 2),
        db_kokku   NUMERIC(14, 2),
        kr_kokku   NUMERIC(14, 2),
        rekv_id    INTEGER,
        rekv_nimi  VARCHAR(254),
        kpv        DATE,
        deebet     NUMERIC(14, 2),
        kreedit    NUMERIC(14, 2),
        konto      VARCHAR(20),
        korr_konto VARCHAR(20),
        dok        VARCHAR(120),
        asutus     VARCHAR(254),
        number     INTEGER,
        kood1      VARCHAR(20),
        kood2      VARCHAR(20),
        kood3      VARCHAR(20),
        kood4      VARCHAR(20),
        kood5      VARCHAR(20),
        proj       VARCHAR(20),
        tunnus     VARCHAR(20),
        selg       TEXT
    )
AS
$BODY$
WITH params AS (
    SELECT ltrim(rtrim(coalesce(l_params ->> 'proj', ''))) || '%'   AS proj,
           ltrim(rtrim(coalesce(l_params ->> 'tunnus', ''))) || '%' AS tunnus,
           ltrim(rtrim(coalesce(l_params ->> 'uritus', ''))) || '%' AS uritus,
           coalesce((l_params ->> 'kond')::INTEGER, 0)::INTEGER     AS kond,
           l_kpv1                                                   AS kpv1,
           l_kpv2                                                   AS kpv2,
           ltrim(rtrim(coalesce(l_konto, ''))) || '%'               AS konto,
           l_rekvid                                                 AS rekvid
),
     rekv_ids AS (
         SELECT rekv_id
         FROM params,
              get_asutuse_struktuur(l_rekvid)
         WHERE rekv_id = CASE
                             WHEN params.kond = 1
                                 -- kond
                                 THEN rekv_id
                             ELSE params.rekvid END),
     dok_tyyp AS (SELECT id FROM libs.library WHERE library = 'DOK' AND kood = 'JOURNAL' AND status < 3),

     alg_kaibed AS (
         SELECT j.rekvid,
                j.konto,
                sum(summa) AS alg_saldo
         FROM (
                  SELECT d.id      AS id,
                         j.kpv     AS kpv,
                         j.rekvId,
                         ltrim(rtrim(j1.deebet)) AS konto,
                         j1.tunnus,
                         j1.proj,
                         j1.summa
                  FROM params,
                       docs.doc D
                           INNER JOIN docs.journal j ON D.id = j.parentid
                           INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  WHERE D.status < 3
                    AND d.doc_type_id IN (SELECT id FROM dok_tyyp)
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND (ltrim(rtrim(j1.deebet))::TEXT LIKE params.konto::TEXT)

                    -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                    AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, params.kpv1, params.kpv2) < params.kpv1
                    AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')
                    AND (params.tunnus IS NULL OR
                         coalesce(j1.tunnus, '') ILIKE coalesce(params.tunnus, '') || '%')
                  UNION ALL
                  SELECT d.id       AS id,
                         j.kpv      AS kpv,
                         j.rekvId,
                         ltrim(rtrim(j1.kreedit)) AS konto,
                         j1.tunnus,
                         j1.proj,
                         -1 * j1.summa
                  FROM params,
                       docs.doc D
                           INNER JOIN docs.journal j ON D.id = j.parentid
                           INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  WHERE D.status < 3
                    AND d.doc_type_id IN (SELECT id FROM dok_tyyp)
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND (ltrim(rtrim(j1.kreedit))::TEXT LIKE params.konto::TEXT)

                    -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                    AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, params.kpv1, params.kpv2) < params.kpv1
                    AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')
                    AND (params.tunnus IS NULL OR
                         coalesce(j1.tunnus, '') ILIKE coalesce(params.tunnus, '') || '%')
              ) j
         GROUP BY j.rekvid, konto
     ),
     db_kaibed AS (
         SELECT d.id                                                           AS id,
                coalesce(alg.kpv, j.kpv)                                       AS kpv,
                jid.number,
                j.rekvId,
                j.asutusid,
                coalesce(regexp_replace(j.selg, '"', '`'), '') :: VARCHAR(254) AS selg,
                COALESCE(j.dok, '') :: VARCHAR(50)                             AS dok,
                ltrim(rtrim(j1.deebet))                                                      AS konto,
                ltrim(rtrim(j1.kreedit))                                                     AS korr_konto,
                j1.summa                                                       AS summa,
                COALESCE(j1.kood1, '') :: VARCHAR(20)                          AS kood1,
                COALESCE(j1.kood2, '') :: VARCHAR(20)                          AS kood2,
                COALESCE(j1.kood3, '') :: VARCHAR(20)                          AS kood3,
                COALESCE(j1.kood4, '') :: VARCHAR(20)                          AS kood4,
                COALESCE(j1.kood5, '') :: VARCHAR(20)                          AS kood5,
                COALESCE(j1.proj, '') :: VARCHAR(20)                           AS proj,
                COALESCE(ltrim(rtrim(a.nimetus)) || ' ' || ltrim(rtrim(a.omvorm)),
                         '') :: VARCHAR(120)                                   AS asutus,
                COALESCE(j1.tunnus, '') :: VARCHAR(20)                         AS tunnus
         FROM params,
              docs.journal j
                  INNER JOIN docs.doc D ON D.id = j.parentid
                  INNER JOIN docs.journalid jid ON j.id = jid.journalid
                  INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                  LEFT JOIN libs.asutus a ON a.id = j.asutusid
                  -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id
         WHERE D.status < 3
           AND d.doc_type_id IN (SELECT id FROM dok_tyyp)
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND ltrim(rtrim(j1.deebet))::TEXT LIKE params.konto::TEXT
           AND docs.get_alg_saldo_kpv(alg.kpv, j.kpv, params.kpv1, params.kpv2) >= params.kpv1
           AND docs.get_alg_saldo_kpv(alg.kpv, j.kpv, params.kpv1, params.kpv2) <= params.kpv2
           AND coalesce(j1.tunnus, '') ILIKE trim(coalesce(params.tunnus, '')) || '%'
           AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')
           AND (params.tunnus IS NULL OR
                coalesce(j1.tunnus, '') ILIKE coalesce(params.tunnus, '') || '%')
     ),
     kr_kaibed AS (
         SELECT d.id                                                           AS id,
                coalesce(alg.kpv, j.kpv)                                       AS kpv,
                jid.number,
                j.rekvId,
                j.asutusid,
                coalesce(regexp_replace(j.selg, '"', '`'), '') :: VARCHAR(254) AS selg,
                COALESCE(j.dok, '') :: VARCHAR(50)                             AS dok,
                ltrim(rtrim(j1.deebet))                                                      AS korr_konto,
                ltrim(rtrim(j1.kreedit))                                                     AS konto,
                j1.summa                                                       AS summa,
                COALESCE(j1.kood1, '') :: VARCHAR(20)                          AS kood1,
                COALESCE(j1.kood2, '') :: VARCHAR(20)                          AS kood2,
                COALESCE(j1.kood3, '') :: VARCHAR(20)                          AS kood3,
                COALESCE(j1.kood4, '') :: VARCHAR(20)                          AS kood4,
                COALESCE(j1.kood5, '') :: VARCHAR(20)                          AS kood5,
                COALESCE(j1.proj, '') :: VARCHAR(20)                           AS proj,
                COALESCE(ltrim(rtrim(a.nimetus)) || ' ' || ltrim(rtrim(a.omvorm)),
                         '') :: VARCHAR(120)                                   AS asutus,
                COALESCE(j1.tunnus, '') :: VARCHAR(20)                         AS tunnus
         FROM params,
              docs.journal j
                  INNER JOIN docs.doc D ON D.id = j.parentid
                  INNER JOIN docs.journalid jid ON j.id = jid.journalid
                  INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                  LEFT JOIN libs.asutus a ON a.id = j.asutusid
                  -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id
         WHERE D.status < 3
           AND d.doc_type_id IN (SELECT id FROM dok_tyyp)
           AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
           AND ltrim(rtrim(j1.kreedit))::TEXT LIKE params.konto::TEXT
           AND docs.get_alg_saldo_kpv(alg.kpv, j.kpv, params.kpv1, params.kpv2) >= params.kpv1
           AND docs.get_alg_saldo_kpv(alg.kpv, j.kpv, params.kpv1, params.kpv2) <= params.kpv2
           AND coalesce(j1.tunnus, '') ILIKE trim(coalesce(params.tunnus, '')) || '%'
           AND (params.proj IS NULL OR coalesce(j1.proj, '') ILIKE coalesce(params.proj, '') || '%')
           AND (params.tunnus IS NULL OR
                coalesce(j1.tunnus, '') ILIKE coalesce(params.tunnus, '') || '%')
     )

SELECT coalesce(a.alg_saldo, 0)::NUMERIC(14, 2)                         AS alg_saldo,
       sum(j.db) OVER (PARTITION BY j.rekvid, j.konto) ::NUMERIC(14, 2) AS db_kokku,
       sum(j.kr) OVER (PARTITION BY j.rekvid, j.konto) ::NUMERIC(14, 2) AS kr_kokku,
       coalesce(j.rekvid, a.rekvid)                                     AS rekv_id,
       coalesce(j.rekv_nimi, r.nimetus)::VARCHAR(254)                   AS rekv_nimi,
       coalesce(j.kpv, params.kpv1)                                     AS kpv,
       coalesce(j.db, 0)::NUMERIC(14, 2)                                AS deebet,
       coalesce(j.kr)::NUMERIC(14, 2)                                   AS kreedit,
       j.konto::VARCHAR(20)                                             AS konto,
       j.korr_konto::VARCHAR(20)                                        AS korr_konto,
       coalesce(j.dok, '')::VARCHAR(120)                                AS dok,
       coalesce(j.asutus, '')::VARCHAR(254)                             AS asutus,
       coalesce(j.number, 0)::INTEGER                                   AS number,
       coalesce(j.kood1, '')::VARCHAR(20),
       coalesce(j.kood2, '')::VARCHAR(20),
       coalesce(j.kood3, '')::VARCHAR(20),
       coalesce(j.kood4, '')::VARCHAR(20),
       coalesce(j.kood5, '')::VARCHAR(20),
       coalesce(j.proj, '')::VARCHAR(20),
       coalesce(j.tunnus, '')::VARCHAR(20),
       coalesce(j.selg, '')::TEXT                                       AS selg
FROM alg_kaibed a
         FULL OUTER JOIN
     (
         WITH kaibed AS (
             SELECT j.id      AS id,
                    j.kpv     AS kpv,
                    j.number,
                    j.rekvId,
                    j.asutusid,
                    j.selg    AS selg,
                    j.dok     AS dok,
                    j.konto,
                    j.korr_konto,
                    j.summa   AS db,
                    0         AS kr,
                    j.kood1   AS kood1,
                    j.kood2   AS kood2,
                    j.kood3   AS kood3,
                    j.kood4   AS kood4,
                    j.kood5   AS kood5,
                    j.proj    AS proj,
                    j.asutus  AS asutus,
                    j.tunnus  AS tunnus,
                    r.nimetus AS rekv_nimi
             FROM db_kaibed j
                      INNER JOIN ou.rekv r ON r.id = j.rekvid
             UNION ALL
             SELECT j.id      AS id,
                    j.kpv     AS kpv,
                    j.number,
                    j.rekvId,
                    j.asutusid,
                    j.selg    AS selg,
                    j.dok     AS dok,
                    j.konto,
                    j.korr_konto,
                    0         AS db,
                    j.summa   AS kr,
                    j.kood1   AS kood1,
                    j.kood2   AS kood2,
                    j.kood3   AS kood3,
                    j.kood4   AS kood4,
                    j.kood5   AS kood5,
                    j.proj    AS proj,
                    j.asutus  AS asutus,
                    j.tunnus  AS tunnus,
                    r.nimetus AS rekv_nimi
             FROM kr_kaibed j
                      INNER JOIN ou.rekv r ON r.id = j.rekvid
         )
         SELECT *
         FROM kaibed
         UNION ALL
         SELECT 0         AS id,
                l_kpv1    AS kpv,
                NULL      AS number,
                l_rekvid  AS rekvId,
                NULL      AS asutusid,
                ''        AS selg,
                ''        AS dok,
                a.konto   AS konto,
                ''        AS korr_konto,
                0         AS db,
                0         AS kr,
                ''        AS kood1,
                ''        AS kood2,
                ''        AS kood3,
                ''        AS kood4,
                ''        AS kood5,
                ''        AS proj,
                ''        AS asutus,
                ''        AS tunnus,
                r.nimetus AS rekv_nimi
         FROM ou.rekv r,
              alg_kaibed a
         WHERE r.id = l_rekvid
           AND NOT exists(SELECT id FROM kaibed)
     ) j
     ON j.rekvid = a.rekvid AND a.konto = j.konto
         INNER JOIN ou.rekv r ON r.id = coalesce(a.rekvid, j.rekvid),
     params

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kontoandmik( TEXT, DATE, DATE, INTEGER, JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kontoandmik( TEXT, DATE, DATE, INTEGER, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kontoandmik( TEXT, DATE, DATE, INTEGER, JSONB ) TO dbkasutaja;

/*
select sum(deebet), sum(kreedit) from (
SELECT qry.*, l.nimetus,
                        (qry.alg_saldo + db_kokku - kr_kokku) as lopp_saldo
                        FROM docs.kontoandmik_('10000002'::text, '2023-04-15'::date, '2023-04-16'::date, 28::integer, '{"kond":1}'::jsonb) qry
                        inner join com_kontoplaan l on l.kood = qry.konto

                        ) qry
where rekv_id = 28
*//*

SELECT qry.*,
       l.nimetus,
       (qry.alg_saldo + db_kokku - kr_kokku) AS lopp_saldo
FROM docs.kontoandmik('100100'::TEXT, '2023-03-01'::DATE, '2023-03-31'::DATE, 28::INTEGER, '%', '{
  "kond": 1
}'::JSONB) qry
         INNER JOIN com_kontoplaan l ON l.kood = qry.konto
    alg_saldo;
db_kokku;
kr_kokku
2724948.69;
2324136.18;
1781483.34
*/