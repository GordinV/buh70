DROP FUNCTION IF EXISTS eelarve.rahavoog_aruanne(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id       INTEGER,
        grupp         VARCHAR(254),
        all_grupp     VARCHAR(254),
        konto         VARCHAR(20),
        nimetus       VARCHAR(254),
        summa         NUMERIC(14, 2),
        eelmise_summa NUMERIC(14, 2),
        idx           INTEGER
    )
AS
$BODY$

WITH qrySaldoAndmik AS (
    SELECT *
    FROM eelarve.saldoandmik s
    WHERE s.aasta = year(l_kpv)
      AND s.kuu = month(l_kpv)
      AND rekvid = (CASE
                        WHEN l_kond = 1 AND l_rekvid <> 63
                            THEN s.rekvid
                        WHEN l_kond = 1 AND l_rekvid = 63
                            THEN 999
                        ELSE l_rekvid END)
      AND s.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid)
                       UNION ALL
                       SELECT CASE
                                  WHEN l_kond = 1 AND l_rekvid <> 63
                                      THEN l_rekvid
                                  WHEN l_kond = 1 AND l_rekvid = 63
                                      THEN 999
                                  ELSE l_rekvid END
    )
),
     eelmiseSaldoAndmik AS (
         SELECT *
         FROM eelarve.saldoandmik s
         WHERE s.aasta = year(l_kpv) - 1
           AND s.kuu = 12
           AND rekvid = (CASE
                             WHEN l_kond = 1 AND l_rekvid <> 63
                                 THEN s.rekvid
                             WHEN l_kond = 1 AND l_rekvid = 63
                                 THEN 999
                             ELSE l_rekvid END)
           AND s.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid)
                            UNION ALL
                            SELECT CASE
                                       WHEN l_kond = 1 AND l_rekvid <> 63
                                           THEN l_rekvid
                                       WHEN l_kond = 1 AND l_rekvid = 63
                                           THEN 999
                                       ELSE l_rekvid END
         )
     ),
     vanaSaldoAndmik AS (
         SELECT *
         FROM eelarve.saldoandmik s
         WHERE s.aasta = year(l_kpv) - 2
           AND s.kuu = 12
           AND rekvid = (CASE
                             WHEN l_kond = 1 AND l_rekvid <> 63
                                 THEN s.rekvid
                             WHEN l_kond = 1 AND l_rekvid = 63
                                 THEN 999
                             ELSE l_rekvid END)
           AND s.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid)
                            UNION ALL
                            SELECT CASE
                                       WHEN l_kond = 1 AND l_rekvid <> 63
                                           THEN l_rekvid
                                       WHEN l_kond = 1 AND l_rekvid = 63
                                           THEN 999
                                       ELSE l_rekvid END
         )
     ),
     qrySaldo AS (
         SELECT s.rekvid,
                '1'                                   AS konto,
                'Rahavood põhitegevusest'             AS grupp,
                ''                                    AS all_grupp,
                upper('Aruandeperioodi tegevustulem') AS nimetus,
                sum(kr) - sum(db)                     AS summa,
                0::NUMERIC(14, 2)                     AS eelmise_summa,
                1000                                  AS idx
         FROM qrySaldoAndmik s
         WHERE val(left(ltrim(rtrim(s.konto)), 1)) >= 3
           AND val(left(ltrim(rtrim(s.konto)), 2)) <= 64
         GROUP BY rekvid
         UNION ALL
         -- 2019
         SELECT s.rekvid,
                '1'                                   AS konto,
                'Rahavood põhitegevusest'             AS grupp,
                ''                                    AS all_grupp,
                upper('Aruandeperioodi tegevustulem') AS nimetus,
                0::NUMERIC(14, 2)                     AS summa,
                sum(kr) - sum(db)::NUMERIC(14, 2)     AS eelmise_summa,
                1000                                  AS idx
         FROM eelmiseSaldoAndmik s
         WHERE val(left(ltrim(rtrim(s.konto)), 1)) >= 3
           AND val(left(ltrim(rtrim(s.konto)), 2)) <= 64
         GROUP BY rekvid
         UNION ALL
         -- Jooksva per Saldoandmikust (Sum: Kontod 61* deebet) - (Sum: Kontod 61* Kreedit)
         SELECT s.rekvid,
                '2'                                       AS konto,
                'Rahavood põhitegevusest'                 AS grupp,
                'Korrigeerimised'                         AS all_grupp,
                'Põhivara amortisatsioon ja ümberhindlus' AS nimetus,
                sum(db) - sum(kr)                         AS summa,
                0::NUMERIC(14, 2)                         AS eelmise_summa,
                1010                                      AS idx
         FROM qrySaldoAndmik s
         WHERE left(s.konto, 2) = '61'
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT s.rekvid,
                '2'                                       AS konto,
                'Rahavood põhitegevusest'                 AS grupp,
                'Korrigeerimised'                         AS all_grupp,
                'Põhivara amortisatsioon ja ümberhindlus' AS nimetus,
                0                                         AS summa,
                sum(db) - sum(kr)::NUMERIC(14, 2)         AS eelmise_summa,
                1010                                      AS idx
         FROM eelmiseSaldoAndmik s
         WHERE left(s.konto, 2) = '61'
         GROUP BY rekvid
         UNION ALL
         --Käibemaksukulu põhivara soetamiseks
         --Jooksva per Saldoandmikust (Sum: Kontod 601002 deebet) - (Sum: Kontod 601002 Kreedit)
         SELECT s.rekvid,
                '2'                                    AS konto,
                'Rahavood põhitegevusest'              AS grupp,
                'Korrigeerimised'                      AS all_grupp,
                'Käibemaksukulu põhivara soetamiseks ' AS nimetus,
                sum(db) - sum(kr)                      AS summa,
                0::NUMERIC(14, 2)                      AS eelmise_summa,
                1020                                   AS idx
         FROM qrySaldoAndmik s
         WHERE left(s.konto, 6) = '601002'
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT s.rekvid,
                '2'                                    AS konto,
                'Rahavood põhitegevusest'              AS grupp,
                'Korrigeerimised'                      AS all_grupp,
                'Käibemaksukulu põhivara soetamiseks ' AS nimetus,
                0                                      AS summa,
                sum(db) - sum(kr)::NUMERIC(14, 2)      AS eelmise_summa,
                1020                                   AS idx
         FROM eelmiseSaldoAndmik s
         WHERE left(s.konto, 6) = '601002'
         GROUP BY rekvid
         UNION ALL
         --Käibemaksukulu põhivara soetamiseks
         --Jooksva per Saldoandmikust (Sum: konto 3502* deebet) - (Sum: konto 3502* kreedit)
         SELECT s.rekvid,
                '2'                                             AS konto,
                'Rahavood põhitegevusest'                       AS grupp,
                'Korrigeerimised'                               AS all_grupp,
                'Saadud sihtfinantseerimine põhivara soetuseks' AS nimetus,
                sum(db) - sum(kr)                               AS summa,
                0::NUMERIC(14, 2)                               AS eelmise_summa,
                1030                                            AS idx
         FROM qrySaldoAndmik s
         WHERE left(s.konto, 4) = '3502'
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT s.rekvid,
                '2'                                             AS konto,
                'Rahavood põhitegevusest'                       AS grupp,
                'Korrigeerimised'                               AS all_grupp,
                'Saadud sihtfinantseerimine põhivara soetuseks' AS nimetus,
                0                                               AS summa,
                sum(db) - sum(kr)::NUMERIC(14, 2)               AS eelmise_summa,
                1030                                            AS idx
         FROM eelmiseSaldoAndmik s
         WHERE left(s.konto, 4) = '3502'
         GROUP BY rekvid
         UNION ALL

         -- Kasum/kahjum pohivara muugist
         SELECT s.rekvid,
                '2'                             AS konto,
                'Rahavood põhitegevusest'       AS grupp,
                'Korrigeerimised'               AS all_grupp,
                'Kasum/kahjum pohivara müügist' AS nimetus,
                sum(db) - sum(kr)               AS summa,
                0::NUMERIC(14, 2)               AS eelmise_summa,
                1035                            AS idx
         FROM qrySaldoAndmik s
         WHERE left(s.konto, 4) IN ('3810', '3811', '3813', '3814')
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT s.rekvid,
                '2'                               AS konto,
                'Rahavood põhitegevusest'         AS grupp,
                'Korrigeerimised'                 AS all_grupp,
                'Kasum/kahjum pohivara müügist'   AS nimetus,
                0                                 AS summa,
                sum(db) - sum(kr)::NUMERIC(14, 2) AS eelmise_summa,
                1035                              AS idx
         FROM eelmiseSaldoAndmik s
         WHERE left(s.konto, 4) IN ('3810', '3811', '3813', '3814')
         GROUP BY rekvid
         UNION ALL

         --Üle antud mitterahaline sihtfinantseerimine
         --Üle antud mitterahaline sihtfinantseerimine / Antud sihtfinantseerimine põhivara soetuseks
         --Jooksva per Saldoandmikust (4502* deebet miinus kreedit)
         SELECT s.rekvid,
                '2'                                            AS konto,
                'Rahavood põhitegevusest'                      AS grupp,
                'Korrigeerimised'                              AS all_grupp,
                'Antud sihtfinantseerimine põhivara soetuseks' AS nimetus,
                sum(db - kr)                                   AS summa,
                0::NUMERIC(14, 2)                              AS eelmise_summa,
                1040                                           AS idx
         FROM qrySaldoAndmik s
         WHERE konto LIKE '4502%'
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT s.rekvid,
                '2'                                            AS konto,
                'Rahavood põhitegevusest'                      AS grupp,
                'Korrigeerimised'                              AS all_grupp,
                'Antud sihtfinantseerimine põhivara soetuseks' AS nimetus,
                0                                              AS summa,
                sum(db - kr)::NUMERIC(14, 2)                   AS eelmise_summa,
                1040                                           AS idx
         FROM eelmiseSaldoAndmik s
         WHERE konto LIKE '4502%'
         GROUP BY rekvid
         UNION ALL

         SELECT s.rekvid,
                '2'                                        AS konto,
                'Rahavood põhitegevusest'                  AS grupp,
                'Korrigeerimised'                          AS all_grupp,
                'Ebatõenäoliselt laekuvate laenude muutus' AS nimetus,
                sum(db) - sum(kr)                          AS summa,
                0::NUMERIC(14, 2)                          AS eelmise_summa,
                1060                                       AS idx
         FROM qrySaldoAndmik s
         WHERE left(s.konto, 6) IN ('605000', '605010', '605020')
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT s.rekvid,
                '2'                                        AS konto,
                'Rahavood põhitegevusest'                  AS grupp,
                'Korrigeerimised'                          AS all_grupp,
                'Ebatõenäoliselt laekuvate laenude muutus' AS nimetus,
                0                                          AS summa,
                sum(db) - sum(kr)::NUMERIC(14, 2)          AS eelmise_summa,
                1060                                       AS idx
         FROM eelmiseSaldoAndmik s
         WHERE left(s.konto, 6) IN ('605000', '605010', '605020')
         GROUP BY rekvid
         UNION ALL

         --(Eelmise aruandeper saldoandmikust (sum: kontod 102* deebet + kontod 152* deebet) - (sum kontod 102* kreedit+ kontod 152* kreedit))
         -- - (Jooksva per saldoandmikust (sum kontod 102* deebet+ kontod 152* deebet) - (sum kontod 102* kreedit + kontod 152* kreedit))
         SELECT *
         FROM (
                  SELECT rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Maksu-, lõivu- ja trahvinõuete muutus KOKKU'  AS nimetus,
                         sum(e.db - e.kr)                               AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1110                                           AS idx
                  FROM eelmiseSaldoAndmik e
                  WHERE left(konto, 3) IN ('102', '152')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Maksu-, lõivu- ja trahvinõuete muutus'        AS nimetus,
                         -1 * (sum(s.db - s.kr)),
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1110                                           AS idx
                  FROM qrySaldoAndmik s
                  WHERE left(s.konto, 3) IN ('102', '152')
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Maksu-, lõivu- ja trahvinõuete muutus'        AS nimetus,
                         0                                              AS summa,
                         sum(e.db - e.kr)::NUMERIC(14, 2)               AS eelmise_summa,
                         1110                                           AS idx
                  FROM vanaSaldoAndmik e
                  WHERE left(konto, 3) IN ('102', '152')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Maksu-, lõivu- ja trahvinõuete muutus'        AS nimetus,
                         0,
                         -1 * (sum(s.db - s.kr))::NUMERIC(14, 2)        AS eelmise_summa,
                         1110                                           AS idx
                  FROM eelmiseSaldoAndmik s
                  WHERE left(s.konto, 3) IN ('102', '152')
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Eelmise aruandeper saldoandmikust (sum: kontod 10300* deebet + kontod 15300* deebet) -
         -- (sum kontod 10300* kreedit + kontod 15300* kreedit)) -
         -- (Jooksva per saldoandmikust (sum kontod 10300* deebet + kontod 15300* deebet) -
         -- (sum kontod 10300* kreedit + kontod 15300* kreedit))
         SELECT *
         FROM (
                  SELECT e.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus nõuetes ostjate vastu'                 AS nimetus,
                         sum(e.db - e.kr),
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1120                                           AS idx
                  FROM eelmiseSaldoAndmik e
                  WHERE left(e.konto, 5) IN ('10300', '15300')
                  GROUP BY e.rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus nõuetes ostjate vastu'                 AS nimetus,
                         -1 * sum(s.db - s.kr)                          AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1120                                           AS idx
                  FROM qrySaldoAndmik s
                  WHERE left(s.konto, 5) IN ('10300', '15300')
                  GROUP BY s.rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT e.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus nõuetes ostjate vastu'                 AS nimetus,
                         0,
                         sum(e.db - e.kr)::NUMERIC(14, 2)               AS eelmise_summa,
                         1120                                           AS idx
                  FROM vanaSaldoAndmik e
                  WHERE left(e.konto, 5) IN ('10300', '15300')
                  GROUP BY e.rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus nõuetes ostjate vastu'                 AS nimetus,
                         0                                              AS summa,
                         -1 * sum(s.db - s.kr)::NUMERIC(14, 2)          AS eelmise_summa,
                         1120                                           AS idx
                  FROM eelmiseSaldoAndmik s
                  WHERE left(s.konto, 5) IN ('10300', '15300')
                  GROUP BY s.rekvid
              ) qry
         UNION ALL

         /*              --(Eelmise aruandeper saldoandmikust (sum: kontod 103190 deebet) - (sum kontod 103190 kreedit)) - (Jooksva per saldoandmikust (sum kontod 103190 deebet) - (sum kontod 103190 kreedit))
                      SELECT
                       s.rekvid,
                       '4' AS konto,
                       'Rahavood põhitegevusest' AS grupp,
                       'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                       'Muutus viitlaekumistes' AS nimetus,
                       coalesce(sum(db - kr)
                                    FILTER (WHERE kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
                       coalesce(sum(db - kr)
                                    FILTER (WHERE kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
                      FROM
                       qrySaldoAndmik s
                      WHERE
                       s.konto LIKE '103190%'
                      GROUP BY
                       rekvid
                      UNION ALL
         */
         --(Eelmise aruandeper saldoandmikust (sum: kontod 1035* deebet - konto 103500 deebet - konto 103540 deebet - konto 103556 deebet - konto 103557 deebet) -
         --(sum kontod 1035* kreedit - konto 103500 kreedit - konto 103540 kreedit - konto 103556 kreedit - konto 103557 kreedit)) -
         --(Jooksva per saldoandmikust (sum: kontod 1035* deebet - konto 103500 deebet - konto 103540 deebet - konto 103556 deebet - konto 103557 deebet)
         -- - (sum kontod 1035* kreedit - konto 103500 kreedit - konto 103540 kreedit - konto 103556 kreedit - konto 103557 kreedit))
         SELECT *
         FROM (
                  SELECT e.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus nõuetes toetuste ja siirete eest'      AS nimetus,
                         coalesce(sum(db) FILTER (WHERE konto LIKE '1035%'), 0) -
                         coalesce(sum(db) FILTER (WHERE konto IN ('103500', '103540', '103556', '103557')),
                                  0) -
                         (coalesce(sum(kr) FILTER (WHERE konto LIKE '1035%' ), 0) -
                          coalesce(sum(kr) FILTER (WHERE konto IN ('103500', '103540', '103556', '103557')),
                                   0)),
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1130                                           AS idx
                  FROM eelmiseSaldoAndmik e
                  GROUP BY rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus nõuetes toetuste ja siirete eest'      AS nimetus,
                         - 1 * ((coalesce(sum(db) FILTER (WHERE konto LIKE '1035%' ), 0) -
                                 coalesce(sum(db)
                                          FILTER (WHERE konto IN ('103500', '103540', '103556', '103557')),
                                          0) -
                                 (coalesce(sum(kr) FILTER (WHERE konto LIKE '1035%' ), 0) -
                                  coalesce(sum(kr)
                                           FILTER (WHERE konto IN ('103500', '103540', '103556', '103557')),
                                           0))))                        AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1130                                           AS idx
                  FROM qrySaldoAndmik s
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT e.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus nõuetes toetuste ja siirete eest'      AS nimetus,
                         0                                              AS summa,
                         coalesce(sum(db) FILTER (WHERE konto LIKE '1035%'), 0) -
                         coalesce(sum(db) FILTER (WHERE konto IN ('103500', '103540', '103556', '103557')),
                                  0) -
                         (coalesce(sum(kr) FILTER (WHERE konto LIKE '1035%' ), 0) -
                          coalesce(sum(kr) FILTER (WHERE konto IN ('103500', '103540', '103556', '103557')),
                                   0))::NUMERIC(14, 2)                  AS eelmise_summa,
                         1130                                           AS idx
                  FROM vanaSaldoAndmik e
                  GROUP BY rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus nõuetes toetuste ja siirete eest'      AS nimetus,
                         0                                              AS summa,
                         - 1 * ((coalesce(sum(db) FILTER (WHERE konto LIKE '1035%' ), 0) -
                                 coalesce(sum(db)
                                          FILTER (WHERE konto IN ('103500', '103540', '103556', '103557')),
                                          0) -
                                 (coalesce(sum(kr) FILTER (WHERE konto LIKE '1035%' ), 0) -
                                  coalesce(sum(kr)
                                           FILTER (WHERE konto IN ('103500', '103540', '103556', '103557')),
                                           0))))::NUMERIC(14, 2)        AS eelmise_summa,
                         1130                                           AS idx
                  FROM eelmiseSaldoAndmik s
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Eelmise aruandeper saldoandmikust (sum: kontod 1036* deebet + sum kontod 1536* deebet) - (sum kontod 1036* kreedit + sum kontod 1536* kreedit))
         -- - (Jooksva per saldoandmikust (sum kontod 1036* deebet + sum ontod 1536* deebet) - (sum kontod 1036* kreedit + sum kontod 1536* kreedit))
         SELECT *
         FROM (
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus muudes nõuetes'                        AS nimetus,
                         coalesce(sum(db - kr)
                                  FILTER (WHERE left(konto, 4) IN ('1036', '1536') AND kuu = 12 AND
                                                aasta = year(l_kpv) - 1),
                                  0) -
                         coalesce(sum(db - kr)
                                  FILTER (WHERE left(konto, 4) IN ('1036', '1536') AND
                                                kuu = month(l_kpv) AND
                                                aasta = year(l_kpv)),
                                  0)                                    AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1140                                           AS idx
                  FROM eelarve.saldoandmik s
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1 AND l_rekvid <> 63
                                          THEN s.rekvid
                                      WHEN l_kond = 1 AND l_rekvid = 63
                                          THEN 999
                                      ELSE l_rekvid END)
                    AND s.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid)
                                     UNION ALL
                                     SELECT CASE
                                                WHEN l_kond = 1 AND l_rekvid <> 63
                                                    THEN l_rekvid
                                                WHEN l_kond = 1 AND l_rekvid = 63
                                                    THEN 999
                                                ELSE l_rekvid END
                  )
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus muudes nõuetes'                        AS nimetus,
                         0                                              AS summa,
                         coalesce(sum(db - kr)
                                  FILTER (WHERE left(konto, 4) IN ('1036', '1536') AND kuu = 12 AND
                                                aasta = year(l_kpv) - 2),
                                  0) -
                         coalesce(sum(db - kr)
                                  FILTER (WHERE left(konto, 4) IN ('1036', '1536') AND
                                                kuu = 12 AND
                                                aasta = year(l_kpv) - 1),
                                  0)::NUMERIC(14, 2)                    AS eelmise_summa,
                         1140                                           AS idx
                  FROM eelarve.saldoandmik s
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1 AND l_rekvid <> 63
                                          THEN s.rekvid
                                      WHEN l_kond = 1 AND l_rekvid = 63
                                          THEN 999
                                      ELSE l_rekvid END)
                    AND s.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid)
                                     UNION ALL
                                     SELECT CASE
                                                WHEN l_kond = 1 AND l_rekvid <> 63
                                                    THEN l_rekvid
                                                WHEN l_kond = 1 AND l_rekvid = 63
                                                    THEN 999
                                                ELSE l_rekvid END
                  )
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Eelmise aruandeper saldoandmikust (sum: kontod 1037* deebet) - (sum kontod 1037* kreedit)) -
         --(Jooksva per saldoandmikust (sum kontod 1037* deebet) - (sum kontod 1037* kreedit))
         SELECT *
         FROM (
                  SELECT rekvid,
                         '4'                                              AS konto,
                         'Rahavood põhitegevusest'                        AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus'   AS all_grupp,
                         'Muutus maksude, lõivude, trahvide ettemaksetes' AS nimetus,
                         sum(db - kr)                                     AS summa,
                         0::NUMERIC(14, 2)                                AS eelmise_summa,
                         1150                                             AS idx
                  FROM eelmiseSaldoAndmik
                  WHERE left(konto, 4) = '1037'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                              AS konto,
                         'Rahavood põhitegevusest'                        AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus'   AS all_grupp,
                         'Muutus maksude, lõivude, trahvide ettemaksetes' AS nimetus,
                         - 1 * (sum(db - kr))                             AS summa,
                         0::NUMERIC(14, 2)                                AS eelmise_summa,
                         1150                                             AS idx
                  FROM qrySaldoAndmik s
                  WHERE left(konto, 4) = '1037'
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT rekvid,
                         '4'                                              AS konto,
                         'Rahavood põhitegevusest'                        AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus'   AS all_grupp,
                         'Muutus maksude, lõivude, trahvide ettemaksetes' AS nimetus,
                         0                                                AS summa,
                         sum(db - kr)::NUMERIC(14, 2)                     AS eelmise_summa,
                         1150                                             AS idx
                  FROM vanaSaldoAndmik
                  WHERE left(konto, 4) = '1037'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                              AS konto,
                         'Rahavood põhitegevusest'                        AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus'   AS all_grupp,
                         'Muutus maksude, lõivude, trahvide ettemaksetes' AS nimetus,
                         0                                                AS summa,
                         - 1 * (sum(db - kr))::NUMERIC(14, 2)             AS eelmise_summa,
                         1150                                             AS idx
                  FROM eelmiseSaldoAndmik s
                  WHERE left(konto, 4) = '1037'
                  GROUP BY rekvid
              ) qry
         UNION ALL

         -- (Eelmise aruandeper saldoandmikust (sum: kontod 1038* deebet miinus kreedit - 103856, 103857 deebet miinus kreedit) -
         -- (Jooksva per saldoandmikust (sum kontod 1038* deebet miinus kreedit miinus kreedit - 103856, 103857 deebet miinus kreedit)
         SELECT *
         FROM (
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus toetuste ettemaksetes'                 AS nimetus,
                         sum(db - kr)                                   AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1160                                           AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE (left(konto, 4) = '1038' AND left(konto, 6) NOT IN ('103856', '103857'))
                  GROUP BY rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus toetuste ettemaksetes'                 AS nimetus,
                         -1 * sum(db - kr)                              AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1160                                           AS idx
                  FROM qrySaldoAndmik s
                  WHERE (left(konto, 4) = '1038' AND left(konto, 6) NOT IN ('103856', '103857'))
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus toetuste ettemaksetes'                 AS nimetus,
                         0                                              AS summa,
                         sum(db - kr)::NUMERIC(14, 2)                   AS eelmise_summa,
                         1160                                           AS idx
                  FROM vanaSaldoAndmik S
                  WHERE (left(konto, 4) = '1038' AND left(konto, 6) NOT IN ('103856', '103857'))
                  GROUP BY rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus toetuste ettemaksetes'                 AS nimetus,
                         0                                              AS summa,
                         -1 * sum(db - kr)::NUMERIC(14, 2)              AS eelmise_summa,
                         1160                                           AS idx
                  FROM eelmiseSaldoAndmik s
                  WHERE (left(konto, 4) = '1038' AND left(konto, 6) NOT IN ('103856', '103857'))
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Eelmise aruandeper saldoandmikust (sum: kontod 1039* deebet + konto 153990 deebet) - (sum kontod 1039* kreedit + konto 153990 kreedit)) -
         --(Jooksva per saldoandmikust (sum kontod 1039* deebet + konto 153990 deebet) - (sum kontod 1039* kreedit + konto 153990 kredit))
         SELECT *
         FROM (
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus muudes ettemaksetes'                   AS nimetus,
                         sum(db - kr)                                   AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1170                                           AS idx
                  FROM eelmiseSaldoAndmik s
                  WHERE (konto LIKE '1039%' OR konto = '153990')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus muudes ettemaksetes'                   AS nimetus,
                         -1 * (sum(db - kr))                            AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1170                                           AS idx
                  FROM qrySaldoAndmik s
                  WHERE (konto LIKE '1039%' OR konto = '153990')
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus muudes ettemaksetes'                   AS nimetus,
                         0                                              AS summa,
                         sum(db - kr)::NUMERIC(14, 2)                   AS eelmise_summa,
                         1170                                           AS idx
                  FROM vanaSaldoAndmik s
                  WHERE (konto LIKE '1039%' OR konto = '153990')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT s.rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus muudes ettemaksetes'                   AS nimetus,
                         0                                              AS summa,
                         -1 * (sum(db - kr))::NUMERIC(14, 2)            AS eelmise_summa,
                         1170                                           AS idx
                  FROM eelmiseSaldoAndmik s
                  WHERE (konto LIKE '1039%' OR konto = '153990')
                  GROUP BY rekvid
              ) qry
         UNION ALL
         --(Eelmise aruandeper saldoandmikust (sum: kontod 108* deebet) - (sum kontod 108* kreedit)) - (Jooksva per saldoandmikust (sum kontod 108* deebet) - (sum kontod 108* kreedit))
         SELECT *
         FROM (
                  SELECT rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus varudes'                               AS nimetus,
                         sum(db - kr)                                   AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1180                                           AS idx
                  FROM eelmiseSaldoAndmik
                  WHERE konto LIKE '108%'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus varudes'                               AS nimetus,
                         - 1 * (sum(db - kr))                           AS summa,
                         0::NUMERIC(14, 2)                              AS eelmise_summa,
                         1180                                           AS idx
                  FROM qrySaldoAndmik S
                  WHERE konto LIKE '108%'
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus varudes'                               AS nimetus,
                         0                                              AS summa,
                         sum(db - kr)::NUMERIC(14, 2)                   AS eelmise_summa,
                         1180                                           AS idx
                  FROM vanaSaldoAndmik
                  WHERE konto LIKE '108%'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT rekvid,
                         '4'                                            AS konto,
                         'Rahavood põhitegevusest'                      AS grupp,
                         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
                         'Muutus varudes'                               AS nimetus,
                         0                                              AS summa,
                         - 1 * (sum(db - kr))::NUMERIC(14, 2)           AS eelmise_summa,
                         1180                                           AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto LIKE '108%'
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Jooksva per saldoandmikust (sum: kontod 200* kreedit) - (sum kontod 200* deebet)) -
         -- (Eelmise per saldoandmikust (sum kontod 200* kreedit) - (sum kontod 200* deebet))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                                     AS konto,
                         'Rahavood põhitegevusest'                               AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus'           AS all_grupp,
                         'Muutus saadud maksude, lõivude, trahvide ettemaksetes' AS nimetus,
                         sum(kr - db)                                            AS summa,
                         0::NUMERIC(14, 2)                                       AS eelmise_summa,
                         1210                                                    AS idx
                  FROM qrySaldoAndmik S
                  WHERE konto LIKE '200%'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                                     AS konto,
                         'Rahavood põhitegevusest'                               AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus'           AS all_grupp,
                         'Muutus saadud maksude, lõivude, trahvide ettemaksetes' AS nimetus,
                         -1 * sum(kr - db)                                       AS summa,
                         0::NUMERIC(14, 2)                                       AS eelmise_summa,
                         1210                                                    AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto LIKE '200%'
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                                     AS konto,
                         'Rahavood põhitegevusest'                               AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus'           AS all_grupp,
                         'Muutus saadud maksude, lõivude, trahvide ettemaksetes' AS nimetus,
                         0                                                       AS summa,
                         sum(kr - db)::NUMERIC(14, 2)                            AS eelmise_summa,
                         1210                                                    AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto LIKE '200%'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                                     AS konto,
                         'Rahavood põhitegevusest'                               AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus'           AS all_grupp,
                         'Muutus saadud maksude, lõivude, trahvide ettemaksetes' AS nimetus,
                         0                                                       AS summa,
                         -1 * sum(kr - db)::NUMERIC(14, 2)                       AS eelmise_summa,
                         1210                                                    AS idx
                  FROM vanaSaldoAndmik S
                  WHERE konto LIKE '200%'
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Jooksva per saldoandmikust (sum: konto 201000 kreedit + konto 25000* kreedit) - (sum konto 201000 deebet + konto 25000* deebet)) -
         --(Eelmise per saldoandmikust (sum kontod 201000 kreedit + konto 25000* kreedit) - (sum kontod 201000 deebet + konto 25000* deebet))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus võlgades hankjatele'                  AS nimetus,
                         sum(kr - db)                                  AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1220                                          AS idx
                  FROM qrySaldoAndmik S
                  WHERE (LEFT(konto, 6) = '201000' OR LEFT(konto, 5) = '25000')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus võlgades hankjatele'                  AS nimetus,
                         -1 * sum(kr - db)                             AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1220                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE (LEFT(konto, 6) = '201000' OR LEFT(konto, 5) = '25000')
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus võlgades hankjatele'                  AS nimetus,
                         0                                             AS summa,
                         sum(kr - db)::NUMERIC(14, 2)                  AS eelmise_summa,
                         1220                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE (LEFT(konto, 6) = '201000' OR LEFT(konto, 5) = '25000')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus võlgades hankjatele'                  AS nimetus,
                         0                                             AS summa,
                         -1 * sum(kr - db)::NUMERIC(14, 2)             AS eelmise_summa,
                         1220                                          AS idx
                  FROM vanaSaldoAndmik S
                  WHERE (LEFT(konto, 6) = '201000' OR LEFT(konto, 5) = '25000')
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Jooksva per saldoandmikust (sum: konto 202* kreedit) - (sum konto 202* deebet)) -
         -- (Eelmise per saldoandmikust (sum kontod 202* kreedit) - (sum kontod 202* deebet))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus võlgades töövõtjatele'                AS nimetus,
                         sum(kr - db)                                  AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1230                                          AS idx
                  FROM qrySaldoAndmik S
                  WHERE konto LIKE '202%'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus võlgades töövõtjatele'                AS nimetus,
                         -1 * sum(kr - db)                             AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1230                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto LIKE '202%'
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus võlgades töövõtjatele'                AS nimetus,
                         0                                             AS summa,
                         sum(kr - db)::NUMERIC(14, 2)                  AS eelmise_summa,
                         1230                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto LIKE '202%'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus võlgades töövõtjatele'                AS nimetus,
                         0                                             AS summa,
                         -1 * sum(kr - db)::NUMERIC(14, 2)             AS eelmise_summa,
                         1230                                          AS idx
                  FROM vanaSaldoAndmik S
                  WHERE konto LIKE '202%'
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Jooksva per saldoandmikust (sum: konto 2030* kreedit + konto 2530* kreedit) - (sum konto 2030* deebet + konto 2530* deebet)) -
         -- (Eelmise per saldoandmikust (sum kontod 2030* kreedit + konto 2530* kreedit) - (sum kontod 2030* deebet + konto 2530* deebet))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus maksu-, lõivu- ja trahvikohustistes'  AS nimetus,
                         sum(kr - db)                                  AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1240                                          AS idx
                  FROM qrySaldoAndmik S
                  WHERE left(konto, 4) IN ('2030', '2530')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus maksu-, lõivu- ja trahvikohustistes'  AS nimetus,
                         -1 * sum(kr - db)                             AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1240                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE left(konto, 4) IN ('2030', '2530')
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus maksu-, lõivu- ja trahvikohustistes'  AS nimetus,
                         0                                             AS summa,
                         sum(kr - db)::NUMERIC(14, 2)                  AS eelmise_summa,
                         1240                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE left(konto, 4) IN ('2030', '2530')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus maksu-, lõivu- ja trahvikohustistes'  AS nimetus,
                         0                                             AS summa,
                         -1 * sum(kr - db)::NUMERIC(14, 2)             AS eelmise_summa,
                         1240                                          AS idx
                  FROM vanaSaldoAndmik S
                  WHERE left(konto, 4) IN ('2030', '2530')
                  GROUP BY rekvid
              ) qry
         UNION ALL
         --(Jooksva per saldoandmikust (sum: konto 203290 kreedit) - (sum konto 203290 deebet)) -
         -- (Eelmise per saldoandmikust (sum kontod 203290 kreedit) - (sum kontod 203290 deebet))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustuste netomuutus' AS all_grupp,
                         'Muutus viitvõlgades'                         AS nimetus,
                         sum(kr - db)                                  AS summa,
                         0                                             AS eelmise_summa,
                         1245                                          AS idx
                  FROM qrySaldoAndmik S
                  WHERE left(konto, 6) = '203290'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustuste netomuutus' AS all_grupp,
                         'Muutus viitvõlgades'                         AS nimetus,
                         -1 * sum(kr - db)                             AS summa,
                         0                                             AS eelmise_summa,
                         1245                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE left(konto, 6) = '203290'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustuste netomuutus' AS all_grupp,
                         'Muutus viitvõlgades'                         AS nimetus,
                         0                                             AS summa,
                         sum(kr - db)                                  AS eelmise_summa,
                         1245                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE left(konto, 6) = '203290'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustuste netomuutus' AS all_grupp,
                         'Muutus viitvõlgades'                         AS nimetus,
                         0                                             AS summa,
                         -1 * sum(kr - db)                             AS eelmise_summa,
                         1245                                          AS idx
                  FROM vanaSaldoAndmik S
                  WHERE left(konto, 6) = '203290'
                  GROUP BY rekvid
              ) qry
         UNION ALL
         --Muutus toetuste ja siirete kohustustes
