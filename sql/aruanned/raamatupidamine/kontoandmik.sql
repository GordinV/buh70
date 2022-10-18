DROP FUNCTION IF EXISTS docs.kontoandmik(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kontoandmik(TEXT, DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kontoandmik(TEXT, DATE, DATE, INTEGER, TEXT);
DROP FUNCTION IF EXISTS docs.kontoandmik(TEXT, DATE, DATE, INTEGER, TEXT, jsonb);

CREATE OR REPLACE FUNCTION docs.kontoandmik(l_konto TEXT, l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER,
                                            l_tunnus TEXT DEFAULT '%', l_params JSONB DEFAULT NULL::JSONB)
    RETURNS TABLE (
        alg_saldo NUMERIC(14, 2),
        db_kokku  NUMERIC(14, 2),
        kr_kokku  NUMERIC(14, 2),
        rekv_id   INTEGER,
        rekv_nimi VARCHAR(254),
        kpv       DATE,
        deebet    NUMERIC(14, 2),
        kreedit   NUMERIC(14, 2),
        konto     VARCHAR(20),
        dok       VARCHAR(120),
        asutus    VARCHAR(254),
        number    INTEGER,
        kood1     VARCHAR(20),
        kood2     VARCHAR(20),
        kood3     VARCHAR(20),
        kood4     VARCHAR(20),
        kood5     VARCHAR(20),
        proj      VARCHAR(20),
        tunnus    VARCHAR(20),
        selg      TEXT
    )
AS
$BODY$
WITH params AS (
    SELECT l_params ->> 'proj'                                  AS proj,
           l_params ->> 'tunnus'                                AS tunnus,
           l_params ->> 'uritus'                                AS uritus,
           coalesce((l_params ->> 'kond')::INTEGER, 0)::INTEGER AS kond
),
     alg_kaibed AS (
         SELECT j.rekvid,
                sum(CASE
                        WHEN ltrim(rtrim(j.deebet))::TEXT = ltrim(rtrim(l_konto))::TEXT
                            THEN j.summa
                        ELSE 0 :: NUMERIC(14, 2) END) -
                sum(CASE
                        WHEN ltrim(rtrim(j.kreedit))::TEXT = ltrim(rtrim(l_konto))::TEXT
                            THEN j.summa
                        ELSE 0 :: NUMERIC(14, 2) END) AS alg_saldo
         FROM cur_journal j
                  -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = j.id, params

         WHERE (ltrim(rtrim(j.deebet))::TEXT = ltrim(rtrim(l_konto))::TEXT OR
                ltrim(rtrim(j.kreedit))::TEXT = ltrim(rtrim(l_konto))::TEXT)
           AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) < l_kpv1
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN empty(params.kond) THEN l_rekvid ELSE j.rekvid END
           AND coalesce(j.tunnus, '') ILIKE trim(l_tunnus) || '%'
           AND (params.proj IS NULL OR coalesce(j.proj, '') ILIKE coalesce(params.proj, '') || '%')
           AND (params.tunnus IS NULL OR
                coalesce(j.tunnus, '') ILIKE coalesce(params.tunnus, '') || '%')
         GROUP BY rekvid
     )

SELECT coalesce(a.alg_saldo, 0)::NUMERIC(14, 2)                       AS alg_saldo,
       sum(coalesce(CASE WHEN j.deebet::TEXT = ltrim(rtrim(l_konto))::TEXT THEN summa ELSE 0 END, 0))
       OVER (PARTITION BY j.rekvid) ::NUMERIC(14, 2)                  AS db_kokku,
       sum(coalesce(CASE WHEN j.kreedit::TEXT = ltrim(rtrim(l_konto))::TEXT THEN summa ELSE 0 END, 0))
       OVER (PARTITION BY j.rekvid)::NUMERIC(14, 2)                   AS kr_kokku,
       coalesce(j.rekvid, a.rekvid)                                   AS rekv_id,
       coalesce(j.rekv_nimi, r.nimetus)::VARCHAR(254)                 AS rekv_nimi,
       coalesce(j.kpv, l_kpv1)                                        AS kpv,
       coalesce(CASE WHEN ltrim(rtrim(j.deebet))::TEXT = ltrim(rtrim(l_konto))::TEXT THEN j.summa ELSE 0 END,
                0)::NUMERIC(14, 2)                                    AS deebet,
       coalesce(CASE WHEN ltrim(rtrim(j.kreedit))::TEXT = ltrim(rtrim(l_konto))::TEXT THEN j.summa ELSE 0 END,
                0)::NUMERIC(14, 2)                                    AS kreedit,
       coalesce(CASE
                    WHEN ltrim(rtrim(j.deebet))::TEXT = ltrim(rtrim(l_konto))::TEXT THEN ltrim(rtrim(j.kreedit))
                    ELSE ltrim(rtrim(j.deebet)) END, '')::VARCHAR(20) AS konto,
       coalesce(dok, '')::VARCHAR(120)                                AS dok,
       coalesce(asutus, '')::VARCHAR(254)                             AS asutus,
       coalesce(number, 0)::INTEGER                                   AS number,
       coalesce(kood1, '')::VARCHAR(20),
       coalesce(kood2, '')::VARCHAR(20),
       coalesce(kood3, '')::VARCHAR(20),
       coalesce(kood4, '')::VARCHAR(20),
       coalesce(kood5, '')::VARCHAR(20),
       coalesce(proj, '')::VARCHAR(20),
       coalesce(tunnus, '')::VARCHAR(20),
       coalesce(selg, '')::TEXT                                       AS selg
FROM alg_kaibed a
         FULL OUTER JOIN
     (
         SELECT coalesce(a.kpv, j.kpv) AS kpv,
                J.id,
                j.rekvid,
                j.asutus,
                j.dok,
                j.number,
                j.selg,
                j.summa,
                j.deebet,
                j.kreedit,
                j.kood1,
                j.kood2,
                j.kood3,
                j.kood4,
                j.kood5,
                j.proj,
                j.tunnus,
                r.nimetus              AS rekv_nimi
         FROM cur_journal j
                  INNER JOIN ou.rekv r ON j.rekvid = r.id
             -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                  LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = j.id,
              params
         WHERE (ltrim(rtrim(j.deebet))::TEXT = ltrim(rtrim(l_konto))::TEXT OR
                ltrim(rtrim(j.kreedit))::TEXT = ltrim(rtrim(l_konto))::TEXT)
           AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) >= l_kpv1
           AND docs.get_alg_saldo_kpv(a.kpv, j.kpv, l_kpv1, l_kpv2) <= l_kpv2
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN empty(params.kond) THEN l_rekvid ELSE j.rekvid END

           AND coalesce(j.tunnus, '') ILIKE trim(coalesce(l_tunnus, '')) || '%'
           AND (params.proj IS NULL OR coalesce(j.proj, '') ILIKE coalesce(params.proj, '') || '%')
           AND (params.tunnus IS NULL OR
                coalesce(j.tunnus, '') ILIKE coalesce(params.tunnus, '') || '%')
     ) j
     ON j.rekvid = a.rekvid
         INNER JOIN ou.rekv r ON r.id = coalesce(a.rekvid, j.rekvid)

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kontoandmik( TEXT, DATE, DATE, INTEGER, TEXT, JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kontoandmik( TEXT, DATE, DATE, INTEGER, TEXT, JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kontoandmik( TEXT, DATE, DATE, INTEGER, TEXT, JSONB ) TO dbkasutaja;

/*
select sum(deebet), sum(kreedit) from (
SELECT qry.*, l.nimetus,
                        (qry.alg_saldo + db_kokku - kr_kokku) as lopp_saldo
                        FROM docs.kontoandmik_('100100'::text, '2022-01-01'::date, '2022-01-31'::date, 3::integer, '%','{"kond":1}'::jsonb) qry
                        inner join com_kontoplaan l on l.kood = qry.konto

                        ) qry
where rekv_id = 3
*/
259
128499.72,111459.57

128499.72,111459.57


16307.4,14493.02
