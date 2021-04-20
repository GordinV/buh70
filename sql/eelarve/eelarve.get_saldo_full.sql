DROP FUNCTION IF EXISTS eelarve.get_saldo_full(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER, formula TEXT,
    l_konto TEXT,
    rv TEXT, l_tegevus TEXT);

CREATE OR REPLACE FUNCTION eelarve.get_saldo_full(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER, formula TEXT,
                                                  l_konto TEXT,
                                                  rv TEXT, l_tegevus TEXT)
    RETURNS NUMERIC
AS
$$
WITH tmp_andmik AS (
    SELECT tegev,
           konto,
           rahavoo,
           nimetus,
           sum(CASE WHEN db = 0 THEN (kr - db) ELSE (db - kr) END) AS saldoandmik,
           sum(db)                                                 AS db,
           sum(kr)                                                 AS kr,
           year(l_kpv)                                             AS aasta,
           month(l_kpv)                                            AS kuu
    FROM eelarve.saldoandmik
    WHERE aasta = year(l_kpv)
      AND kuu = month(l_kpv)
      AND rekvid = (CASE
                        WHEN l_kond = 1 AND
                             (CASE WHEN l_rekvid = 63 AND coalesce(l_kond, 0) = 1 THEN 999 ELSE l_rekvid END) = 63
                            THEN 999
                        WHEN l_kond = 1 AND
                             (CASE WHEN l_rekvid = 63 AND coalesce(l_kond, 0) = 1 THEN 999 ELSE l_rekvid END) <> 63
                            THEN rekvid
                        ELSE (CASE WHEN l_rekvid = 63 AND coalesce(l_kond, 0) = 1 THEN 999 ELSE l_rekvid END) END)
      AND rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(
                                  (CASE WHEN l_rekvid = 63 AND coalesce(l_kond, 0) = 1 THEN 999 ELSE l_rekvid END))
                     UNION ALL
                     SELECT CASE
                                WHEN (CASE WHEN l_rekvid = 63 AND coalesce(l_kond, 0) = 1 THEN 999 ELSE l_rekvid END) =
                                     63 THEN 999
                                ELSE (CASE
                                          WHEN l_rekvid = 63 AND coalesce(l_kond, 0) = 1 THEN 999
                                          ELSE l_rekvid END) END AS rekv_id
    )
      AND (l_konto IS NULL OR konto LIKE trim(l_konto::TEXT || '%'))
    GROUP BY tegev
           , konto
           , rahavoo
           , nimetus

    UNION ALL
    -- eelmise periodi andmed
    SELECT tegev,
           l_konto,
           rahavoo,
           nimetus,
           sum(CASE WHEN db = 0 THEN (kr - db) ELSE (db - kr) END) AS saldoandmik,
           sum(db)                                                 AS db,
           sum(kr)                                                 AS kr,
           year(l_kpv) - 1                                         AS aasta, -- year(($1 - interval '3 month')::date),
           12                                                      AS kuu    --month(($1 - interval '3 month')::date)
    FROM eelarve.saldoandmik
    WHERE aasta = year(l_kpv) - 1 --year(($1 - interval '3 month')::date)
      AND kuu = 12                -- month(($1 - interval '3 month')::date)
      AND rekvid = (CASE
                        WHEN l_kond = 1 AND l_rekvid = 63
                            THEN 999
                        WHEN l_kond = 1 AND l_rekvid <> 63 THEN rekvid
                        ELSE l_rekvid END)
      AND rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid)
                     UNION ALL
                     SELECT CASE WHEN l_rekvid = 63 THEN 999 ELSE l_rekvid END AS rekv_id
    )
      AND (l_konto IS NULL OR konto LIKE trim(l_konto::TEXT || '%'))

    GROUP BY tegev
           , allikas
           , konto
           , rahavoo
           , nimetus
)
SELECT coalesce((SELECT sum(CASE
                                WHEN formula LIKE '%KD' THEN (kr - db)
                                WHEN formula LIKE '%DK' THEN (db - kr)
                                ELSE saldoandmik END)
                 FROM tmp_andmik s,
                      (SELECT min(aasta) AS eelmine_aasta, max(aasta) AS aasta, min(kuu) AS eelmine_kuu, max(kuu) AS kuu
                       FROM tmp_andmik) aasta
                 WHERE s.aasta = CASE WHEN left(formula, 1) = 'M' THEN aasta.eelmine_aasta ELSE aasta.aasta END
                   AND (l_konto IS NULL OR s.konto LIKE trim(l_konto::TEXT || '%'))
                   AND (rv IS NULL OR trim(s.rahavoo) = rv)
                   AND (l_tegevus IS NULL OR trim(s.tegev) = l_tegevus)), 0);
$$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.get_saldo_full(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER, formula TEXT, konto TEXT,
    rv TEXT, tegevus TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.get_saldo_full(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER, formula TEXT, konto TEXT,
    rv TEXT, tegevus TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.get_saldo_full(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER, formula TEXT, konto TEXT,
    rv TEXT, tegevus TEXT) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.get_saldo_full(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER, formula TEXT, konto TEXT,
    rv TEXT, tegevus TEXT) TO dbvaatleja;

/*
select eelarve.get_saldo_full('2021-03-31'::DATE, 63::INTEGER, 1::INTEGER, 'MDK', '100',
    NULL::TEXT, NULL::TEXT)
 */