--(Jooksva per saldoandmikust (sum: konto 2035* kreedit miinus deebet- konto 203500, 203540, 203556, 203557 kreedit miinus deebet) -
--(Eelmise per saldoandmikust (sum kontod 2035* kreedit miinus deebet - konto 203500, 203540, 203556, 203557 kreedit miinus de
--Muutus toetuste ja siirete kohustustes
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus toetuste ja siirete kohustistes'      AS nimetus,
                         sum(kr - db)                                  AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1250                                          AS idx
                  FROM qrySaldoAndmik S
                  WHERE left(konto, 4) = '2035'
                    AND left(konto, 6) NOT IN ('203500', '203540', '203556', '203557')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus toetuste ja siirete kohustistes'      AS nimetus,
                         -1 * sum(kr - db)                             AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1250                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE left(konto, 4) = '2035'
                    AND left(konto, 6) NOT IN ('203500', '203540', '203556', '203557')
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus toetuste ja siirete kohustistes'      AS nimetus,
                         0                                             AS summa,
                         sum(kr - db)::NUMERIC(14, 2)                  AS eelmise_summa,
                         1250                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE left(konto, 4) = '2035'
                    AND left(konto, 6) NOT IN ('203500', '203540', '203556', '203557')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus toetuste ja siirete kohustistes'      AS nimetus,
                         0                                             AS summa,
                         -1 * sum(kr - db)::NUMERIC(14, 2)             AS eelmise_summa,
                         1250                                          AS idx
                  FROM vanaSaldoAndmik S
                  WHERE left(konto, 4) = '2035'
                    AND left(konto, 6) NOT IN ('203500', '203540', '203556', '203557')
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Jooksva per saldoandmikust (sum: konto 2036* kreedit + konto 2536* kreedit) - (sum konto 2036* deebet + 2536* deebet)) -
         -- (Eelmise per saldoandmikust (sum kontod 2036* kreedit + 2536* kreedit) - (sum kontod 2036* deebet + 2536* deebet))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus muudes kohustistes'                   AS nimetus,
                         sum(kr - db)                                  AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1260                                          AS idx
                  FROM qrySaldoAndmik S
                  WHERE left(konto, 4) IN ('2036', '2536')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus muudes kohustistes'                   AS nimetus,
                         -1 * sum(kr - db)                             AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1260                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE left(konto, 4) IN ('2036', '2536')
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus muudes kohustistes'                   AS nimetus,
                         0                                             AS summa,
                         sum(kr - db)::NUMERIC(14, 2)                  AS eelmise_summa,
                         1260                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE left(konto, 4) IN ('2036', '2536')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus muudes kohustistes'                   AS nimetus,
                         0                                             AS summa,
                         -1 * sum(kr - db)::NUMERIC(14, 2)             AS eelmise_summa,
                         1260                                          AS idx
                  FROM vanaSaldoAndmik S
                  WHERE left(konto, 4) IN ('2036', '2536')
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Jooksva per saldoandmikust (sum: konto 2038* kreedit - konto 203856 kreedit- konto 203857 kreedit) -
--(sum konto 2038* deebet - konto 203856 deebet - konto 203857 deebet)) -
--(Eelmise per saldoandmikust (sum: konto 2038* kreedit - konto 203856 kreedit- konto 203857 kreedit) -
--(sum konto 2038* deebet - konto 203856 deebet - konto 203857 deebet))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus saadud toetuste ettemaksetes'         AS nimetus,
                         sum(kr - db)                                  AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1270                                          AS idx
                  FROM qrySaldoAndmik S
                  WHERE konto LIKE '2038%'
                    AND konto NOT IN ('203856', '203857')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus saadud toetuste ettemaksetes'         AS nimetus,
                         -1 * sum(kr - db)                             AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1270                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto LIKE '2038%'
                    AND konto NOT IN ('203856', '203857')
                  GROUP BY rekvid
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus saadud toetuste ettemaksetes'         AS nimetus,
                         0                                             AS summa,
                         sum(kr - db)::NUMERIC(14, 2)                  AS eelmise_summa,
                         1270                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto LIKE '2038%'
                    AND konto NOT IN ('203856', '203857')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus saadud toetuste ettemaksetes'         AS nimetus,
                         0                                             AS summa,
                         -1 * sum(kr - db)::NUMERIC(14, 2)             AS eelmise_summa,
                         1270                                          AS idx
                  FROM vanaSaldoAndmik S
                  WHERE konto LIKE '2038%'
                    AND konto NOT IN ('203856', '203857')
                  GROUP BY rekvid
              ) qry
         UNION ALL

         --(Jooksva per saldoandmikust (sum: konto 203900 kreedit + konto 203990 kreedit + konto 253890 kreedit) - (sum konto 203900 deebet + konto 203990 deebet + konto 253890 deebet)) -
         -- (Eelmise per saldoandmikust (sum kontod 203900 kreedit + konto 203990 kreedit + konto 253890 kreedit) - (sum kontod 203900 deebet + konto 203990 deebet + konto 253890 deebet))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus muudes saadud ettemaksetes'           AS nimetus,
                         sum(kr - db)                                  AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1280                                          AS idx
                  FROM qrySaldoAndmik S
                  WHERE konto IN ('203900', '203990', '253890')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus muudes saadud ettemaksetes'           AS nimetus,
                         -1 * sum(kr - db)                             AS summa,
                         0::NUMERIC(14, 2)                             AS eelmise_summa,
                         1280                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto IN ('203900', '203990', '253890')
                  GROUP BY rekvid
                  UNION ALL
