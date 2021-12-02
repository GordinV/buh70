DROP FUNCTION IF EXISTS get_saldo(konto TEXT, rv TEXT);
DROP FUNCTION IF EXISTS get_saldo(formula TEXT, konto TEXT, rv TEXT);
DROP FUNCTION IF EXISTS get_saldo(formula TEXT, konto TEXT, rv TEXT, tegev TEXT);
DROP FUNCTION IF EXISTS get_saldo(formula TEXT, konto TEXT, rv TEXT, tegev TEXT, INTEGER);
DROP FUNCTION IF EXISTS get_saldo(formula TEXT, konto TEXT, rv TEXT, tegev TEXT, INTEGER, INTEGER);

DROP TABLE IF EXISTS tmp_andmik;
CREATE TEMPORARY TABLE tmp_andmik (
    idx         TEXT,
    tyyp        INTEGER,
    tegev       VARCHAR(20),
    artikkel    VARCHAR(20),
    rahavoog    VARCHAR(20),
    nimetus     VARCHAR(254),
    eelarve     NUMERIC(14, 2),
    tegelik     NUMERIC(14, 2),
    kassa       NUMERIC(14, 2),
    saldoandmik NUMERIC(14, 2),
    db          NUMERIC(14, 2),
    kr          NUMERIC(14, 2),
    aasta       INTEGER,
    kuu         INTEGER,
    rekv_id     INTEGER
);

CREATE OR REPLACE FUNCTION get_saldo(formula TEXT, konto TEXT, rv TEXT DEFAULT NULL, tegevus TEXT DEFAULT NULL,
                                     rekv_id INTEGER DEFAULT NULL,
                                     aasta INTEGER DEFAULT NULL)
    RETURNS NUMERIC
AS
$$
SELECT coalesce((SELECT sum(CASE
                                WHEN $1 LIKE '%KD' THEN (kr - db)
                                WHEN $1 LIKE '%DK' THEN (db - kr)
                                ELSE saldoandmik END)
                 FROM tmp_andmik s,
                      (SELECT min(aasta) AS eelmine_aasta, max(aasta) AS aasta, min(kuu) AS eelmine_kuu, max(kuu) AS kuu
                       FROM tmp_andmik) aasta
                 WHERE s.tyyp = 2
                   AND s.aasta = CASE
                                     WHEN left($1, 1) = 'M' THEN coalesce($6 - 1, aasta.eelmine_aasta)
                                     ELSE coalesce($6, aasta.aasta) END
--			and s.kuu = case when left($1,1) = 'M' then aasta.eelmine_kuu else  aasta.kuu end
    AND ($2 IS NULL OR s.artikkel LIKE trim($2::TEXT || '%'))
    AND ($3 IS NULL OR trim(s.rahavoog) = $3)
    AND ($5 IS NULL OR s.rekv_id = $5)
    AND ($4 IS NULL OR trim(s.tegev) = $4)),
       0);
$$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION get_saldo(formula TEXT, konto TEXT, rv TEXT, TEXT, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_saldo(formula TEXT, konto TEXT, rv TEXT, TEXT, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION get_saldo(formula TEXT, konto TEXT, rv TEXT, TEXT, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION get_saldo(formula TEXT, konto TEXT, rv TEXT, TEXT, INTEGER, INTEGER) TO dbvaatleja;


/*

SELECT *
FROM eelarve_andmik(DATE(2019,01,31), 63, 0)
where (not empty(tegev) or not empty(artikkel))




SELECT * from tmp_andmik
where tyyp = 2
and artikkel like trim('30'::text ||  '%')


SELECT get_saldo('DK'::text,'30'::text)
*/