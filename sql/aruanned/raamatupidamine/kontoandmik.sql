DROP FUNCTION IF EXISTS docs.kontoandmik(DATE, DATE, INTEGER);
DROP FUNCTION IF EXISTS docs.kontoandmik(TEXT, DATE, DATE, INTEGER);

CREATE OR REPLACE FUNCTION docs.kontoandmik(l_konto TEXT, l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
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
    ) AS
$BODY$
WITH alg_kaibed AS (
    SELECT j.rekvid,
           sum(CASE
                   WHEN j.deebet::TEXT = l_konto
                       THEN j.summa
                   ELSE 0 :: NUMERIC(14, 2) END) -
           sum(CASE
                   WHEN j.kreedit::TEXT = l_konto
                       THEN j.summa
                   ELSE 0 :: NUMERIC(14, 2) END) AS alg_saldo
    FROM cur_journal j
    WHERE (j.deebet::TEXT = l_konto OR j.kreedit::TEXT = l_konto)
      AND kpv < l_kpv1
      AND j.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
    GROUP BY rekvid
)
SELECT coalesce(a.alg_saldo, 0)::NUMERIC(14, 2)                                                       AS alg_saldo,
       sum(coalesce(CASE WHEN j.deebet::TEXT = l_konto THEN summa ELSE 0 END, 0))
           OVER (PARTITION BY j.rekvid) ::NUMERIC(14, 2)                                              AS db_kokku,
       sum(coalesce(CASE WHEN j.kreedit::TEXT = l_konto THEN summa ELSE 0 END, 0))
           OVER (PARTITION BY j.rekvid)::NUMERIC(14, 2)                                               AS kr_kokku,
       coalesce(j.rekvid, a.rekvid)                                                                   AS rekv_id,
       coalesce(j.rekv_nimi, r.nimetus)::VARCHAR(254)                                                 AS rekv_nimi,
       coalesce(j.kpv, l_kpv1)                                                                        AS kpv,
       coalesce(CASE WHEN j.deebet::TEXT = l_konto THEN j.summa ELSE 0 END, 0)::NUMERIC(14, 2)        AS deebet,
       coalesce(CASE WHEN j.kreedit::TEXT = l_konto THEN j.summa ELSE 0 END, 0)::NUMERIC(14, 2)       AS kreedit,
       coalesce(CASE WHEN j.deebet::TEXT = l_konto THEN j.kreedit ELSE j.deebet END, '')::VARCHAR(20) AS konto,
       coalesce(dok, '')::VARCHAR(120)                                                                AS dok,
       coalesce(asutus, '')::VARCHAR(254)                                                             AS asutus,
       coalesce(number, 0)::INTEGER                                                                   AS number,
       coalesce(kood1, '')::VARCHAR(20),
       coalesce(kood2, '')::VARCHAR(20),
       coalesce(kood3, '')::VARCHAR(20),
       coalesce(kood4, '')::VARCHAR(20),
       coalesce(kood5, '')::VARCHAR(20),
       coalesce(proj, '')::VARCHAR(20),
       coalesce(tunnus, '')::VARCHAR(20),
       coalesce(selg, '')::TEXT                                                                       AS selg
FROM alg_kaibed a
         FULL OUTER JOIN
     (SELECT J.*, r.nimetus AS rekv_nimi
      FROM cur_journal j
               INNER JOIN ou.rekv r ON j.rekvid = r.id
      WHERE (j.deebet::TEXT = l_konto OR j.kreedit::TEXT = l_konto)
        AND kpv >= l_kpv1
        AND kpv <= l_kpv2
        AND j.rekvid IN (SELECT rekv_id
                         FROM get_asutuse_struktuur(l_rekvid))) j
     ON j.rekvid = a.rekvid
         LEFT OUTER JOIN ou.rekv r ON r.id = a.rekvid

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kontoandmik( TEXT, DATE, DATE, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kontoandmik( TEXT, DATE, DATE, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.kontoandmik( TEXT, DATE, DATE, INTEGER ) TO dbkasutaja;

/*
SELECT *
FROM docs.kontoandmik('100100', '2020-01-01', '2020-01-31' :: DATE, 3)

*/