-- 2019
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus muudes saadud ettemaksetes'           AS nimetus,
                         0                                             AS summa,
                         sum(kr - db)::NUMERIC(14, 2)                  AS eelmise_summa,
                         1280                                          AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto IN ('203900', '203990', '253890')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '5'                                           AS konto,
                         'Rahavood põhitegevusest'                     AS grupp,
                         'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                         'Muutus muudes saadud ettemaksetes'           AS nimetus,
                         0                                             AS summa,
                         -1 * sum(kr - db)::NUMERIC(14, 2)             AS eelmise_summa,
                         1280                                          AS idx
                  FROM vanaSaldoAndmik S
                  WHERE konto IN ('203900', '203990', '253890')
                  GROUP BY rekvid
              ) qry
         UNION ALL
         --Jooksva per saldoandmikust (sum: ((konto 206* kreedit RV 41, 49, 05, 06) - (konto 206030 kreedit RV 41, 49, 05, 06))+ (konto 256* kreedit RV 41, 49, 05, 06) -
--((sum konto 206* deebet RV 41, 49, 05, 06) - (konto 206030 deebet RV 41, 49, 05, 06)) - (konto 256* deebet RV 41, 49, 06, 05))
         SELECT S.rekvid,
                '5'                                           AS konto,
                'Rahavood põhitegevusest'                     AS grupp,
                'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                'Muutus eraldistes'                           AS nimetus,
                sum(kr - db)                                  AS summa,
                0::NUMERIC(14, 2)                             AS eelmise_summa,
                1290                                          AS idx
         FROM qrySaldoAndmik S
         WHERE left(konto, 3) IN ('206', '256')
           AND rahavoo IN ('41', '49', '05', '06')
           AND konto <> '206030'
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT S.rekvid,
                '5'                                           AS konto,
                'Rahavood põhitegevusest'                     AS grupp,
                'Põhitegevusega seotud kohustiste netomuutus' AS all_grupp,
                'Muutus eraldistes'                           AS nimetus,
                0                                             AS summa,
                sum(kr - db)::NUMERIC(14, 2)                  AS eelmise_summa,
                1290                                          AS idx
         FROM eelmiseSaldoAndmik S
         WHERE left(konto, 3) IN ('206', '256')
           AND rahavoo IN ('41', '49', '05', '06')
           AND konto <> '206030'
         GROUP BY rekvid
         UNION ALL

         --Materiaalse ja immateriaalse põhivara soetus
--         Jooksva per saldoandmikust (Konto 155* kreedit (RV 01)) - (Sum: Konto 155* deebet (RV 01)) +(Sum: Konto 156* kreedit (RV 01)) -
         --         (Sum: Konto 156* deebet (RV 01)) +
         --         ( 601002 Kreedit miinus deebet)+(650990 kreedit - deebet) +
         --         (sum: konto 2082* kreedit (RV 01; RV 05)) -
         --         (sum: konto 2082* deebet (RV 01; RV 05)) +
         --         (sum: konto 2582* kreedit (RV 01; RV 05)) -
         --         (sum: konto 2582* deebet (RV 01; RV 05)) +
         --         (sum: konto 350200 kreedit (RV 01)) - (sum: konto 350200 deebet (RV 01)) +
         --         (sum: konto 350220 kreedit (RV 01)) - (sum: konto 350220 deebet (RV 01)) + (sum: konto 350240 kreedit (RV 01)) -
         --         (sum: konto 350240 deebet RV 01)) + (sum 257* kreedit (RV 01)) - (sum 257* kreedit RV 01)) +
         --         (sum: konto 2086* kreedit (RV 01; RV 05)) - (sum: konto 2086* deebet (RV 01; RV 05)) +
         --         (sum: konto 2586* kreedit (RV 01; RV 05)) - (sum: konto 2586* deebet (RV 01; RV 05))  +
         --         (Jooksva per saldoandmikust (sum: konto 201010 kreedit + konto 25001* kreedit) - (sum konto 201010 deebet + konto 25001* deebet))
         --         - (Eelmise per saldoandmikust (sum kontod 201010 kreedit + konto 25001* kreedit) - (sum kontod 201010 deebet + konto 25001* deebet))
         --         SELECT S.rekvid,

         SELECT rekvid,
                ''                                                               AS konto,
                'Rahavood investeerimistegevusest'                               AS grupp,
                'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                ''                                                               AS nimetus,
                sum(summa)                                                       AS summa,
                0::NUMERIC(14, 2)                                                AS eelmise_summa,
                1305                                                             AS idx
         FROM (
                  SELECT rekvid,
                         '71'                                                             AS konto,
                         ''                                                               AS grupp,
                         'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                         'Materiaalse ja immateriaalse põhivara soetus'                   AS nimetus,
                         sum(summa)                                                       AS summa,
                         1291                                                             AS idx
                  FROM (SELECT rekvid,
                               kr - db AS summa
                        FROM qrySaldoAndmik q
                        WHERE ((left(konto, 3) IN ('155', '156', '257') AND rahavoo = '01')
                            OR (left(konto, 6) IN ('601002', '650990'))
                            OR (left(konto, 4) IN ('2082', '2582', '2086', '2586') AND rahavoo IN ('01', '05'))
                            OR (left(konto, 6) IN ('350200', '350220', '350240') AND rahavoo = '01')
                            OR (left(konto, 6) = '201010'
                                OR left(konto, 5) = '25001')
                                  )
                        UNION ALL
                        SELECT rekvid
                                ,
                               -1 * (kr - db) AS summa
                        FROM eelmiseSaldoAndmik
                        WHERE left(konto, 6) IN ('201010')
                           OR left(konto, 5) IN ('25001')
                       ) qry
                  GROUP BY rekvid
              ) qry
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT rekvid,
                ''                                                               AS konto,
                'Rahavood investeerimistegevusest'                               AS grupp,
                'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                ''                                                               AS nimetus,
                0                                                                AS summa,
                sum(summa)::NUMERIC(14, 2)                                       AS eelmise_summa,
                1305                                                             AS idx
         FROM (
                  SELECT rekvid,
                         '71'                                                             AS konto,
                         ''                                                               AS grupp,
                         'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                         'Materiaalse ja immateriaalse põhivara soetus'                   AS nimetus,
                         sum(summa)                                                       AS summa,
                         1291                                                             AS idx
                  FROM (SELECT rekvid,
                               kr - db AS summa
                        FROM eelmiseSaldoAndmik q
                        WHERE ((left(konto, 3) IN ('155', '156', '257') AND rahavoo = '01')
                            OR (left(konto, 6) IN ('601002', '650990'))
                            OR (left(konto, 4) IN ('2082', '2582', '2086', '2586') AND rahavoo IN ('01', '05'))
                            OR (left(konto, 6) IN ('350200', '350220', '350240') AND rahavoo = '01')
                            OR (left(konto, 6) = '201010'
                                OR left(konto, 5) = '25001')
                                  )
                        UNION ALL
                        SELECT rekvid
                                ,
                               -1 * (kr - db) AS summa
                        FROM vanaSaldoAndmik
                        WHERE left(konto, 6) IN ('201010')
                           OR left(konto, 5) IN ('25001')
                       ) qry
                  GROUP BY rekvid
              ) qry
         GROUP BY rekvid
         UNION ALL

         --Jooksva per Saldoandmikust (Sum: Kontod 381000+381001+381100+381101+381110+381111+381115+381116+381120+381121+381125+381126+381130+381131+381140+381141+381145+381146+
--381150+381151+381160+381161+381170+381171+381180+381181+381300+381301+381320+381321+381360+381361+381400+381401+381410+381411+381420+381421 kreedit)
-- - (Sum: 381000+381001+381100+381101+381110+381111+381115+381116+381120+381121+381125+381126+381130+381131+381140+381141+381145+381146+381150+381151+381160+
--381161+381170+381171+381180+381181+381300+381301+381320+381321+381360+381361+381400+381401+381410+381411+381420+381421 deebet)
         SELECT rekvid,
                konto,
                'Rahavood investeerimistegevusest'                                   AS grupp,
                'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_gripp,
                ''                                                                   AS nimetus,
                sum(summa)                                                           AS summa,
                0::NUMERIC(14, 2)                                                    AS eelmise_summa,
                1310                                                                 AS idx
         FROM (
                  SELECT rekvid,
                         '72'                  AS konto,
                         ''                    AS grupp,
                         ''                    AS all_grupp,
                         'Müügist saadud tulu' AS nimetus,
                         sum(kr - db)          AS summa
                  FROM qrySaldoAndmik S
                  WHERE konto IN
                        ('381000',
                         '381001',
                         '381100',
                         '381101',
                         '381110',
                         '381111',
                         '381115',
                         '381116',
                         '381120',
                         '381121',
                         '381125',
                         '381126',
                         '381130',
                         '381131',
                         '381140',
                         '381141',
                         '381145',
                         '381146',
                         '381150',
                         '381151',
                         '381160',
                         '381161',
                         '381170',
                         '381171',
                         '381180',
                         '381181',
                         '381300',
                         '381301',
                         '381320',
                         '381321',
                         '381360',
                         '381361',
                         '381400',
                         '381401',
                         '381410',
                         '381411',
                         '381420',
                         '381421')
                  GROUP BY rekvid
                  UNION ALL
                  --(Eelmise aruandeper saldoandmikust (sum: kontod 10301* deebet + konto 15301* deebet) - (sum kontod 10301* kreedit + konto 15301* kreedit)) -
--(Jooksva per saldoandmikust (sum: kontod 10301* deebet + konto 15301* deebet) - (sum kontod 10301* kreedit + konto 15301* kreedit))
                  SELECT *
                  FROM (
                           WITH preQry AS (
                               SELECT rekvid, (db - kr) AS summa
                               FROM eelmiseSaldoAndmik e
                               WHERE left(konto, 5) IN ('10301', '15301')
                               UNION ALL
                               SELECT rekvid
                                       ,
                                      -1 * (db - kr) AS summa
                               FROM qrySaldoAndmik
                               WHERE left(konto, 5) IN ('10301', '15301')
                           ),
                                qry AS (SELECT rekvid, sum(summa) AS summa
                                        FROM preQry
                                        GROUP BY rekvid)
                           SELECT S.rekvid,
                                  '72'                                                                 AS konto,
                                  ''                                                                   AS grupp,
                                  'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                                  'Korrigeerimine laekumata nõuete muutusega'                          AS nimetus,
                                  summa                                                                AS summa
                           FROM qry S
                       ) qry
                  UNION ALL
--(Jooksva per saldoandmikust (sum: konto 203910 kreedit) - (sum konto 203910 deebet)) - (Eelmise per saldoandmikust (sum kontod 203910 kreedit) - (sum kontod 203910 deebet))
                  SELECT *
                  FROM (
                           WITH preQry AS (
                               SELECT rekvid, -1 * (kr - db) AS summa
                               FROM eelmiseSaldoAndmik e
                               WHERE konto IN ('203910')
                               UNION ALL
                               SELECT rekvid
                                       ,
                                      (kr - db) AS summa
                               FROM qrySaldoAndmik
                               WHERE konto IN ('203910')
                           ),
                                qry AS (SELECT rekvid, sum(summa) AS summa
                                        FROM preQry
                                        GROUP BY rekvid)

                           SELECT S.rekvid,
                                  '72'                                                                 AS konto,
                                  ''                                                                   AS grupp,
                                  'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                                  'Korrigeerimine laekunud ettemaksete muutusega'                      AS nimetus,
                                  summa
                           FROM qry S
                       ) qry
                  UNION ALL
--(Eelmise aruandeper saldoandmikust (sum: kontod 10325* deebet + konto 15325* deebet) - (sum kontod 10325* kreedit + konto 15325* kreedit)) - (Jooksva per saldoandmikust (sum: kontod 10325* deebet + konto 15325* deebet) - (sum kontod 10325* kreedit + konto 15325* kreedit))
                  SELECT *
                  FROM (
                           WITH preQry AS (
                               SELECT rekvid, (db - kr) AS summa
                               FROM eelmiseSaldoAndmik e
                               WHERE left(konto, 5) IN ('10325', '15325')
                               UNION ALL
                               SELECT rekvid
                                       ,
                                      -1 * (db - kr) AS summa
                               FROM qrySaldoAndmik
                               WHERE left(konto, 5) IN ('10325', '15325')
                           ),
                                qry AS (SELECT rekvid, sum(summa) AS summa
                                        FROM preQry
                                        GROUP BY rekvid)


                           SELECT S.rekvid,
                                  '72'                                                                 AS konto,
                                  ''                                                                   AS grupp,
                                  'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                                  'Korrigeerimine järelmaksunõuete muutusega'                          AS nimetus,
                                  summa
                           FROM qry S
                       ) qry
                  UNION ALL
                  -- Jooksva per Saldoandmikust (Sum: Konto 605020 kreedit) - (Sum: Konto 605020 deebet)
                  SELECT S.rekvid,
                         '72'                                                                 AS konto,
                         'Rahavood investeerimistegevusest'                                   AS grupp,
                         'Rahavood investeerimistegevusest'                                   AS all_grupp,
                         'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS nimetus,
                         sum(kr - db)                                                         AS summa
                  FROM qrySaldoAndmik S
                  WHERE konto = '605020'
                  GROUP BY rekvid
              ) qry
         GROUP BY rekvid
                 ,
                  konto
                 ,
                  grupp
         UNION ALL
-- 2019
         SELECT rekvid,
                konto,
                'Rahavood investeerimistegevusest'                                   AS grupp,
                'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_gripp,
                ''                                                                   AS nimetus,
                0                                                                    AS summa,
                sum(summa)::NUMERIC(14, 2)                                           AS eelmise_summa,
                1310                                                                 AS idx
         FROM (
                  SELECT rekvid,
                         '72'                  AS konto,
                         ''                    AS grupp,
                         ''                    AS all_grupp,
                         'Müügist saadud tulu' AS nimetus,
                         sum(kr - db)          AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE konto IN
                        ('381000',
                         '381001',
                         '381100',
                         '381101',
                         '381110',
                         '381111',
                         '381115',
                         '381116',
                         '381120',
                         '381121',
                         '381125',
                         '381126',
                         '381130',
                         '381131',
                         '381140',
                         '381141',
                         '381145',
                         '381146',
                         '381150',
                         '381151',
                         '381160',
                         '381161',
                         '381170',
                         '381171',
                         '381180',
                         '381181',
                         '381300',
                         '381301',
                         '381320',
                         '381321',
                         '381360',
                         '381361',
                         '381400',
                         '381401',
                         '381410',
                         '381411',
                         '381420',
                         '381421')
                  GROUP BY rekvid
                  UNION ALL
                  --(Eelmise aruandeper saldoandmikust (sum: kontod 10301* deebet + konto 15301* deebet) - (sum kontod 10301* kreedit + konto 15301* kreedit)) -
--(Jooksva per saldoandmikust (sum: kontod 10301* deebet + konto 15301* deebet) - (sum kontod 10301* kreedit + konto 15301* kreedit))
                  SELECT *
                  FROM (
                           WITH preQry AS (
                               SELECT rekvid, (db - kr) AS summa
                               FROM vanaSaldoAndmik e
                               WHERE left(konto, 5) IN ('10301', '15301')
                               UNION ALL
                               SELECT rekvid
                                       ,
                                      -1 * (db - kr) AS summa
                               FROM eelmiseSaldoAndmik
                               WHERE left(konto, 5) IN ('10301', '15301')
                           ),
                                qry AS (SELECT rekvid, sum(summa) AS summa
                                        FROM preQry
                                        GROUP BY rekvid)
                           SELECT S.rekvid,
                                  '72'                                                                 AS konto,
                                  ''                                                                   AS grupp,
                                  'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                                  'Korrigeerimine laekumata nõuete muutusega'                          AS nimetus,
                                  summa                                                                AS summa
                           FROM qry S
                       ) qry
                  UNION ALL
--(Jooksva per saldoandmikust (sum: konto 203910 kreedit) - (sum konto 203910 deebet)) - (Eelmise per saldoandmikust (sum kontod 203910 kreedit) - (sum kontod 203910 deebet))
                  SELECT *
                  FROM (
                           WITH preQry AS (
                               SELECT rekvid, -1 * (kr - db) AS summa
                               FROM vanaSaldoAndmik e
                               WHERE konto IN ('203910')
                               UNION ALL
                               SELECT rekvid
                                       ,
                                      (kr - db) AS summa
                               FROM eelmiseSaldoAndmik
                               WHERE konto IN ('203910')
                           ),
                                qry AS (SELECT rekvid, sum(summa) AS summa
                                        FROM preQry
                                        GROUP BY rekvid)

                           SELECT S.rekvid,
                                  '72'                                                                 AS konto,
                                  ''                                                                   AS grupp,
                                  'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                                  'Korrigeerimine laekunud ettemaksete muutusega'                      AS nimetus,
                                  summa
                           FROM qry S
                       ) qry
                  UNION ALL
--(Eelmise aruandeper saldoandmikust (sum: kontod 10325* deebet + konto 15325* deebet) - (sum kontod 10325* kreedit + konto 15325* kreedit)) - (Jooksva per saldoandmikust (sum: kontod 10325* deebet + konto 15325* deebet) - (sum kontod 10325* kreedit + konto 15325* kreedit))
                  SELECT *
                  FROM (
                           WITH preQry AS (
                               SELECT rekvid, (db - kr) AS summa
                               FROM vanaSaldoAndmik e
                               WHERE left(konto, 5) IN ('10325', '15325')
                               UNION ALL
                               SELECT rekvid
                                       ,
                                      -1 * (db - kr) AS summa
                               FROM eelmiseSaldoAndmik
                               WHERE left(konto, 5) IN ('10325', '15325')
                           ),
                                qry AS (SELECT rekvid, sum(summa) AS summa
                                        FROM preQry
                                        GROUP BY rekvid)


                           SELECT S.rekvid,
                                  '72'                                                                 AS konto,
                                  ''                                                                   AS grupp,
                                  'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                                  'Korrigeerimine järelmaksunõuete muutusega'                          AS nimetus,
                                  summa
                           FROM qry S
                       ) qry
                  UNION ALL
                  -- Jooksva per Saldoandmikust (Sum: Konto 605020 kreedit) - (Sum: Konto 605020 deebet)
                  SELECT S.rekvid,
                         '72'                                                                 AS konto,
                         'Rahavood investeerimistegevusest'                                   AS grupp,
                         'Rahavood investeerimistegevusest'                                   AS all_grupp,
                         'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS nimetus,
                         sum(kr - db)                                                         AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE konto = '605020'
                  GROUP BY rekvid
              ) qry
         GROUP BY rekvid
                 ,
                  konto
                 ,
                  grupp
         UNION ALL

         --Jooksva per saldoandmikust (Sum: Konto 1032* kreedit (RV 01) + sum konto 1532* kreedit (RV 01)) - (Sum: Konto 1032* deebet (RV 01)+ sum konto 1532* deebet (RV 01))
/*             SELECT
              S.rekvid,
              '7' AS konto,
              'Rahavood investeerimistegevusest' AS grupp,
              'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
              'Antud laenud' AS nimetus,
              COALESCE(sum(kr - db)
                           FILTER (WHERE LEFT(konto, 4) IN (
                                                            '1032',
                                                            '1532') AND rahavoo =
                                                                        '01'
                               AND kuu = MONTH(l_kpv) AND
                                         aasta = YEAR(l_kpv)), 0
                  )
                  AS summa
             FROM
              qrySaldoAndmik S
             GROUP BY
              rekvid
             UNION ALL
*/--Jooksva per saldoandmikust (Sum: Konto 1032* kreedit (RV 02) + sum konto 1532* kreedit (RV 02)) - (Sum: Konto 1032* deebet (RV 02)+ sum konto 1532* deebet (RV 02))

         SELECT S.rekvid,
                '7'                                AS konto,
                'Rahavood investeerimistegevusest' AS grupp,
                'Tagasi makstud laenud'            AS all_grupp,
                ''                                 AS nimetus,
                sum(kr - db)                       AS summa,
                0::NUMERIC(14, 2)                  AS eelmise_summa,
                1345                               AS idx
         FROM qrySaldoAndmik S
         WHERE LEFT(konto, 4) IN ('1032', '1532')
           AND rahavoo = '02'
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT S.rekvid,
                '7'                                AS konto,
                'Rahavood investeerimistegevusest' AS grupp,
                'Tagasi makstud laenud'            AS all_grupp,
                ''                                 AS nimetus,
                0                                  AS summa,
                sum(kr - db)::NUMERIC(14, 2)       AS eelmise_summa,
                1345                               AS idx
         FROM eelmiseSaldoAndmik S
         WHERE LEFT(konto, 4) IN ('1032', '1532')
           AND rahavoo = '02'
         GROUP BY rekvid
         UNION ALL
         -- --Jooksva per saldoandmikust (Sum: Konto 150* kreedit (RV 01)) - (Sum: Konto 150* deebet (RV 01))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '7'                                AS konto,
                         'Rahavood investeerimistegevusest' AS grupp,
                         'Tasutud osaluste soetamisel'      AS all_grupp,
                         ''                                 AS nimetus,
                         sum(kr - db)                       AS summa,
                         0                                  AS eelmise_summa,
                         1345                               AS idx
                  FROM qrySaldoAndmik S
                  WHERE left(konto, 3) = '150'
                    AND rahavoo = '01'
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '7'                                AS konto,
                         'Rahavood investeerimistegevusest' AS grupp,
                         'Tasutud osaluste soetamisel'      AS all_grupp,
                         ''                                 AS nimetus,
                         0                                  AS summa,
                         sum(kr - db)                       AS eelmise_summa,
                         1345                               AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE left(konto, 3) = '150'
                    AND rahavoo = '01'
                  GROUP BY rekvid
              ) qry
         UNION ALL
         -- (Jooksva per saldoandmikust (Sum: Konto 655500 kreedit+ konto 652010 kreedit) - (sum konto 655500  deebet + konto 652010 deebet) +
         -- (sum 103110 kreedit RV 02 - Sum Konto 103110 deebet RV 02))
         SELECT *
         FROM (
                  SELECT S.rekvid,
                         '7'                                AS konto,
                         'Rahavood investeerimistegevusest' AS grupp,
                         'Laekunud dividendid'              AS all_grupp,
                         ''                                 AS nimetus,
                         sum(kr - db)                       AS summa,
                         0                                  AS eelmise_summa,
                         1345                               AS idx
                  FROM qrySaldoAndmik S
                  WHERE konto IN ('655500', '652010')
                     OR (konto = '103110' AND rahavoo = '02')
                  GROUP BY rekvid
                  UNION ALL
                  SELECT S.rekvid,
                         '7'                                AS konto,
                         'Rahavood investeerimistegevusest' AS grupp,
                         'Laekunud dividendid'              AS all_grupp,
                         ''                                 AS nimetus,
                         0                                  AS summa,
                         sum(kr - db)                       AS eelmise_summa,
                         1345                               AS idx
                  FROM eelmiseSaldoAndmik S
                  WHERE konto IN ('655500', '652010')
                     OR (konto = '103110' AND rahavoo = '02')
                  GROUP BY rekvid
              ) qry
         UNION ALL


         --(Eelmise per saldoandmikust (Sum konto 103540 deebet) - (sum konto 103540 kreedit) - (sum konto 203540 kreedit) + (sum konto 203540 deebet))
-- - (sum konto 257800 kreedit) +
-- (sum konto 257800 deebet)) -
--(Jooksva per saldoandmikust (Sum: Konto 103540 deebet) - (sum konto 103540 kreedit) -
--(konto 203540 kreedt) + (konto 203540 deebet) -
--(konto 257800 kreedit) + (konto 257800 deebet))
/*             SELECT
              S.rekvid,
              '7' AS konto,
              'Rahavood investeerimistegevusest' AS grupp,
              'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
              'Korrigeerimine laenutegevuseks saadud sihtfinantseerimise muutusega' AS nimetus,
              (COALESCE(sum(db - kr)
                            FILTER (WHERE konto =
                                          '103540'
                                AND kuu = 12 AND
                                          aasta = YEAR(l_kpv) - 1), 0) -
               COALESCE(sum(kr)
                            FILTER (WHERE konto =
                                          '203540'
                                AND kuu = MONTH(l_kpv) AND
                                          aasta = YEAR(l_kpv)), 0) +
               COALESCE(sum(db)
                            FILTER (WHERE konto =
                                          '203540'
                                AND kuu = MONTH(l_kpv) AND
                                          aasta = YEAR(l_kpv)), 0) -
               COALESCE(sum(kr)
                            FILTER (WHERE konto =
                                          '257800'
                                AND kuu = 12 AND
                                          aasta = YEAR(l_kpv) - 1), 0) +
               COALESCE(sum(db)
                            FILTER (WHERE konto =
                                          '257800'
                                AND kuu = 12 AND
                                          aasta = YEAR(l_kpv) - 1), 0)
                  )
                  -
              (
                                  COALESCE
                                      (
                                          sum
                                              (
                                                      db
                                                      -
                                                      kr
                                              )
                                                      FILTER
                                                          (
                                                          WHERE konto = '103540'
                                                          AND kuu = MONTH(l_kpv
                                                              )
                                                          AND
                                                                aasta
                                                                    =
                                                                YEAR
                                                                    (
                                                                        l_kpv
                                                                    )
                                                          )
                                      ,
                                          0
                                      )
                                  -
                                  COALESCE
                                      (
                                          sum
                                              (
                                                  kr
                                              )
                                                  FILTER
                                                      (
                                                      WHERE konto = '203540 '
                                                      AND kuu = MONTH(l_kpv
                                                          )
                                                      AND
                                                            aasta
                                                                =
                                                            YEAR
                                                                (
                                                                    l_kpv
                                                                )
                                                      )
                                      ,
                                          0
                                      )
                              +
                                  COALESCE
                                      (
                                          sum
                                              (
                                                  db
                                              )
                                                  FILTER
                                                      (
                                                      WHERE konto = '203540'
                                                      AND kuu = MONTH(l_kpv
                                                          )
                                                      AND
                                                            aasta
                                                                =
                                                            YEAR
                                                                (
                                                                    l_kpv
                                                                )
                                                      )
                                      ,
                                          0
                                      )
                          -
                                  COALESCE
                                      (
                                          sum
                                              (
                                                  kr
                                              )
                                                  FILTER
                                                      (
                                                      WHERE konto = '257800'
                                                      AND kuu = MONTH(l_kpv
                                                          )
                                                      AND
                                                            aasta
                                                                =
                                                            YEAR
                                                                (
                                                                    l_kpv
                                                                )
                                                      )
                                      ,
                                          0
                                      )
                      +
                                  COALESCE
                                      (
                                          sum
                                              (
                                                  db
                                              )
                                                  FILTER
                                                      (
                                                      WHERE konto = '257800'
                                                      AND kuu = MONTH(l_kpv
                                                          )
                                                      AND
                                                            aasta
                                                                =
                                                            YEAR
                                                                (
                                                                    l_kpv
                                                                )
                                                      )
                                      ,
                                          0
                                      )
                  )
                  AS summa
             FROM
              qrySaldoAndmik S
             GROUP BY
              rekvid
             UNION ALL
*/--             Jooksva per saldoandmikust (Konto 4502* kreedit-deebet) + 1KDRV24
--             + (Jooksva per saldoandmikust (konto 203556, 203557, 253550 kreedit miinus deebet)
--             - (sum konto 103856, 103857, 1537 deebet miinus kreedit)
--             - (Eelmise per saldoandmikust (sum kontod 203556, 203557, 253550 kreedit miinus deebet)
--             + (Eelmise per saldoandmikust (konto 103856, 103857, 1537 deebet miinus kreedit)

/*             SELECT
              * FROM
              (
                  WITH osa_1 AS (
                      SELECT rekvid, sum(kr - db) AS summa
                      FROM qrySaldoAndmik
                          WHERE
                           (left(konto, 4) = '4502'
                                OR konto IN ('203556', '203557', '253550')
                                OR (left(konto, 1) = '1'
                                   AND rahavoo = '24')
                               )
                          GROUP BY
                           rekvid
                          UNION ALL
                          SELECT
                           rekvid,
                           -1 * sum(db - kr) AS summa
                          FROM
                           qrySaldoAndmik
                          WHERE
                           (konto IN ('103856', '103857')
                                OR left(konto, 4) = '1537'
                               )
                          GROUP BY
                           rekvid
                  ),
                       osa_2 AS (
                           SELECT rekvid, sum(kr - db) AS summa
                           FROM eelmiseSaldoAndmik
                               WHERE
                                (konto IN ('203556', '203557', '253550'))
                               GROUP BY
                                rekvid
                               UNION ALL
                                -- поправил знак на минус
                               SELECT
                                rekvid,
                                -1 * sum(db - kr) AS summa
                               FROM
                                eelmiseSaldoAndmik
                               WHERE
                                (konto IN ('103856', '103857')
                                     OR left(konto, 4) = '1537')
                               GROUP BY
                                rekvid
                       ),
                       preQry AS (
                           SELECT rekvid,
                                  sum(summa) AS summa
                           FROM osa_1
                               GROUP BY
                                rekvid
                               UNION ALL
                               SELECT
                                rekvid,
                                -1 * sum(summa)
                               FROM
                                osa_2
                               GROUP BY
                                rekvid
                       )
                  SELECT S.rekvid,
                         '7'                                              AS konto,
                         'Rahavood investeerimistegevusest'               AS grupp,
                         ''                                               AS all_grupp,
                         'Tasutud sihtfinantseerimine põhivara soetuseks' AS nimetus,
                         sum(summa)                                       AS summa
                  FROM preQry S
                      GROUP BY rekvid
              ) qry
             UNION ALL
*/-- --Jooksva per saldoandmikust (Sum: Konto 101* kreedit (RV 02) + sum konto 151* kreedit (RV 02)) - (Sum: Konto 101* deebet (RV 02)+ sum konto 151* deebet (RV 02))
/*             SELECT
              S.rekvid,
              '7' AS konto,
              'Rahavood investeerimistegevusest' AS grupp,
              '' AS all_grupp,
              'Laekunud finantsinvesteeringute müügist' AS nimetus,
              COALESCE(sum(kr - db)
                           FILTER (WHERE LEFT(konto, 3) IN (
                                                            '101',
                                                            '151') AND rahavoo =
                                                                       '02'
                               AND kuu = MONTH(l_kpv) AND
                                         aasta = YEAR(l_kpv)), 0
                  )
                  AS summa
             FROM
              qrySaldoAndmik S
             GROUP BY
              rekvid
             UNION ALL
*/--
-- --Jooksva per saldoandmikust (Sum: Konto 150* kreedit (RV 02)) - (Sum: Konto 150* deebet (RV 02))
/*             SELECT
              S.rekvid,
              '7' AS konto,
              'Rahavood investeerimistegevusest' AS grupp,
              '' AS all_grupp,
              'Laekunud osaluste müügist' AS nimetus,
              COALESCE(sum(kr - db)
                           FILTER (WHERE LEFT(konto, 3) IN (
                               '150') AND rahavoo =
                                          '02'
                               AND kuu = MONTH(l_kpv) AND
                                         aasta = YEAR(l_kpv)), 0
                  )
                  AS summa
             FROM
              qrySaldoAndmik S
             GROUP BY
              rekvid
             UNION ALL
*/ --(Eelmise per saldoandmikust (Sum konto 10310* deebet) - (sum konto 10310* kreedit)) +
--(Jooksva per saldoandmikust (Sum: Konto 6580* kreedit) - (sum konto 6580* deebet) +
--(konto 658910 kreedit) - (konto 658910 deebet) -
--(sum 10310* deebet - Sum Konto 10310* kreedit )) + (Sum: Konto 655* kreedit - konto 655* deebet) -
--((sum 101* deebet RV 21, 29, 22) - (sum 101* kreedit RV 21, 29, 22)) -
--((Sum: Konto 151* deebet RV 21, 29, 22) - (konto 151* kreedit RV 21, 29, 22)) -
--(konto 655500 kreedit miinus konto 655500 deebet) -
--((sum 1032* deebet RV 22 - sum 1032* kreedit RV 22 + sum 1532* deebet RV 22 - sum 1532* kreedit RV 22)) +
--((konto 101900 deebet RV 21 - konto 101900 kreedit RV 21))
         SELECT *
         FROM (
                  WITH osa_1 AS (
                      -- Eelmise per saldoandmikust (Sum konto 10310* deebet) - (sum konto 10310* kreedit))
                      SELECT rekvid,
                             db - kr AS summa
                      FROM eelmiseSaldoAndmik
                      WHERE left(konto, 5) = '10310'
                  ),
                       osa_2 AS (
                           -- (Jooksva per saldoandmikust (Sum: Konto 6580* kreedit) - (sum konto 6580* deebet) + (konto 658910 kreedit) - (konto 658910 deebet)
                           SELECT rekvid,
                                  kr - db AS summa
                           FROM qrySaldoAndmik
                           WHERE (left(konto, 4) IN ('6580')
                               OR konto IN ('658910'))),
                       osa_3 AS (
                           -- sum 10310* deebet - Sum Konto 10310* kreedit
                           SELECT rekvid,
                                  db - kr AS summa
                           FROM qrySaldoAndmik
                           WHERE left(konto, 5) IN ('10310')
                       ),
                       osa_4 AS (
                           --  (Sum: Konto 655* kreedit - konto 655* deebet)
                           SELECT rekvid,
                                  kr - db AS summa
                           FROM qrySaldoAndmik
                           WHERE left(konto, 3) IN ('655')
                       ),
                       osa_5 AS (
                           --  (sum 101* deebet RV 21, 29, 22) - (sum 101* kreedit RV 21, 29, 22)) - ((Sum: Konto 151* deebet RV 21, 29, 22) - (konto 151* kreedit RV 21, 29, 22))
                           SELECT rekvid,
                                  db - kr AS summa
                           FROM qrySaldoAndmik
                           WHERE left(konto, 3) IN ('101', '151')
                             AND rahavoo IN ('21', '29', '22')
                       ),
                       osa_6 AS (
                           -- (konto 655500 kreedit miinus konto 655500 deebet)
                           SELECT rekvid,
                                  kr - db AS summa
                           FROM qrySaldoAndmik
                           WHERE konto = '655500'
                       ),
                       osa_7 AS (
-- ((sum 1032* deebet RV 22 - sum 1032* kreedit RV 22 + sum 1532* deebet RV 22 - sum 1532* kreedit RV 22)) + ((konto 101900 deebet RV 21 - konto 101900 kreedit RV 21))
                           SELECT rekvid,
                                  db - kr AS summa
                           FROM qrySaldoAndmik
                           WHERE (left(konto, 4) IN ('1032', '1532') AND rahavoo = '22'
                               OR konto = '101900' AND rahavoo = '21'
                                     )
                       ),
                       preReport AS (
                           SELECT rekvid, sum(summa) AS summa
                           FROM osa_1
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  sum(summa) AS summa
                           FROM osa_2
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  -1 * sum(summa) AS summa
                           FROM osa_3
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  sum(summa) AS summa
                           FROM osa_4
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  -1 * sum(summa) AS summa
                           FROM osa_5
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  -1 * sum(summa) AS summa
                           FROM osa_6
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  -1 * sum(summa) AS summa
                           FROM osa_7
                           GROUP BY rekvid
                       )
                  SELECT S.rekvid,
                         '7'                                     AS konto,
                         'Rahavood investeerimistegevusest'      AS grupp,
                         'Laekunud intressid ja muu finantstulu' AS all_grupp,
                         ''                                      AS nimetus,
                         summa,
                         0::NUMERIC(14, 2)                       AS eelmise_summa,
                         1350                                    AS idx
                  FROM preReport S
              ) qry
         UNION ALL
-- 2019
         SELECT *
         FROM (
                  WITH osa_1 AS (
                      -- Eelmise per saldoandmikust (Sum konto 10310* deebet) - (sum konto 10310* kreedit))
                      SELECT rekvid,
                             db - kr AS summa
                      FROM vanaSaldoAndmik
                      WHERE left(konto, 5) = '10310'
                  ),
                       osa_2 AS (
                           -- (Jooksva per saldoandmikust (Sum: Konto 6580* kreedit) - (sum konto 6580* deebet) + (konto 658910 kreedit) - (konto 658910 deebet)
                           SELECT rekvid,
                                  kr - db AS summa
                           FROM eelmiseSaldoAndmik
                           WHERE (left(konto, 4) IN ('6580')
                               OR konto IN ('658910'))),
                       osa_3 AS (
                           -- sum 10310* deebet - Sum Konto 10310* kreedit
                           SELECT rekvid,
                                  db - kr AS summa
                           FROM eelmiseSaldoAndmik
                           WHERE left(konto, 5) IN ('10310')
                       ),
                       osa_4 AS (
                           --  (Sum: Konto 655* kreedit - konto 655* deebet)
                           SELECT rekvid,
                                  kr - db AS summa
                           FROM eelmiseSaldoAndmik
                           WHERE left(konto, 3) IN ('655')
                       ),
                       osa_5 AS (
                           --  (sum 101* deebet RV 21, 29, 22) - (sum 101* kreedit RV 21, 29, 22)) - ((Sum: Konto 151* deebet RV 21, 29, 22) - (konto 151* kreedit RV 21, 29, 22))
                           SELECT rekvid,
                                  db - kr AS summa
                           FROM eelmiseSaldoAndmik
                           WHERE left(konto, 3) IN ('101', '151')
                             AND rahavoo IN ('21', '29', '22')
                       ),
                       osa_6 AS (
                           -- (konto 655500 kreedit miinus konto 655500 deebet)
                           SELECT rekvid,
                                  kr - db AS summa
                           FROM eelmiseSaldoAndmik
                           WHERE konto = '655500'
                       ),
                       osa_7 AS (
-- ((sum 1032* deebet RV 22 - sum 1032* kreedit RV 22 + sum 1532* deebet RV 22 - sum 1532* kreedit RV 22)) + ((konto 101900 deebet RV 21 - konto 101900 kreedit RV 21))
                           SELECT rekvid,
                                  db - kr AS summa
                           FROM eelmiseSaldoAndmik
                           WHERE (left(konto, 4) IN ('1032', '1532') AND rahavoo = '22'
                               OR konto = '101900' AND rahavoo = '21'
                                     )
                       ),
                       preReport AS (
                           SELECT rekvid, sum(summa) AS summa
                           FROM osa_1
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  sum(summa) AS summa
                           FROM osa_2
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  -1 * sum(summa) AS summa
                           FROM osa_3
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  sum(summa) AS summa
                           FROM osa_4
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  -1 * sum(summa) AS summa
                           FROM osa_5
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  -1 * sum(summa) AS summa
                           FROM osa_6
                           GROUP BY rekvid
                           UNION ALL
                           SELECT rekvid,
                                  -1 * sum(summa) AS summa
                           FROM osa_7
                           GROUP BY rekvid
                       )
                  SELECT S.rekvid,
                         '7'                                     AS konto,
                         'Rahavood investeerimistegevusest'      AS grupp,
                         'Laekunud intressid ja muu finantstulu' AS all_grupp,
                         ''                                      AS nimetus,
                         0,
                         summa::NUMERIC(14, 2)                   AS eelmise_summa,
                         1350                                    AS idx
                  FROM preReport S
              ) qry
         UNION ALL

         -- Jooksva per saldoandmikust (Sum konto 2081* kreedit (RV 05) - konto 2081* deebet (RV 05) + sum konto 2581* kreedit (RV 05) - konto 2581* deebet (RV 05)
         SELECT S.rekvid,
                '8'                                  AS konto,
                'Rahavood finantseerimistegevusest'  AS grupp,
                'Laekunud laenud'                    AS all_grupp,
                ''                                   AS nimetus,
                COALESCE(sum(kr - db)
                         FILTER (WHERE LEFT(konto, 4) IN ('2081', '2581')
                             AND rahavoo = '05'), 0) AS summa,
                0::NUMERIC(14, 2)                    AS eelmise_summa,
                1400                                 AS idx
         FROM qrySaldoAndmik S
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT S.rekvid,
                '8'                                                  AS konto,
                'Rahavood finantseerimistegevusest'                  AS grupp,
                'Laekunud laenud'                                    AS all_grupp,
                ''                                                   AS nimetus,
                0                                                    AS summa,
                COALESCE(sum(kr - db)
                         FILTER (WHERE LEFT(konto, 4) IN ('2081', '2581')
                             AND rahavoo = '05'), 0)::NUMERIC(14, 2) AS eelmise_summa,
                1400                                                 AS idx
         FROM eelmiseSaldoAndmik S
         GROUP BY rekvid
         UNION ALL

         --Jooksva per saldoandmikust (Sum konto 2081* kreedit (RV 06) - konto 2081* deebet (RV 06) + sum konto 2581* kreedit (RV 06) - konto 2581* deebet (RV 06)
         SELECT S.rekvid,
                '8'                                 AS konto,
                'Rahavood finantseerimistegevusest' AS grupp,
                'Tagasi makstud laenud'             AS all_grupp,
                ''                                  AS nimetus,
                sum(kr - db)                        AS summa,
                0::NUMERIC(14, 2)                   AS eelmise_summa,
                1410                                AS idx
         FROM qrySaldoAndmik S
         WHERE LEFT(konto, 4) IN ('2081', '2581')
           AND rahavoo = '06'
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT S.rekvid,
                '8'                                 AS konto,
                'Rahavood finantseerimistegevusest' AS grupp,
                'Tagasi makstud laenud'             AS all_grupp,
                ''                                  AS nimetus,
                0                                   AS summa,
                sum(kr - db)::NUMERIC(14, 2)        AS eelmise_summa,
                1410                                AS idx
         FROM eelmiseSaldoAndmik S
         WHERE LEFT(konto, 4) IN ('2081', '2581')
           AND rahavoo = '06'
         GROUP BY rekvid
         UNION ALL

         --(Jooksva per saldoandmikust (Sum konto 208100 kreedit - konto 208100 deebet)) - (eelmise per saldoandmikust (sum konto 208100 kreedit- konto 208100 deebet))
         SELECT S.rekvid,
                '8'                                      AS konto,
                'Rahavood finantseerimistegevusest'      AS grupp,
                'Tagasi makstud kapitalirendikohustised' AS all_grupp,
                ''                                       AS nimetus,
                COALESCE(sum(kr - db)
                         FILTER (WHERE LEFT(konto, 4) IN ('2082', '2582')
                             AND rahavoo = '06'), 0)
                                                         AS summa,
                0::NUMERIC(14, 2)                        AS eelmise_summa,
                1420                                     AS idx
         FROM qrySaldoAndmik S
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT S.rekvid,
                '8'                                                  AS konto,
                'Rahavood finantseerimistegevusest'                  AS grupp,
                'Tagasi makstud kapitalirendikohustised'             AS all_grupp,
                ''                                                   AS nimetus,
                0                                                    AS summa,
                COALESCE(sum(kr - db)
                         FILTER (WHERE LEFT(konto, 4) IN ('2082', '2582')
                             AND rahavoo = '06'), 0)::NUMERIC(14, 2) AS eelmise_summa,
                1420                                                 AS idx
         FROM eelmiseSaldoAndmik S
         GROUP BY rekvid
         UNION ALL

         --Tasutud sihtfinantseerimine põhivara soetuseks
--Jooksva per saldoandmikust (Konto 4502* kreedit-deebet) + 1KDRV24+
-- (Jooksva per saldoandmikust (konto 203556, 203557, 253550 kreedit miinus deebet) -
--(sum konto 103856, 103857, 1537 deebet miinus kreedit) -
-- (Eelmise per saldoandmikust (sum kontod 203556, 203557, 253550 kreedit miinus deebet) +
--(Eelmise per saldoandmikust (konto 103856, 103857, 1537 deebet miinus kreedit)
         SELECT rekvid,
                '8'                                              AS konto,
                'Rahavood investeerimistegevusest'               AS grupp,
                'Makstud sihtfinantseerimine põhivara soetuseks' AS all_grupp,
                ''                                               AS nimetus,
                sum(summa)                                       AS summa,
                0::NUMERIC(14, 2)                                AS eelmise_summa,
                1340                                             AS idx
         FROM (
                  SELECT rekvid,
                         (kr - db) AS summa
                  FROM qrySaldoAndmik S
                  WHERE (LEFT(konto, 4) IN ('4502') OR konto IN (
                                                                 '203556',
                                                                 '203557',
                                                                 '253550') OR
                         LEFT(konto, 1) = '1' AND rahavoo = '24')
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (db - kr) AS summa
                  FROM qrySaldoAndmik S
                  WHERE (konto IN ('103856', '103857') OR
                         LEFT(konto, 4) = '1537')
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (kr - db) AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE konto IN ('203556', '203557', '253550')
                  UNION ALL
                  SELECT rekvid
                          ,
                         1 * (db - kr) AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE (konto IN ('103856', '103857') OR
                         LEFT(konto, 4) = '1537')) qry
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT rekvid,
                '8'                                              AS konto,
                'Rahavood investeerimistegevusest'               AS grupp,
                'Makstud sihtfinantseerimine põhivara soetuseks' AS all_grupp,
                ''                                               AS nimetus,
                0                                                AS summa,
                sum(summa)::NUMERIC(14, 2)                       AS eelmise_summa,
                1340                                             AS idx
         FROM (
                  SELECT rekvid,
                         (kr - db) AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE (LEFT(konto, 4) IN ('4502') OR konto IN (
                                                                 '203556',
                                                                 '203557',
                                                                 '253550') OR
                         LEFT(konto, 1) = '1' AND rahavoo = '24')
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (db - kr) AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE (konto IN ('103856', '103857') OR
                         LEFT(konto, 4) = '1537')
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (kr - db) AS summa
                  FROM vanaSaldoAndmik S
                  WHERE konto IN ('203556', '203557', '253550')
                  UNION ALL
                  SELECT rekvid
                          ,
                         1 * (db - kr) AS summa
                  FROM vanaSaldoAndmik S
                  WHERE (konto IN ('103856', '103857') OR
                         LEFT(konto, 4) = '1537')) qry
         GROUP BY rekvid
         UNION ALL
         -- Laekunud sihtfinanteerimine põhivara soetuseks
-- Jooksva per saldoandmikust (Sum: Konto 257* kreedit-deebet (RV 05) + (konto 3502* kreedit miinus deebet) - (konto 3502 RV 19, RV 01 kreedit miinus deebet)+
         -- (Jooksva per saldoandmikust (sum: konto 203856 kreedit + konto 203857 kreedit) - (sum konto 203856 deebet + konto 203857 deebet)) -
         -- (Eelmise per saldoandmikust (sum kontod 203856 kreedit + konto 203857 kreedit) - (sum kontod 203856 deebet + konto 203857 deebet)) +
         -- (Eelmise per saldoandmikust (sum konto 103556 deebet + konto 103557 deebet + 153556 deebet) - (sum konto 103556 kreedit + konto 103557 kreedit + konto 153556 kreedit)) -

         -- (Jooksva per saldoandmikust (sum konto 103556 deebet + konto 103557 deebet + konto 153556 deebet) -
         -- (sum konto 103556 kreedit + konto 103557 kreedit + konto 153556 kreedit))
         SELECT rekvid,
                '8'                                              AS konto,
                'Rahavood investeerimistegevusest'               AS grupp,
                'Laekunud sihtfinanteerimine põhivara soetuseks' AS all_grupp,
                ''                                               AS nimetus,
                sum(summa)                                       AS summa,
                0::NUMERIC(14, 2)                                AS eelmise_summa,
                1340                                             AS idx
         FROM (
                  SELECT rekvid,
                         (kr - db) AS summa
                  FROM qrySaldoAndmik S
                  WHERE (LEFT(konto, 3) IN ('257') AND rahavoo = '05')
                     OR (left(konto, 4) = '3502')
                     OR konto IN ('203856', '203857')
                  UNION ALL
                  SELECT rekvid,
                         -1 * (kr - db) AS summa
                  FROM qrySaldoAndmik S
                  WHERE (LEFT(konto, 4) = '3502' AND rahavoo IN ('19', '01'))
                  UNION ALL
                  SELECT rekvid,
                         -1 * (kr - db) AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE konto IN ('203856', '203857')
                  UNION ALL
                  SELECT rekvid,
                         (db - kr) AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE konto IN ('103556', '103557', '153556')
                  UNION ALL
                  SELECT rekvid,
                         -1 * (db - kr) AS summa
                  FROM qrySaldoAndmik S
                  WHERE konto IN ('103556', '103557', '153556')
              ) qry
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT rekvid,
                '8'                                              AS konto,
                'Rahavood investeerimistegevusest'               AS grupp,
                'Laekunud sihtfinanteerimine põhivara soetuseks' AS all_grupp,
                ''                                               AS nimetus,
                0                                                AS summa,
                sum(summa)::NUMERIC(14, 2)                       AS eelmise_summa,
                1340                                             AS idx
         FROM (
                  SELECT rekvid,
                         (kr - db) AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE (LEFT(konto, 3) IN ('257') AND rahavoo = '05')
                     OR (left(konto, 4) = '3502')
                     OR konto IN ('203856', '203857')
                  UNION ALL
                  SELECT rekvid,
                         -1 * (kr - db) AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE (LEFT(konto, 4) = '3502' AND rahavoo IN ('19', '01'))
                  UNION ALL
                  SELECT rekvid,
                         -1 * (kr - db) AS summa
                  FROM vanaSaldoAndmik S
                  WHERE konto IN ('203856', '203857')
                  UNION ALL
                  SELECT rekvid,
                         (db - kr) AS summa
                  FROM vanaSaldoAndmik S
                  WHERE konto IN ('103556', '103557', '153556')
                  UNION ALL
                  SELECT rekvid,
                         -1 * (db - kr) AS summa
                  FROM eelmiseSaldoAndmik S
                  WHERE konto IN ('103556', '103557', '153556')
              ) qry
         GROUP BY rekvid
         UNION ALL


         --Laekunud liitumistasud
--(Jooksva per saldoandmikust (sum: konto 253800 kreedit + konto 323880 kreedit) - (sum konto 253800 deebet + konto 323880 deebet)) -
--(Eelmise per saldoandmikust (sum konto 253800 kreedit) - (sum kontod 253800 deebet))
         /*            SELECT
                      S.rekvid,
                      '8' AS konto,
                      'Rahavood finantseerimistegevusest' AS grupp,
                      '' AS all_grupp,
                      'Laekunud liitumistasud' AS nimetus,
                      COALESCE(sum(kr - db)
                                   FILTER (WHERE konto IN (
                                                           '253800',
                                                           '323880')
                                       AND kuu = MONTH(l_kpv) AND aasta = YEAR(l_kpv)), 0
                          )
                          -
                      COALESCE
                          (
                              sum
                                  (
                                          kr
                                          -
                                          db
                                  )
                                          FILTER
                                              (
                                              WHERE konto IN ('253800', '323880'
                                              )
                                              AND
                                                    kuu
                                                        =
                                                    12
                                              AND
                                                    aasta
                                                        =
                                                    YEAR
                                                        (
                                                            l_kpv
                                                        )
                                                        -
                                                    1
                                              )
                          ,
                              0
                          )
                          AS summa
                     FROM
                      qrySaldoAndmik S
                     GROUP BY
                      rekvid
                     UNION ALL
         */ --Jooksva per saldoandmikust (Sum konto 650* kreedit - konto 650* deebet) + jooksva per saldoandmikust (konto 203200 kreedit - konto 203200 deebet) -
--(eelmise per saldoandmikust (konto 203200 kreedit- konto 203200 deebet)) + (jooksva per saldoandmikust (konto 209000 kreedit - konto 209000 deebet) -
--(eelmise per saldoandmikust (konto 209000 kreedit - konto 209000 deebet)) + eelmise per saldandmikust (konto 103300 deebet - konto 103300 kreedit)) -
--jooksva per saldoandmikust (konto 103300 deebet - konto 103300 kreedit) + jooksva per saldoandmikust (konto 256* kreedit RV 42 - konto 256* deebet RV 42) +
--jooksva per saldoandmikust (konto 208* kreedit (RV 42) - konto 208* deebet (RV 42)) + jooksva per saldoandmikust (konto 258* kreedit (RV 42) - konto 258* deebet (RV 42))

         SELECT rekvid,
                '8'                                 AS konto,
                'Rahavood finantseerimistegevusest' AS grupp,
                'Makstud intressid'                 AS all_grupp,
                ''                                  AS nimetus,
                sum(summa)                          AS summa,
                0::NUMERIC(14, 2)                   AS eelmise_summa,
                1430                                AS idx
         FROM (
                  SELECT rekvid,
                         kr - db AS summa
                  FROM qrySaldoAndmik q
                  WHERE (konto LIKE
                         '650%' OR konto =
                                   '203200')
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (kr - db) AS summa
                  FROM eelmiseSaldoAndmik s
                  WHERE konto = '203200'
                  UNION ALL
                  SELECT rekvid
                          ,
                         kr - db AS summa
                  FROM qrySaldoAndmik s
                  WHERE konto = '209000'
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (kr - db) AS summa
                  FROM eelmiseSaldoAndmik s
                  WHERE konto = '209000'
                  UNION ALL
                  SELECT rekvid
                          ,
                         (db - kr) AS summa
                  FROM eelmiseSaldoAndmik s
                  WHERE konto = '103300'
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (db - kr) AS summa
                  FROM qrySaldoAndmik s
                  WHERE konto = '103300'
                  UNION ALL
                  SELECT rekvid
                          ,
                         (kr - db) AS summa
                  FROM qrySaldoAndmik s
                  WHERE (konto LIKE '208%' AND rahavoo = '42' OR konto LIKE '258%' AND rahavoo = '42')) qry
         GROUP BY rekvid
         UNION ALL
-- 2019
         SELECT rekvid,
                '8'                                 AS konto,
                'Rahavood finantseerimistegevusest' AS grupp,
                'Makstud intressid'                 AS all_grupp,
                ''                                  AS nimetus,
                0                                   AS summa,
                sum(summa)::NUMERIC(14, 2)          AS eelmise_summa,
                1430                                AS idx
         FROM (
                  SELECT rekvid,
                         kr - db AS summa
                  FROM eelmiseSaldoAndmik q
                  WHERE (konto LIKE
                         '650%' OR konto =
                                   '203200')
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (kr - db) AS summa
                  FROM vanaSaldoAndmik s
                  WHERE konto = '203200'
                  UNION ALL
                  SELECT rekvid
                          ,
                         kr - db AS summa
                  FROM eelmiseSaldoAndmik s
                  WHERE konto = '209000'
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (kr - db) AS summa
                  FROM vanaSaldoAndmik s
                  WHERE konto = '209000'
                  UNION ALL
                  SELECT rekvid
                          ,
                         (db - kr) AS summa
                  FROM vanaSaldoAndmik s
                  WHERE konto = '103300'
                  UNION ALL
                  SELECT rekvid
                          ,
                         -1 * (db - kr) AS summa
                  FROM eelmiseSaldoAndmik s
                  WHERE konto = '103300'
                  UNION ALL
                  SELECT rekvid
                          ,
                         (kr - db) AS summa
                  FROM eelmiseSaldoAndmik s
                  WHERE (konto LIKE '208%' AND rahavoo = '42' OR konto LIKE '258%' AND rahavoo = '42')
              ) qry
         GROUP BY rekvid
         UNION ALL
         -- netto
-- (Jooksva per saldoandmikust (sum konto 7* kreedit - 7* deebet -
-- konto 700002 kreedit - konto 710002 kreedit - konto 700030 kreedit - konto 710030 kreedit +
-- konto 700002 deebet + konto 710002 deebet + konto 700030 deebet + konto 710030 deebet) +
-- kontod 1* kreedit (RV 15 + RV 16) - kontod 1* deebet (RV 15 + RV 16) +
-- kontod 2* kreedit (RV 15 + RV 16 + RV 35 + RV 36) - kontod 2* deebet (RV 15 + RV 16 + RV 35 + RV 36)
         SELECT rekvid,
                '8'                                 AS konto,
                'Rahavood finantseerimistegevusest' AS grupp,
                'Netofinantseerimine eelavest'      AS all_grupp,
                ''                                  AS nimetus,
                sum(summa)                          AS summa,
                sum(eelmise_summa)::NUMERIC(14, 2)  AS eelmise_summa,
                1430                                AS idx
         FROM (
                  SELECT rekvid,
                         kr - db           AS summa,
                         0::NUMERIC(14, 2) AS eelmise_summa
                  FROM qrySaldoAndmik q
                  WHERE konto LIKE '7%'
                  UNION ALL
                  SELECT rekvid,
                         (db - kr)         AS summa,
                         0::NUMERIC(14, 2) AS eelmise_summa
                  FROM qrySaldoAndmik s
                  WHERE konto IN ('700002', '710002', '700030', '710030')
                  UNION ALL
                  SELECT rekvid,
                         kr - db           AS summa,
                         0::NUMERIC(14, 2) AS eelmise_summa
                  FROM qrySaldoAndmik s
                  WHERE konto LIKE '1%'
                    AND rahavoo IN ('15', '16')
                  UNION ALL
                  SELECT rekvid,
                         (kr - db)         AS summa,
                         0::NUMERIC(14, 2) AS eelmise_summa
                  FROM qrySaldoAndmik s
                  WHERE konto LIKE '2%'
                    AND rahavoo IN ('15', '16', '35', '36')
                  UNION ALL
-- 2019
                  SELECT rekvid,
                         0::NUMERIC(14, 2) AS summa,
                         kr - db           AS eelmise_summa
                  FROM eelmiseSaldoAndmik q
                  WHERE (konto LIKE
                         '7%')
                  UNION ALL
                  SELECT rekvid,
                         0::NUMERIC(14, 2) AS summa,
                         (db - kr)         AS eelmise_summa
                  FROM eelmiseSaldoAndmik s
                  WHERE konto IN ('700002', '710002', '700030', '710030')
                  UNION ALL
                  SELECT rekvid,
                         0::NUMERIC(14, 2) AS summa,
                         kr - db           AS eelmise_summa
                  FROM eelmiseSaldoAndmik s
                  WHERE konto LIKE '1%'
                    AND rahavoo IN ('15', '16')
                  UNION ALL
                  SELECT rekvid,
                         0::NUMERIC(14, 2) AS summa,
                         (kr - db)         AS eelmise_summa
                  FROM eelmiseSaldoAndmik s
                  WHERE konto LIKE '2%'
                    AND rahavoo IN ('15', '16', '35', '36')
              ) qry
         GROUP BY rekvid
         UNION ALL

         --Eelmise per saldoandmikust (sum konto 100* deebet - konto 100* kreedit) + (sum konto 101100 deebet - konto 101100 kreedit)
         SELECT rekvid,
                '91'                                          AS konto,
                'Raha ja selle ekvivalendid perioodi alguses' AS grupp,
                ''                                            AS all_grupp,
                ''                                            AS nimetus,
                sum(db - kr)                                  AS summa,
                0::NUMERIC(14, 2)                             AS eelmise_summa,
                1520                                          AS idx
         FROM eelmiseSaldoAndmik s
         WHERE (konto LIKE '100%' OR konto = '101100')
         GROUP BY rekvid
         UNION ALL
--2019
         SELECT rekvid,
                '91'                                          AS konto,
                'Raha ja selle ekvivalendid perioodi alguses' AS grupp,
                ''                                            AS all_grupp,
                ''                                            AS nimetus,
                0                                             AS summa,
                sum(db - kr)::NUMERIC(14, 2)                  AS eelmise_summa,
                1520                                          AS idx
         FROM vanaSaldoAndmik s
         WHERE (konto LIKE '100%' OR konto = '101100')
         GROUP BY rekvid
         UNION ALL
         --Jooksva per saldoandmikust (sum konto 100* deebet - konto 100* kreedit) + (sum konto 101100 deebet - konto 101100 kreedit)
         SELECT S.rekvid,
                '92'                                        AS konto,
                'Raha ja selle ekvivalendid perioodi lõpus' AS grupp,
                ''                                          AS all_grupp,
                ''                                          AS nimetus,
                sum(db - kr)                                AS summa,
                0::NUMERIC(14, 2)                           AS eelmise_summa,
                1530                                        AS idx
         FROM qrySaldoAndmik s
         WHERE (konto LIKE '100%' OR konto = '101100')
         GROUP BY rekvid
         UNION ALL
         -- 2019
         SELECT S.rekvid,
                '92'                                        AS konto,
                'Raha ja selle ekvivalendid perioodi lõpus' AS grupp,
                ''                                          AS all_grupp,
                ''                                          AS nimetus,
                0                                           AS summa,
                sum(db - kr)::NUMERIC(14, 2)                AS eelmise_summa,
                1530                                        AS idx
         FROM eelmiseSaldoAndmik s
         WHERE (konto LIKE '100%' OR konto = '101100')
         GROUP BY rekvid
     )
SELECT rekvid                          AS rekv_id,
       grupp :: VARCHAR(254),
       all_grupp::VARCHAR(254),
       konto:: VARCHAR(20),
       nimetus::VARCHAR(254),
       sum(coalesce(summa, 0))         AS summa,
       sum(coalesce(eelmise_summa, 0)) AS eelmise_summa,
       idx
FROM ( --     = korrigeeritud tegevustulem (3) + käibevarade muutus (4) + kohustuste muutus (5)
         SELECT rekvid,
                'Rahavood põhitegevusest'              AS grupp,
                upper('Rahavood põhitegevusest KOKKU') AS all_grupp,
                '60'                                   AS konto,
                ''                                     AS nimetus,
                sum(summa)                             AS summa,
                sum(eelmise_summa)                     AS eelmise_summa,
                1300                                   AS idx
         FROM qrySaldo S
         WHERE S.konto IN ('1', '2', '4', '5')
         GROUP BY rekvid
         UNION ALL
         SELECT rekvid,
                grupp,
                all_grupp,
                konto,
                nimetus,
                summa,
                eelmise_summa,
                idx
         FROM qrySaldo
         UNION ALL
         SELECT rekvid,
                'Rahavood põhitegevusest'                 AS grupp,
                'Korrigeerimised'                         AS all_grupp,
                '3'                                       AS konto,
                upper('Korrigeeritud tegevustulem KOKKU') AS nimetus,
                sum(summa)                                AS summa,
                sum(eelmise_summa)                        AS eelmise_summa,
                1070                                      AS idx
         FROM qrySaldo S
         WHERE S.konto IN ('1', '2')
         GROUP BY rekvid
         UNION ALL
         SELECT rekvid,
                'Rahavood põhitegevusest'                             AS grupp,
                'Põhitegevusega seotud käibevarade netomuutus'        AS all_grupp,
                '40'                                                  AS konto,
                upper('Põhitegevusega seotud käibevarade netomuutus') AS nimetus,
                sum(summa)                                            AS summa,
                sum(eelmise_summa)                                    AS eelmise_summa,
                1190                                                  AS idx
         FROM qrySaldo S
         WHERE S.konto = '4'
         GROUP BY rekvid
         UNION ALL
         SELECT rekvid,
                'Rahavood põhitegevusest'                                  AS grupp,
                'Põhitegevusega seotud kohustiste netomuutus'              AS all_grupp,
                '50'                                                       AS konto,
                upper('Põhitegevusega seotud kohustiste netomuutus KOKKU') AS nimetus,
                sum(summa)                                                 AS summa,
                sum(eelmise_summa)                                         AS eelmise_summa,
                1295                                                       AS idx
         FROM qrySaldo S
         WHERE S.konto = '5'
         GROUP BY rekvid
         UNION ALL
         SELECT rekvid,
                'Rahavood investeerimistegevusest'                               AS grupp,
                'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
                '710'                                                            AS konto,
                ''                                                               AS nimetus,
                sum(summa)                                                       AS summa,
                sum(eelmise_summa)                                               AS eelmise_summa,
                1305                                                             AS idx
         FROM qrySaldo S
         WHERE S.konto IN ('71')
         GROUP BY rekvid
         UNION ALL
         SELECT rekvid,
                'Rahavood investeerimistegevusest'              AS grupp,
                upper('Rahavood investeerimistegevusest KOKKU') AS all_grupp,
                '79'                                            AS konto,
                ''                                              AS nimetus,
                sum(summa)                                      AS summa,
                sum(eelmise_summa)                              AS eelmise_summa,
                1365                                            AS idx
         FROM qrySaldo S
         WHERE S.grupp = 'Rahavood investeerimistegevusest'
         GROUP BY rekvid
         UNION ALL
         SELECT rekvid,
                'Rahavood finantseerimistegevusest'              AS grupp,
                upper('Rahavood finantseerimistegevusest KOKKU') AS all_grupp,
                '80'                                             AS konto,
                ''                                               AS nimetus,
                sum(summa)                                       AS summa,
                sum(eelmise_summa)                               AS eelmise_summa,
                1440                                             AS idx
         FROM qrySaldo S
         WHERE S.grupp = 'Rahavood finantseerimistegevusest'
         GROUP BY rekvid
         UNION ALL
         SELECT rekvid,
                upper('Puhas rahavoog') AS grupp,
                ''                      AS all_grupp,
                '90'                    AS konto,
                ''                      AS nimetus,
                sum(summa)              AS summa,
                sum(eelmise_summa)      AS eelmise_summa,
                1510                    AS idx
         FROM qrySaldo S
         WHERE S.grupp IN ('Rahavood finantseerimistegevusest', 'Rahavood investeerimistegevusest')
            OR S.konto IN ('1', '2', '4', '5')
         GROUP BY rekvid
         UNION ALL
         SELECT rekvid,
                'Raha ja selle ekvivalentide muutus'                        AS grupp,
                ''                                                          AS all_grupp,
                '93'                                                        AS konto,
                ''                                                          AS nimetus,
                COALESCE(sum(summa) FILTER (WHERE konto = '92'), 0) -
                COALESCE(sum(summa) FILTER (WHERE konto = '91'), 0)         AS summa,
                COALESCE(sum(eelmise_summa) FILTER (WHERE konto = '92'), 0) -
                COALESCE(sum(eelmise_summa) FILTER (WHERE konto = '91'), 0) AS eelmise_summa,
                1540                                                        AS idx
         FROM qrySaldo S
         GROUP BY rekvid
     ) qry
GROUP BY rekvid,
         idx,
         grupp,
         all_grupp,
         konto,
         nimetus

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbvaatleja;

SELECT rekv_id,
       summa,
       eelmise_summa,
       grupp,
       all_grupp,
       konto,
       nimetus
FROM eelarve.rahavoog_aruanne('2021-06-30' :: DATE, 63, 1)
--WHERE eelmise_summa <> 0
ORDER BY idx
;


