DROP FUNCTION IF EXISTS eelarve.rahavoog_aruanne( DATE, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    rekv_id   INTEGER,
    grupp     VARCHAR(254),
    all_grupp VARCHAR(254),
    konto     VARCHAR(20),
    nimetus   VARCHAR(254),
    summa     NUMERIC(14, 2)
  ) AS
$BODY$

WITH qrySaldo AS (
  SELECT
    s.rekvid,
    '1'                            AS konto,
    'Rahavood põhitegevusest'      AS grupp,
    ''                             AS all_grupp,
    'Aruandeperioodi tegevustulem' AS nimetus,
    sum(kr) - sum(db)              AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND val(left(ltrim(rtrim(s.konto)), 1)) >= 3 AND val(left(ltrim(rtrim(s.konto)), 2)) <= 64
  GROUP BY rekvid
  UNION ALL
  -- Jooksva per Saldoandmikust (Sum: Kontod 61* deebet) - (Sum: Kontod 61* Kreedit)
  SELECT
    s.rekvid,
    '2'                                       AS konto,
    'Rahavood põhitegevusest'                 AS grupp,
    'Korrigeerimised'                         AS all_grupp,
    'Põhivara amortisatsioon ja ümberhindlus' AS nimetus,
    sum(db) - sum(kr)                         AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND val(left(ltrim(rtrim(s.konto)), 2)) = 61
  GROUP BY rekvid
  UNION ALL
  --Käibemaksukulu põhivara soetamiseks
  --Jooksva per Saldoandmikust (Sum: konto 3502* deebet) - (Sum: konto 3502* kreedit)
  SELECT
    s.rekvid,
    '2'                                             AS konto,
    'Rahavood põhitegevusest'                       AS grupp,
    'Korrigeerimised'                               AS all_grupp,
    'Saadud sihtfinantseerimine põhivara soetuseks' AS nimetus,
    sum(db) - sum(kr)                               AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND s.konto LIKE '3502%'
  GROUP BY rekvid
  UNION ALL
  --Käibemaksukulu põhivara soetamiseks
  --Jooksva per Saldoandmikust (Sum: Kontod 601002 deebet) - (Sum: Kontod 601002 Kreedit)
  SELECT
    s.rekvid,
    '2'                                             AS konto,
    'Rahavood põhitegevusest'                       AS grupp,
    'Korrigeerimised'                               AS all_grupp,
    'Saadud sihtfinantseerimine põhivara soetuseks' AS nimetus,
    sum(db) - sum(kr)                               AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND s.konto LIKE '61%'
  GROUP BY rekvid
  UNION ALL
  --Käibemaksukulu põhivara soetamiseks
  --Jooksva per Saldoandmikust (Sum: Kontod 601002 deebet) - (Sum: Kontod 601002 Kreedit)
  SELECT
    s.rekvid,
    '2'                                   AS konto,
    'Rahavood põhitegevusest'             AS grupp,
    'Korrigeerimised'                     AS all_grupp,
    'Käibemaksukulu põhivara soetamiseks' AS nimetus,
    sum(db) - sum(kr)                     AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND s.konto LIKE '601002%'
  GROUP BY rekvid
  UNION ALL
  --Saadud sihtfinantseerimine põhivara soetuseks
  --Jooksva per Saldoandmikust (Sum: konto 3502* deebet) - (Sum: konto 3502* kreedit)
  SELECT
    s.rekvid,
    '2'                                             AS konto,
    'Rahavood põhitegevusest'                       AS grupp,
    'Korrigeerimised'                               AS all_grupp,
    'Saadud sihtfinantseerimine põhivara soetuseks' AS nimetus,
    sum(db) - sum(kr)                               AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND s.konto LIKE '3502%'
  GROUP BY rekvid
  UNION ALL
  --351
  SELECT
    s.rekvid,
    '2'                                         AS konto,
    'Rahavood põhitegevusest'                   AS grupp,
    'Korrigeerimised'                           AS all_grupp,
    'Saadud sihtfinantseerimise amortisatsioon' AS nimetus,
    sum(db) - sum(kr)                           AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND s.konto LIKE '351%'
  GROUP BY rekvid
  UNION ALL
  -- 323880
  SELECT
    s.rekvid,
    '2'                                    AS konto,
    'Rahavood põhitegevusest'              AS grupp,
    'Korrigeerimised'                      AS all_grupp,
    'Saadud liitumistasude amortisatsioon' AS nimetus,
    sum(db) - sum(kr)                      AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND s.konto LIKE '323880%'
  GROUP BY rekvid
  UNION ALL
  -- Kasum/kahjum pohivara muugist
  SELECT
    s.rekvid,
    '2'                             AS konto,
    'Rahavood põhitegevusest'       AS grupp,
    'Korrigeerimised'               AS all_grupp,
    'Kasum/kahjum pohivara muugist' AS nimetus,
    sum(db) - sum(kr)               AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND left(s.konto, 4) IN ('3810', '3811', '3813', '3814')
  GROUP BY rekvid
  UNION ALL
  --Üle antud mitterahaline sihtfinantseerimine
  --Üle antud mitterahaline sihtfinantseerimine / Antud sihtfinantseerimine põhivara soetuseks
  --Jooksva per Saldoandmikust (4502* deebet miinus kreedit)
  SELECT
    s.rekvid,
    '2'                                            AS konto,
    'Rahavood põhitegevusest'                      AS grupp,
    'Korrigeerimised'                              AS all_grupp,
    'Antud sihtfinantseerimine põhivara soetuseks' AS nimetus,
    sum(db) - sum(kr)                              AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND s.konto LIKE '4502%'
  GROUP BY rekvid
  UNION ALL
  SELECT
    s.rekvid,
    '2'                                        AS konto,
    'Rahavood põhitegevusest'                  AS grupp,
    'Korrigeerimised'                          AS all_grupp,
    'Ebatoenaoliselt laekuvate laenude muutus' AS nimetus,
    sum(db) - sum(kr)                          AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND left(s.konto, 6) IN ('605000', '605010', '605020')
  GROUP BY rekvid
  UNION ALL
  --= aruandeper tegevustulem + korrigeerimised
  SELECT
    s.rekvid,
    '2'                                        AS konto,
    'Rahavood põhitegevusest'                  AS grupp,
    'Korrigeerimised'                          AS all_grupp,
    'Ebatoenaoliselt laekuvate laenude muutus' AS nimetus,
    sum(db) - sum(kr)                          AS summa
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND left(s.konto, 6) IN ('605000', '605010', '605020')
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 102* deebet + kontod 152* deebet) - (sum kontod 102* kreedit+ kontod 152* kreedit))
  -- - (Jooksva per saldoandmikust (sum kontod 102* deebet+ kontod 152* deebet) - (sum kontod 102* kreedit + kontod 152* kreedit))
  SELECT
    s.rekvid,
    '4'                                            AS konto,
    'Rahavood põhitegevusest'                      AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
    'Maksu-, lõivu- ja trahvinõuete muutus'        AS nimetus,
    (coalesce(sum(db)
                FILTER (WHERE left(s.konto, 3) IN ('102', '152') AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
     coalesce(sum(kr)
                FILTER (WHERE left(s.konto, 3) IN ('102', '152') AND kuu = 12 AND aasta = year(l_kpv) - 1), 0)) -
    (coalesce(sum(db)
                FILTER (WHERE left(s.konto, 3) IN ('102', '152') AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
     coalesce(sum(kr)
                FILTER (WHERE left(s.konto, 3) IN ('102', '152') AND kuu = month(l_kpv) AND aasta = year(l_kpv)),
              0))                                  AS summa
  FROM eelarve.saldoandmik s
  WHERE left(s.konto, 3) IN ('102', '152')
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 10300* deebet + kontod 15300* deebet) - (sum kontod 10300* kreedit + kontod 15300* kreedit)) - (Jooksva per saldoandmikust (sum kontod 10300* deebet + kontod 15300* deebet) - (sum kontod 10300* kreedit + kontod 15300* kreedit))
  SELECT
    s.rekvid,
    '4'                                                                      AS konto,
    'Rahavood põhitegevusest'                                                AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus'                           AS all_grupp,
    'Muutus nõuetes ostjate vastu'                                           AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  WHERE left(s.konto, 5) IN ('10300', '15300')
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 103190 deebet) - (sum kontod 103190 kreedit)) - (Jooksva per saldoandmikust (sum kontod 103190 deebet) - (sum kontod 103190 kreedit))
  SELECT
    s.rekvid,
    '4'                                                                      AS konto,
    'Rahavood põhitegevusest'                                                AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus'                           AS all_grupp,
    'Muutus viitlaekumistes'                                                 AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  WHERE s.konto LIKE '103190%'
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 1035* deebet - konto 103500 deebet - konto 103540 deebet - konto 103556 deebet - konto 103557 deebet) -
  --(sum kontod 1035* kreedit - konto 103500 kreedit - konto 103540 kreedit - konto 103556 kreedit - konto 103557 kreedit)) -
  --(Jooksva per saldoandmikust (sum: kontod 1035* deebet - konto 103500 deebet - konto 103540 deebet - konto 103556 deebet - konto 103557 deebet) - (sum kontod 1035* kreedit - konto 103500 kreedit - konto 103540 kreedit - konto 103556 kreedit - konto 103557 kreedit))
  SELECT
    s.rekvid,
    '4'                                                   AS konto,
    'Rahavood põhitegevusest'                             AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus'        AS all_grupp,
    'Muutus nõuetes toetuste ja siirete eest'             AS nimetus,
    (coalesce(sum(db)
                FILTER (WHERE konto LIKE '1035%' AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
     coalesce(sum(db)
                FILTER (WHERE konto IN ('103500', '103540', '103556', '103557') AND kuu = 12 AND
                              aasta = year(l_kpv) - 1), 0)) -
    (coalesce(sum(kr)
                FILTER (WHERE konto LIKE '1035%' AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
     coalesce(sum(kr)
                FILTER (WHERE konto IN ('103500', '103540', '103556', '103557') AND kuu = 12 AND
                              aasta = year(l_kpv) - 1), 0)) -

    ((coalesce(sum(db)
                 FILTER (WHERE konto LIKE '1035%' AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
      coalesce(sum(db)
                 FILTER (WHERE konto IN ('103500', '103540', '103556', '103557') AND kuu = 12 AND
                               aasta = year(l_kpv) - 1), 0)) -
     (coalesce(sum(kr)
                 FILTER (WHERE konto LIKE '1035%' AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
      coalesce(sum(kr)
                 FILTER (WHERE konto IN ('103500', '103540', '103556', '103557') AND kuu = month(l_kpv) AND
                               aasta = year(l_kpv)), 0))) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 1036* deebet + sum kontod 1536* deebet) - (sum kontod 1036* kreedit + sum kontod 1536* kreedit))
  -- - (Jooksva per saldoandmikust (sum kontod 1036* deebet + sum ontod 1536* deebet) - (sum kontod 1036* kreedit + sum kontod 1536* kreedit))
  SELECT
    s.rekvid,
    '4'                                            AS konto,
    'Rahavood põhitegevusest'                      AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
    'Muutus muudes nõuetes'                        AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 4) IN ('1036', '1536') AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 4) IN ('1036', '1536') AND kuu = month(l_kpv) AND aasta = year(l_kpv)),
             0)                                    AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 1037* deebet) - (sum kontod 1037* kreedit)) -
  --(Jooksva per saldoandmikust (sum kontod 1037* deebet) - (sum kontod 1037* kreedit))
  SELECT
    s.rekvid,
    '4'                                                                                             AS konto,
    'Rahavood põhitegevusest'                                                                       AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus'                                                  AS all_grupp,
    'Muutus maksude, lõivude, trahvide ettemaksetes'                                                AS nimetus,
    (coalesce(sum(db)
                FILTER (WHERE konto LIKE '1037%' AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
     coalesce(sum(kr)
                FILTER (WHERE konto LIKE '1037%' AND kuu = 12 AND aasta = year(l_kpv) - 1), 0)) -
    coalesce(sum(db)
               FILTER (WHERE konto LIKE '1037%' AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(kr)
               FILTER (WHERE konto LIKE '1037%' AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 1038* deebet + kontod 1537* deebet) - (sum kontod 1038* kreedit + kontod 1537* kreedit)) -
  --(Jooksva per saldoandmikust (sum kontod 1038* deebet + kontod 1537* deebet) - (sum kontod 1038* kreedit + kontod 1537* kreedit))

  --Muutus toetuste ettemaksetes
  --(Eelmise aruandeper saldoandmikust (sum: kontod 1038* deebet miinus kreedit - 103856, 103857 deebet miinus kreedit) -
  --(Jooksva per saldoandmikust (sum kontod 1038* deebet miinus kreedit miinus kreedit - 103856, 103857 deebet miinus kreedit)
  SELECT
    s.rekvid,
    '4'                                            AS konto,
    'Rahavood põhitegevusest'                      AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
    'Muutus toetuste ettemaksetes'                 AS nimetus,
    (coalesce(sum(db)
                FILTER (WHERE left(konto, 4) IN ('1038', '1537') AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
     coalesce(sum(kr)
                FILTER (WHERE left(konto, 4) IN ('1038', '1537') AND kuu = 12 AND aasta = year(l_kpv) - 1), 0)) -
    (coalesce(sum(db)
                FILTER (WHERE left(konto, 4) IN ('1038', '1537') AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
     coalesce(sum(kr)
                FILTER (WHERE left(konto, 4) IN ('1038', '1537') AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)) -
    (coalesce(sum(db - kr)
                FILTER (WHERE konto LIKE '1038%' AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
     coalesce(sum(db - kr)
                FILTER (WHERE konto IN ('103856', '103857') AND kuu = 12 AND aasta = year(l_kpv) - 1), 0)) -
    (COALESCE(sum(db - kr)
                FILTER (WHERE konto LIKE '1038%' AND kuu = MONTH(l_kpv) AND aasta = YEAR(l_kpv)), 0) -
     COALESCE(sum(db - kr)
                FILTER (WHERE konto IN ('103856', '103857') AND kuu = MONTH(l_kpv) AND aasta = YEAR(l_kpv)),
              0))                                  AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  --(Eelmise aruandeper saldoandmikust (sum: kontod 1039* deebet + konto 153990 deebet) - (sum kontod 1039* kreedit + konto 153990 kreedit)) -
  --(Jooksva per saldoandmikust (sum kontod 1039* deebet + konto 153990 deebet) - (sum kontod 1039* kreedit + konto 153990 kredit))
  UNION ALL
  SELECT
    s.rekvid,
    '4'                                            AS konto,
    'Rahavood põhitegevusest'                      AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
    'Muutus toetuste ettemaksetes'                 AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 4) IN ('1038', '1537') AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 4) IN ('1038', '1537') AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 4) IN ('1038') AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 6) IN ('103856', '103857') AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 4) IN ('1038') AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 6) IN ('103856', '103857') AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)

                                                   AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 1039* deebet + konto 153990 deebet) - (sum kontod 1039* kreedit + konto 153990 kreedit)) -
  --(Jooksva per saldoandmikust (sum kontod 1039* deebet + konto 153990 deebet) - (sum kontod 1039* kreedit + konto 153990 kredit))
  SELECT
    s.rekvid,
    '4'                                                 AS konto,
    'Rahavood põhitegevusest'                           AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus'      AS all_grupp,
    'Muutus muudes ettemaksetes'                        AS nimetus,
    ((coalesce(sum(db)
                 FILTER (WHERE (konto LIKE '1039%' OR konto = '153990') AND kuu = 12 AND
                               aasta = year(l_kpv) - 1), 0)) -
     (coalesce(sum(kr)
                 FILTER (WHERE (konto LIKE '1039%' OR konto = '153990') AND kuu = 12 AND
                               aasta = year(l_kpv) - 1), 0))) -
    (coalesce(sum(db)
                FILTER (WHERE (konto LIKE '1039%' OR konto = '153990') AND kuu = month(l_kpv) AND
                              aasta = year(l_kpv)), 0)) -
    (coalesce(sum(kr)
                FILTER (WHERE (konto LIKE '1039%' OR konto = '153990') AND kuu = month(l_kpv) AND
                              aasta = year(l_kpv)), 0)) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 108* deebet) - (sum kontod 108* kreedit)) - (Jooksva per saldoandmikust (sum kontod 108* deebet) - (sum kontod 108* kreedit))
  SELECT
    s.rekvid,
    '4'                                               AS konto,
    'Rahavood põhitegevusest'                         AS grupp,
    'Põhitegevusega seotud käibevarade netomuutus'    AS all_grupp,
    'Muutus varudes'                                  AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE konto LIKE '108%' AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE konto LIKE '108%' AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: kontod 200* kreedit) - (sum kontod 200* deebet)) - (Eelmise per saldoandmikust (sum kontod 200* kreedit) - (sum kontod 200* deebet))
  SELECT
    s.rekvid,
    '5'                                                     AS konto,
    'Rahavood põhitegevusest'                               AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'           AS all_grupp,
    'Muutus saadud maksude, lõivude, trahvide ettemaksetes' AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '200%' AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '200%' AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0)   AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 201000 kreedit + konto 25000* kreedit) - (sum konto 201000 deebet + konto 25000* deebet)) -
  --(Eelmise per saldoandmikust (sum kontod 201000 kreedit + konto 25000* kreedit) - (sum kontod 201000 deebet + konto 25000* deebet))
  SELECT
    s.rekvid,
    '5'                                                   AS konto,
    'Rahavood põhitegevusest'                             AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'         AS all_grupp,
    'Muutus võlgades hankjatele'                          AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '201000%' OR konto LIKE '25000%') AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '201000%' OR konto LIKE '25000%') AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 202* kreedit) - (sum konto 202* deebet)) - (Eelmise per saldoandmikust (sum kontod 202* kreedit) - (sum kontod 202* deebet))
  SELECT
    s.rekvid,
    '5'                                                   AS konto,
    'Rahavood põhitegevusest'                             AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'         AS all_grupp,
    'Muutus võlgades töövõtjatele'                        AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '202%' AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '202%' AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 2030* kreedit + konto 2530* kreedit) - (sum konto 2030* deebet + konto 2530* deebet)) - (Eelmise per saldoandmikust (sum kontod 2030* kreedit + konto 2530* kreedit) - (sum kontod 2030* deebet + konto 2530* deebet))
  SELECT
    s.rekvid,
    '5'                                                   AS konto,
    'Rahavood põhitegevusest'                             AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'         AS all_grupp,
    'Muutus maksu-, lõivu- ja trahvikohustustes'          AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2030', '2530') AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2030', '2530') AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 203290 kreedit) - (sum konto 203290 deebet)) - (Eelmise per saldoandmikust (sum kontod 203290 kreedit) - (sum kontod 203290 deebet))
  SELECT
    s.rekvid,
    '5'                                                   AS konto,
    'Rahavood põhitegevusest'                             AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'         AS all_grupp,
    'Muutus viitvõlgades'                                 AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '203290%' AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '203290%' AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Muutus toetuste ja siirete kohustustes
  --(Jooksva per saldoandmikust (sum: konto 2035* kreedit miinus deebet- konto 203500, 203540, 203556, 203557 kreedit miinus deebet) -
  --(Eelmise per saldoandmikust (sum kontod 2035* kreedit miinus deebet - konto 203500, 203540, 203556, 203557 kreedit miinus de
  --Muutus toetuste ja siirete kohustustes
  SELECT
    s.rekvid,
    '5'                                                   AS konto,
    'Rahavood põhitegevusest'                             AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'         AS all_grupp,
    'Muutus toetuste ja siirete kohustustes'              AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '2035%' AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 6) IN ('203500', '203540', '203556', '203557') AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '2035%' AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 6) IN ('203500', '203540', '203556', '203557') AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 2036* kreedit + konto 2536* kreedit) - (sum konto 2036* deebet + 2536* deebet)) - (Eelmise per saldoandmikust (sum kontod 2036* kreedit + 2536* kreedit) - (sum kontod 2036* deebet + 2536* deebet))
  SELECT
    s.rekvid,
    '5'                                                   AS konto,
    'Rahavood põhitegevusest'                             AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'         AS all_grupp,
    'Muutus muudes kohustustes'                           AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2036', '2536') AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2036', '2536') AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 2038* kreedit - konto 203856 kreedit- konto 203857 kreedit) -
  --(sum konto 2038* deebet - konto 203856 deebet - konto 203857 deebet)) -
  --(Eelmise per saldoandmikust (sum: konto 2038* kreedit - konto 203856 kreedit- konto 203857 kreedit) -
  --(sum konto 2038* deebet - konto 203856 deebet - konto 203857 deebet))
  SELECT
    s.rekvid,
    '5'                                                     AS konto,
    'Rahavood põhitegevusest'                               AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'           AS all_grupp,
    'Muutus saadud toetuste ettemaksetes'                   AS nimetus,
    (
      coalesce(sum(kr)
                 FILTER (WHERE konto LIKE '2038%' AND kuu = month(l_kpv) AND
                               aasta = year(l_kpv)), 0) +
      coalesce(sum(kr)
                 FILTER (WHERE konto IN ('203856', '203857') AND kuu = month(l_kpv) AND
                               aasta = year(l_kpv)), 0) -
      (coalesce(sum(db)
                  FILTER (WHERE konto LIKE '2038%' AND kuu = month(l_kpv) AND
                                aasta = year(l_kpv)), 0) +
       coalesce(sum(db)
                  FILTER (WHERE konto IN ('203856', '203857') AND kuu = month(l_kpv) AND
                                aasta = year(l_kpv)), 0))
    ) -
    ((coalesce(sum(kr)
                 FILTER (WHERE konto LIKE '2038%' AND kuu = 12 AND
                               aasta = year(l_kpv) - 1), 0) +
      coalesce(sum(kr)
                 FILTER (WHERE konto IN ('203856', '203857') AND kuu = 12 AND
                               aasta = year(l_kpv) - 1), 0)) -
     coalesce(sum(db)
                FILTER (WHERE konto LIKE '2038%' AND kuu = 12 AND
                              aasta = year(l_kpv) - 1), 0) +
     coalesce(sum(db)
                FILTER (WHERE konto IN ('203856', '203857') AND kuu = 12 AND
                              aasta = year(l_kpv) - 1), 0)) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 203900 kreedit + konto 203990 kreedit + konto 253890 kreedit) - (sum konto 203900 deebet + konto 203990 deebet + konto 253890 deebet)) - (Eelmise per saldoandmikust (sum kontod 203900 kreedit + konto 203990 kreedit + konto 253890 kreedit) - (sum kontod 203900 deebet + konto 203990 deebet + konto 253890 deebet))
  SELECT
    s.rekvid,
    '5'                                                     AS konto,
    'Rahavood põhitegevusest'                               AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'           AS all_grupp,
    'Muutus muudes saadud ettemaksetes'                     AS nimetus,
    (
      coalesce(sum(kr)
                 FILTER (WHERE konto IN ('203900', '203990', '253890') AND kuu = month(l_kpv) AND
                               aasta = year(l_kpv)), 0) -
      coalesce(sum(db)
                 FILTER (WHERE konto IN ('203900', '203990', '253890') AND kuu = month(l_kpv) AND
                               aasta = year(l_kpv)), 0)) -
    (coalesce(sum(kr)
                FILTER (WHERE konto IN ('203900', '203990', '253890') AND kuu = 12 AND
                              aasta = year(l_kpv) - 1), 0) -
     coalesce(sum(db)
                FILTER (WHERE konto IN ('203900', '203990', '253890') AND kuu = 12 AND
                              aasta = year(l_kpv) - 1), 0)) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (sum: ((konto 206* kreedit RV 41, 49, 05, 06) - (konto 206030 kreedit RV 41, 49, 05, 06))+ (konto 256* kreedit RV 41, 49, 05, 06) -
  --((sum konto 206* deebet RV 41, 49, 05, 06) - (konto 206030 deebet RV 41, 49, 05, 06)) - (konto 256* deebet RV 41, 49, 06, 05))
  SELECT
    s.rekvid,
    '5'                                                    AS konto,
    'Rahavood põhitegevusest'                              AS grupp,
    'Põhitegevusega seotud kohustuste netomuutus'          AS all_grupp,
    'Muutus eraldistes'                                    AS nimetus,
    (
      (coalesce(sum(kr)
                  FILTER (WHERE konto LIKE '206%' AND rahavoo IN ('41', '49', '05', '06') AND kuu = month(l_kpv) AND
                                aasta = year(l_kpv)), 0) -
       coalesce(sum(kr)
                  FILTER (WHERE konto = '206030' AND rahavoo IN ('41', '49', '05', '06') AND kuu = month(l_kpv) AND
                                aasta = year(l_kpv)), 0) +
       coalesce(sum(kr)
                  FILTER (WHERE konto LIKE '256%' AND rahavoo IN ('41', '49', '05', '06') AND kuu = month(l_kpv) AND
                                aasta = year(l_kpv)), 0)) -

      (coalesce(sum(db)
                  FILTER (WHERE konto LIKE '206%' AND rahavoo IN ('41', '49', '05', '06') AND kuu = month(l_kpv) AND
                                aasta = year(l_kpv)), 0) -
       coalesce(sum(db)
                  FILTER (WHERE konto = '206030' AND rahavoo IN ('41', '49', '05', '06') AND kuu = month(l_kpv) AND
                                aasta = year(l_kpv)), 0) +
       coalesce(sum(db)
                  FILTER (WHERE konto LIKE '256%' AND rahavoo IN ('41', '49', '05', '06') AND kuu = month(l_kpv) AND
                                aasta = year(l_kpv)), 0))) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --25.05.2012
  --Materiaalse ja immateriaalse põhivara soetus
  --Jooksva per saldoandmikust (Konto 155* kreedit (RV 01)) - (Sum: Konto 155* deebet (RV 01)) +(Sum: Konto 156* kreedit (RV 01)) - (Sum: Konto 156* deebet (RV 01)) +
  --( 601002 Kreedit miinus deebet)+(650990 kreedit - deebet) + (sum: konto 2082* kreedit (RV 01; RV 05))
  -- - (sum: konto 2082* deebet (RV 01; RV 05)) + (sum: konto 2582* kreedit (RV 01; RV 05)) - (sum: konto 2582* deebet (RV 01; RV 05)) +
  --(sum: konto 350200 kreedit (RV 01)) - (sum: konto 350200 deebet (RV 01)) + (sum: konto 350220 kreedit (RV 01)) - (sum: konto 350220 deebet (RV 01)) + (sum: konto 350240 kreedit (RV 01)) - (sum: konto 350240 deebet RV 01)) +
  -- (sum 257* kreedit (RV 01)) - (sum 257* kreedit RV 01)) +
  -- (sum: konto 2086* kreedit (RV 01; RV 05)) - (sum: konto 2086* deebet (RV 01; RV 05)) + (sum: konto 2586* kreedit (RV 01; RV 05)) - (sum: konto 2586* deebet (RV 01; RV 05))  +
  --(Jooksva per saldoandmikust (sum: konto 201010 kreedit + konto 25001* kreedit) - (sum konto 201010 deebet + konto 25001* deebet)) -
  --(Eelmise per saldoandmikust (sum kontod 201010 kreedit + konto 25001* kreedit) - (sum kontod 201010 deebet + konto 25001* deebet))

  --Jooksva per saldoandmikust (Konto 155* kreedit (RV 01)) - (Sum: Konto 155* deebet (RV 01)) +(Sum: Konto 156* kreedit (RV 01)) - (Sum: Konto 156* deebet (RV 01)) +( 601002 Kreedit miinus deebet)+(650990 kreedit - deebet) + (sum: konto 2082* kreedit (RV 01;
  SELECT
    s.rekvid,
    '71'                                                             AS konto,
    'Rahavood investeerimistegevusest'                               AS grupp,
    'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Materiaalse ja immateriaalse põhivara soetus'                   AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE ((left(konto, 3) IN ('155', '156', '257') AND rahavoo = '01')
                              OR (konto IN ('601002', '650990'))
                              OR (left(konto, 4) IN ('2082', '2582', '2086', '2586') AND rahavoo IN ('01', '05'))
                              OR (konto IN ('350200', '350220', '350240') AND rahavoo = '01')
                              OR konto = '201010'
                              OR left(konto, 5) = '25001')
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE ((konto = '201010' OR left(konto, 5) = '25001')
                              AND kuu = 12 AND
                              aasta = year(l_kpv) - 1)), 0)          AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  -- -Jooksva per saldoandmikust (Sum: Konto 154* kreedit (RV 01)) - (Sum: Konto 154* deebet (RV 01))
  SELECT
    s.rekvid,
    '71'                                                             AS konto,
    'Rahavood investeerimistegevusest'                               AS grupp,
    'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Kinnisvarainvesteeringute soetus'                               AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (left(konto, 3) IN ('154') AND rahavoo = '01')
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)                AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum: Konto 157* kreedit (RV 01)) - (Sum: Konto 157* deebet (RV 01))
  SELECT
    s.rekvid,
    '71'                                                             AS konto,
    'Rahavood investeerimistegevusest'                               AS grupp,
    'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Bioloogiliste varade soetus'                                    AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (left(konto, 3) IN ('157') AND rahavoo = '01')
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)                AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 201010 kreedit + konto 25001* kreedit) -
  --(sum konto 201010 deebet + konto 25001* deebet)) - (Eelmise per saldoandmikust (sum kontod 201010 kreedit + konto 25001* kreedit) - (sum kontod 201010 deebet + konto 25001* deebet))
  SELECT
    s.rekvid,
    '71'                                                             AS konto,
    'Rahavood investeerimistegevusest'                               AS grupp,
    'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Bioloogiliste varade soetus'                                    AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (left(konto, 3) IN ('157') AND rahavoo = '01')
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)                AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per Saldoandmikust (Sum: Kontod 381000+381001+381100+381101+381110+381111+381115+381116+381120+381121+381125+381126+381130+381131+381140+381141+381145+381146+
  --381150+381151+381160+381161+381170+381171+381180+381181+381300+381301+381320+381321+381360+381361+381400+381401+381410+381411+381420+381421 kreedit)
  -- - (Sum: 381000+381001+381100+381101+381110+381111+381115+381116+381120+381121+381125+381126+381130+381131+381140+381141+381145+381146+381150+381151+381160+
  --381161+381170+381171+381180+381181+381300+381301+381320+381321+381360+381361+381400+381401+381410+381411+381420+381421 deebet)
  SELECT
    s.rekvid,
    '72'                                                                 AS konto,
    'Rahavood investeerimistegevusest'                                   AS grupp,
    'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Müügist saadud tulu'                                                AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto IN
                             ('381000', '381001', '381100', '381101', '381110', '381111', '381115', '381116', '381120', '381121', '381125',
                               '381126', '381130', '381131', '381140', '381141', '381145', '381146', '381150', '381151', '381160', '381161',
                                                                                                                                   '381170', '381171', '381180', '381181', '381300', '381301', '381320', '381321', '381360', '381361', '381400',
                              '381401', '381410', '381411', '381420', '381421')
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)                    AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 10301* deebet + konto 15301* deebet) - (sum kontod 10301* kreedit + konto 15301* kreedit)) -
  --(Jooksva per saldoandmikust (sum: kontod 10301* deebet + konto 15301* deebet) - (sum kontod 10301* kreedit + konto 15301* kreedit))
  SELECT
    s.rekvid,
    '72'                                                                 AS konto,
    'Rahavood investeerimistegevusest'                                   AS grupp,
    'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Korrigeerimine laekumata nõuete muutusega'                          AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 5) IN ('10301', '15301')
                             AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 5) IN ('10301', '15301')
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)

                                                                         AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 203910 kreedit) - (sum konto 203910 deebet)) - (Eelmise per saldoandmikust (sum kontod 203910 kreedit) - (sum kontod 203910 deebet))
  SELECT
    s.rekvid,
    '72'                                                                 AS konto,
    'Rahavood investeerimistegevusest'                                   AS grupp,
    'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Korrigeerimine laekunud ettemaksete muutusega'                      AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '203910'
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '203910'
                             AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0)                AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Eelmise aruandeper saldoandmikust (sum: kontod 10325* deebet + konto 15325* deebet) - (sum kontod 10325* kreedit + konto 15325* kreedit)) - (Jooksva per saldoandmikust (sum: kontod 10325* deebet + konto 15325* deebet) - (sum kontod 10325* kreedit + konto 15325* kreedit))
  SELECT
    s.rekvid,
    '72'                                                                 AS konto,
    'Rahavood investeerimistegevusest'                                   AS grupp,
    'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Korrigeerimine laekunud ettemaksete muutusega'                      AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 5) IN ('10325', '15325')
                             AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0) -

    coalesce(sum(db - kr)
               FILTER (WHERE left(konto, 5) IN ('10325', '15325')
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)                    AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per Saldoandmikust (Sum: Konto 605020 kreedit) - (Sum: Konto 605020 deebet)
  SELECT
    s.rekvid,
    '72'                                                                  AS konto,
    'Rahavood investeerimistegevusest'                                    AS grupp,
    'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)'  AS all_grupp,
    'Korrigeerimine ebatõenäoliselt laekuvaks arvatud järelmaksunõuetega' AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '605020'
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)                     AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum: konto 206030 kreedit) - (sum konto 206030 deebet)) - (Eelmise per saldoandmikust (sum kontod 206030 kreedit) - (sum kontod 206030 deebet)) + (jooksva per saldoandmikust (konto 700030 kreedit + konto 710030 kreedit - konto 700030 deebet - konto 710030 deebet)
  SELECT
    s.rekvid,
    '72'                                                                 AS konto,
    'Rahavood investeerimistegevusest'                                   AS grupp,
    'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Korrigeerimine kustutatud EVP-de jäägi muutusega'                   AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '206030'
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '206030'
                             AND kuu = 12 AND
                             aasta = year(l_kpv) - 1), 0)

                                                                         AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum: Konto 1032* kreedit (RV 01) + sum konto 1532* kreedit (RV 01)) - (Sum: Konto 1032* deebet (RV 01)+ sum konto 1532* deebet (RV 01))
  SELECT
    s.rekvid,
    '7'                                                                  AS konto,
    'Rahavood investeerimistegevusest'                                   AS grupp,
    'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Antud laenud'                                                       AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('1032', '1532') AND rahavoo = '01'
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)

                                                                         AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum: Konto 1032* kreedit (RV 02) + sum konto 1532* kreedit (RV 02)) - (Sum: Konto 1032* deebet (RV 02)+ sum konto 1532* deebet (RV 02))
  SELECT
    s.rekvid,
    '7'                                                                  AS konto,
    'Rahavood investeerimistegevusest'                                   AS grupp,
    'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
    'Tagasi makstud laenud'                                              AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('1032', '1532') AND rahavoo = '02'
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)

                                                                         AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Eelmise per saldoandmikust (Sum konto 103540 deebet) - (sum konto 103540 kreedit) - (sum konto 203540 kreedit) + (sum konto 203540 deebet))
  -- - (sum konto 257800 kreedit) +
  -- (sum konto 257800 deebet)) -
  --(Jooksva per saldoandmikust (Sum: Konto 103540 deebet) - (sum konto 103540 kreedit) -
  --(konto 203540 kreedt) + (konto 203540 deebet) -
  --(konto 257800 kreedit) + (konto 257800 deebet))
  SELECT
    s.rekvid,
    '7'                                                                            AS konto,
    'Rahavood investeerimistegevusest'                                             AS grupp,
    'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)'           AS all_grupp,
    'Korrigeerimine laenutegevuseks saadud sihtfinantseerimise muutusega'          AS nimetus,
    (coalesce(sum(db - kr)
                FILTER (WHERE konto = '103540'
                              AND kuu = 12 AND
                              aasta = year(l_kpv) - 1), 0) -
     coalesce(sum(kr)
                FILTER (WHERE konto = '203540'
                              AND kuu = month(l_kpv) AND
                              aasta = year(l_kpv)), 0) +
     coalesce(sum(db)
                FILTER (WHERE konto = '203540'
                              AND kuu = month(l_kpv) AND
                              aasta = year(l_kpv)), 0) -
     coalesce(sum(kr)
                FILTER (WHERE konto = '257800'
                              AND kuu = 12 AND
                              aasta = year(l_kpv) - 1), 0) +
     coalesce(sum(db)
                FILTER (WHERE konto = '257800'
                              AND kuu = 12 AND
                              aasta = year(l_kpv) - 1), 0)) -
    (coalesce(sum(db - kr)
                FILTER (WHERE konto = '103540'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
     coalesce(sum(kr)
                FILTER (WHERE konto = '203540 '
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +

     coalesce(sum(db)
                FILTER (WHERE konto = '203540'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
     coalesce(sum(kr)
                FILTER (WHERE konto = '257800'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +

     coalesce(sum(db)
                FILTER (WHERE konto = '257800'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  -- --Jooksva per saldoandmikust (Sum: Konto 101* kreedit (RV 01) + sum konto 151* kreedit (RV 01)) - (Sum: Konto 101* deebet (RV 01)+ sum konto 151* deebet (RV 01))
  SELECT
    s.rekvid,
    '7'                                         AS konto,
    'Rahavood investeerimistegevusest'          AS grupp,
    ''                                          AS all_grupp,
    'Tasutud finantsinvesteeringute soetamisel' AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 3) IN ('101', '151') AND rahavoo = '01'
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)

                                                AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  -- --Jooksva per saldoandmikust (Sum: Konto 101* kreedit (RV 02) + sum konto 151* kreedit (RV 02)) - (Sum: Konto 101* deebet (RV 02)+ sum konto 151* deebet (RV 02))
  SELECT
    s.rekvid,
    '7'                                       AS konto,
    'Rahavood investeerimistegevusest'        AS grupp,
    ''                                        AS all_grupp,
    'Laekunud finantsinvesteeringute müügist' AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 3) IN ('101', '151') AND rahavoo = '02'
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)

                                              AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  -- --Jooksva per saldoandmikust (Sum: Konto 150* kreedit (RV 01)) - (Sum: Konto 150* deebet (RV 01))
  SELECT
    s.rekvid,
    '7'                                AS konto,
    'Rahavood investeerimistegevusest' AS grupp,
    ''                                 AS all_grupp,
    'Tasutud osaluste soetamisel'      AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 3) IN ('150') AND rahavoo = '01'
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)

                                       AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  -- --Jooksva per saldoandmikust (Sum: Konto 150* kreedit (RV 02)) - (Sum: Konto 150* deebet (RV 02))
  SELECT
    s.rekvid,
    '7'                                AS konto,
    'Rahavood investeerimistegevusest' AS grupp,
    ''                                 AS all_grupp,
    'Laekunud osaluste müügist'        AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 3) IN ('150') AND rahavoo = '02'
                             AND kuu = month(l_kpv) AND
                             aasta = year(l_kpv)), 0)

                                       AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (Sum: Konto 655500 kreedit+ konto 652010 kreedit) - (sum konto 655500  deebet + konto 652010 deebet) +
  --(sum 103110 kreedit RV 02 - Sum Konto 10311 0 deebet RV 02))
  SELECT
    s.rekvid,
    '7'                                AS konto,
    'Rahavood investeerimistegevusest' AS grupp,
    ''                                 AS all_grupp,
    'Laekunud dividendid'              AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE konto IN ('655500', '652010') AND rahavoo = '02'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +
    coalesce(sum(kr - db)
               FILTER (WHERE konto IN ('103110') AND rahavoo = '02'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)
                                       AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Eelmise per saldoandmikust (Sum konto 10310* deebet) - (sum konto 10310* kreedit)) +
  --(Jooksva per saldoandmikust (Sum: Konto 6580* kreedit) - (sum konto 6580* deebet) +
  --(konto 658910 kreedit) - (konto 658910 deebet) -
  --(sum 10310* deebet - Sum Konto 10310* kreedit )) + (Sum: Konto 655* kreedit - konto 655* deebet) -
  --((sum 101* deebet RV 21, 29, 22) - (sum 101* kreedit RV 21, 29, 22)) -
  --((Sum: Konto 151* deebet RV 21, 29, 22) - (konto 151* kreedit RV 21, 29, 22)) -
  --(konto 655500 kreedit miinus konto 655500 deebet) -
  --((sum 1032* deebet RV 22 - sum 1032* kreedit RV 22 + sum 1532* deebet RV 22 - sum 1532* kreedit RV 22)) +
  --((konto 101900 deebet RV 21 - konto 101900 kreedit RV 21))
  SELECT
    s.rekvid,
    '7'                                                                          AS konto,
    'Rahavood investeerimistegevusest'                                           AS grupp,
    ''                                                                           AS all_grupp,
    'Laekunud intressid ja muu finantstulu'                                      AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE konto LIKE '10310%'
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) +
    (coalesce(sum(kr - db)
                FILTER (WHERE konto LIKE '6580%'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +
     coalesce(sum(kr - db)
                FILTER (WHERE konto = '658910'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
     coalesce(sum(kr - db)
                FILTER (WHERE konto LIKE '10310%'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)) +
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '655%'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE konto LIKE '101%' AND rahavoo IN ('21', '29', '22')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE konto LIKE '151%' AND rahavoo IN ('21', '29', '22')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '655500'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    (coalesce(sum(db - kr)
                FILTER (WHERE konto LIKE '1032%' AND rahavoo = '22'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +
     coalesce(sum(db - kr)
                FILTER (WHERE konto LIKE '1532%' AND rahavoo = '22'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)) +
    coalesce(sum(db - kr)
               FILTER (WHERE konto = '101900' AND rahavoo = '21'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  -- --Jooksva per saldoandmikust (Sum konto 2080* kreedit (RV 05) - konto 2080* deebet (RV 05) + sum konto 2580* kreedit (RV 05) - konto 2580* deebet (RV 05)
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Laekunud võlakirjade emiteerimisest'                                        AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2080', '2580') AND rahavoo = '05'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum konto 2080* kreedit (RV 06) - konto 2080* deebet (RV 06) + sum konto 2580* kreedit (RV 06) - konto 2580* deebet (RV 06)
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Lunastatud võlakirjad'                                                      AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2080', '2580') AND rahavoo = '06'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum konto 2081* kreedit (RV 05) - konto 2081* deebet (RV 05) + sum konto 2581* kreedit (RV 05) - konto 2581* deebet (RV 05)
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Laekunud laenud'                                                            AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2081', '2581') AND rahavoo = '05'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum konto 2081* kreedit (RV 06) - konto 2081* deebet (RV 06) + sum konto 2581* kreedit (RV 06) - konto 2581* deebet (RV 06)
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Tagasi makstud laenud'                                                      AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2081', '2581') AND rahavoo = '06'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (Sum konto 208100 kreedit - konto 208100 deebet)) - (eelmise per saldoandmikust (sum konto 208100 kreedit- konto 208100 deebet))
  SELECT
    s.rekvid,
    '8'                                                                    AS konto,
    'Rahavood finantseerimistegevusest'                                    AS grupp,
    ''                                                                     AS all_grupp,
    'Arvelduskrediidi muutus'                                              AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '208100'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '208100'
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum konto 2082* kreedit (RV 06) - konto 2082* deebet (RV 06) + sum konto 2582* kreedit (RV 06) - konto 2582* deebet (RV 06)
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Tagasi makstud kapitalirendikohustused'                                     AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2082', '2582') AND rahavoo = '06'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum konto 2083* kreedit (RV 05) - konto 2083* deebet (RV 05) + sum konto 2583* kreedit (RV 05) - konto 2583* deebet (RV 05)
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Laekunud faktooringlepingute alusel'                                        AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2083', '2583') AND rahavoo = '05'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum konto 2083* kreedit (RV 06) - konto 2083* deebet (RV 06) + sum konto 2583* kreedit (RV 06) - konto 2583* deebet (RV 06)
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Tagasi makstud faktooringlepingute alusel'                                  AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE left(konto, 4) IN ('2083', '2583') AND rahavoo = '06'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum: Konto 257* kreedit-deebet (RV 05) + (konto 3502* kreedit miinus deebet) -
  --(konto 3502 RV 19, RV 01 kreedit miinus deebet)+ (Jooksva per saldoandmikust (sum: konto 203856 kreedit + konto 203857 kreedit) -
  --(sum konto 203856 deebet + konto 203857 deebet)) - (Eelmise per saldoandmikust (sum kontod 203856 kreedit + konto 203857 kreedit) -
  --(sum kontod 203856 deebet + konto 203857 deebet)) + (Eelmise per saldoandmikust (sum konto 103556 deebet + konto 103557 deebet + 153556 deebet) -
  --(sum konto 103556 kreedit + konto 103557 kreedit + konto 153556 kreedit)) - (Jooksva per saldoandmikust (sum konto 103556 deebet + konto 103557 deebet +

  --konto 153556 deebet) - (sum konto 103556 kreedit + konto 103557 kreedit + konto 153556 kreedit))
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Laekunud sihtfinanteerimine põhivara soetuseks'                             AS nimetus,
    (coalesce(sum(kr - db)
                FILTER (WHERE konto LIKE '257%' AND rahavoo = '05'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +
     coalesce(sum(kr - db)
                FILTER (WHERE konto LIKE '3502%'
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -

     coalesce(sum(kr - db)
                FILTER (WHERE konto LIKE '3502%' AND rahavoo IN ('19', '01')
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +

     coalesce(sum(kr - db)
                FILTER (WHERE konto IN ('203856', '203857')
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)) -

    (coalesce(sum(kr - db)
                FILTER (WHERE konto IN ('203856', '203857')
                              AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) +
     coalesce(sum(db - kr)
                FILTER (WHERE konto IN ('103556', '103557', '153556')
                              AND kuu = 12 AND aasta = year(l_kpv) - 1), 0)) -
    coalesce(sum(db - kr)
               FILTER (WHERE konto IN ('103556', '103557', '153556')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa

  FROM eelarve.saldoandmik s
  GROUP BY rekvid
  UNION ALL
  --Tasutud sihtfinantseerimine põhivara soetuseks
  --Jooksva per saldoandmikust (Konto 4502* kreedit-deebet) + 1KDRV24+ (Jooksva per saldoandmikust (konto 203556, 203557, 253550 kreedit miinus deebet) -
  --(sum konto 103856, 103857, 1537 deebet miinus kreedit) - (Eelmise per saldoandmikust (sum kontod 203556, 203557, 253550 kreedit miinus deebet) +
  --(Eelmise per saldoandmikust (konto 103856, 103857, 1537 deebet miinus kreedit)
  SELECT
    s.rekvid,
    '8'                                                                    AS konto,
    'Rahavood finantseerimistegevusest'                                    AS grupp,
    ''                                                                     AS all_grupp,
    'Makstud sihtfinantseerimine põhivara soetuseks'                       AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (left(konto, 4) IN ('4502') OR konto IN ('203556', '203557', '253550') OR
                              left(konto, 1) = '1' AND rahavoo = '24')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE (left(konto, 4) IN ('1537') OR konto IN ('103856', '103857'))
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -

    coalesce(sum(kr - db)
               FILTER (WHERE konto IN ('203556', '203557', '253550')
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) +

    COALESCE(sum(db - kr)
               FILTER (WHERE (konto IN ('103856', '103857') OR konto LIKE '1537%')
                             AND kuu = 12 AND aasta = YEAR(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --Laekunud liitumistasud
  --(Jooksva per saldoandmikust (sum: konto 253800 kreedit + konto 323880 kreedit) - (sum konto 253800 deebet + konto 323880 deebet)) -
  --(Eelmise per saldoandmikust (sum konto 253800 kreedit) - (sum kontod 253800 deebet))
  SELECT
    s.rekvid,
    '8'                                                                    AS konto,
    'Rahavood finantseerimistegevusest'                                    AS grupp,
    ''                                                                     AS all_grupp,
    'Laekunud liitumistasud'                                               AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE konto IN ('253800', '323880')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto IN ('253800', '323880')
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum konto 650* kreedit - konto 650* deebet) + jooksva per saldoandmikust (konto 203200 kreedit - konto 203200 deebet) -
  --(eelmise per saldoandmikust (konto 203200 kreedit- konto 203200 deebet)) + (jooksva per saldoandmikust (konto 209000 kreedit - konto 209000 deebet) -
  --(eelmise per saldoandmikust (konto 209000 kreedit - konto 209000 deebet)) + eelmise per saldandmikust (konto 103300 deebet - konto 103300 kreedit)) -
  --jooksva per saldoandmikust (konto 103300 deebet - konto 103300 kreedit) + jooksva per saldoandmikust (konto 256* kreedit RV 42 - konto 256* deebet RV 42) +
  --jooksva per saldoandmikust (konto 208* kreedit (RV 42) - konto 208* deebet (RV 42)) + jooksva per saldoandmikust (konto 258* kreedit (RV 42) - konto 258* deebet (RV 42))

  SELECT
    s.rekvid,
    '8'                                 AS konto,
    'Rahavood finantseerimistegevusest' AS grupp,
    ''                                  AS all_grupp,
    'Makstud intressid'                 AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '650%' OR konto = '203200')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto IN ('203200')
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) +
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '209000'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(kr - db)
               FILTER (WHERE konto = '209000'
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) +
    coalesce(sum(db - kr)
               FILTER (WHERE konto = '103300'
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) -
    coalesce(sum(db - kr)
               FILTER (WHERE (konto = '103300' OR konto LIKE '256%' AND rahavoo = '42')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '208%' AND rahavoo = '42' OR konto LIKE '258%' AND rahavoo = '42')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)

                                        AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (Sum konto 6589* kreedit - konto 6589* deebet - 658910 kreedit + 658910 deebet)) +
  --jooksva per saldoandmikust (konto 208* kreedit (RV 41*) - konto 208* deebet (RV 41)) +

  --jooksva per saldoandmikust (konto 258* kreedit (RV 41*) - konto 258* deebet (RV 41*))
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Makstud muud finantskulud'                                                  AS nimetus,
    (coalesce(sum(kr - db)
                FILTER (WHERE (konto LIKE '6589%')
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
     coalesce(sum(kr)
                FILTER (WHERE konto IN ('658910')
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +
     coalesce(sum(db)
                FILTER (WHERE konto IN ('658910')
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)) +
    coalesce(sum(db - kr)
               FILTER (WHERE (konto LIKE '258%' OR konto LIKE '208%') AND rahavoo = '41'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (Sum konto 297* kreedit - konto 297* deebet)) - (eelmise per saldoandmikust (Sum konto 297* kreedit - konto 297* deebet))
  SELECT
    s.rekvid,
    '8'                                                                    AS konto,
    'Rahavood finantseerimistegevusest'                                    AS grupp,
    ''                                                                     AS all_grupp,
    'Riskimaandamise reservi muutus'                                       AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '297%')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    coalesce(sum(kr)
               FILTER (WHERE konto IN ('658910')
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (konto 203210 kreedit RV 06 miinus konto 203210 deebet RV 06)
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Makstud dividendid'                                                         AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (konto = '203210' AND rahavoo = '06')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum (konto 29* RV 05 kreedit - konto 29* RV 05 deebet)) + (sum konto 289000 kreedit RV 05 - sum konto 289000 deebet RV 05))
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Laekunud sissemaksed omakapitali'                                           AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '29%' OR konto = '289000') AND rahavoo = '05'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (Sum (konto 29* RV 06 kreedit - konto 29* RV 06 deebet)) + (sum konto 289000 kreedit RV 06 - sum konto 289000 deebet RV 06))
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Tasutud väljamaksed omakapitalist'                                          AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '29%' OR konto = '289000') AND rahavoo = '06'
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (Sum konto 68* kreedit - konto 68* deebet))
  SELECT
    s.rekvid,
    '8'                                                                          AS konto,
    'Rahavood finantseerimistegevusest'                                          AS grupp,
    ''                                                                           AS all_grupp,
    'Dividendidelt makstud tulumaks'                                             AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '68%')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --(Jooksva per saldoandmikust (sum konto 7* kreedit - 7* deebet - konto 700002 kreedit - konto 710002 kreedit - konto 700030 kreedit - konto 710030 kreedit +
  --konto 700002 deebet + konto 710002 deebet + konto 700030 deebet + konto 710030 deebet) + kontod 1* kreedit (RV 15 + RV 16) - kontod 1* deebet (RV 15 + RV 16) +
  --kontod 2* kreedit (RV 15 + RV 16 + RV 35 + RV 36) - kontod 2* deebet (RV 15 + RV 16 + RV 35 + RV 36)
  SELECT
    s.rekvid,
    '8'                                 AS konto,
    'Rahavood finantseerimistegevusest' AS grupp,
    ''                                  AS all_grupp,
    'Netofinantseerimine eelavest'      AS nimetus,
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '7%')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) -
    (coalesce(sum(kr)
                FILTER (WHERE (konto IN ('700002', '710002', '700030', '710030'))
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +
     coalesce(sum(db)
                FILTER (WHERE (konto IN ('700002', '710002', '700030', '710030'))
                              AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)) +
    coalesce(sum(kr - db)
               FILTER (WHERE (konto LIKE '1%' AND rahavoo IN ('15', '16'))
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +
    coalesce(sum(kr - db)
               FILTER (WHERE konto LIKE '2%' AND rahavoo IN ('15', '16', '35', '36')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0)
                                        AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --Eelmise per saldoandmikust (sum konto 100* deebet - konto 100* kreedit) + (sum konto 101100 deebet - konto 101100 kreedit)
  SELECT
    s.rekvid,
    '91'                                                                   AS konto,
    ''                                                                     AS grupp,
    ''                                                                     AS all_grupp,
    'Raha ja selle ekvivalendid perioodi alguses'                          AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE (konto LIKE '100%')
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) +
    coalesce(sum(db - kr)
               FILTER (WHERE (konto = '101100')
                             AND kuu = 12 AND aasta = year(l_kpv) - 1), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid
  UNION ALL
  --Jooksva per saldoandmikust (sum konto 100* deebet - konto 100* kreedit) + (sum konto 101100 deebet - konto 101100 kreedit)
  SELECT
    s.rekvid,
    '92'                                                                         AS konto,
    ''                                                                           AS grupp,
    ''                                                                           AS all_grupp,
    'Raha ja selle ekvivalendid perioodi lõpus'                                  AS nimetus,
    coalesce(sum(db - kr)
               FILTER (WHERE (konto LIKE '100%')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) +
    coalesce(sum(db - kr)
               FILTER (WHERE (konto = '101100')
                             AND kuu = month(l_kpv) AND aasta = year(l_kpv)), 0) AS summa
  FROM eelarve.saldoandmik S
  GROUP BY rekvid

)

SELECT
  rekvid     AS rekv_id,
  grupp :: VARCHAR(254),
  all_grupp :: VARCHAR(254),
  konto :: VARCHAR(20),
  nimetus :: VARCHAR(254),
  sum(summa) AS summa
FROM (
       SELECT
         rekvid,
         grupp,
         all_grupp,
         konto,
         nimetus,
         summa
       FROM qrySaldo
       UNION ALL
       SELECT
         rekvid,
         'Rahavood põhitegevusest'    AS grupp,
         'Korrigeerimised'            AS all_grupp,
         '3'                          AS konto,
         'Korrigeeritud tegevustulem' AS nimetus,
         sum(summa)                   AS summa
       FROM qrySaldo S
       WHERE S.konto IN ('1', '2')
       GROUP BY rekvid
       UNION ALL
       SELECT
         rekvid,
         'Rahavood põhitegevusest'                      AS grupp,
         'Põhitegevusega seotud käibevarade netomuutus' AS all_grupp,
         '40'                                           AS konto,
         'Põhitegevusega seotud käibevarade netomuutus' AS nimetus,
         sum(summa)                                     AS summa
       FROM qrySaldo S
       WHERE S.konto = '4'
       GROUP BY rekvid
       UNION ALL
       SELECT
         rekvid,
         'Rahavood põhitegevusest'                           AS grupp,
         'Põhitegevusega seotud kohustuste netomuutus'       AS all_grupp,
         '50'                                                AS konto,
         'Põhitegevusega seotud kohustuste netomuutus kokku' AS nimetus,
         sum(summa)                                          AS summa
       FROM qrySaldo S
       WHERE S.konto = '5'
       GROUP BY rekvid
       UNION ALL
       --     = korrigeeritud tegevustulem (3) + käibevarade muutus (4) + kohustuste muutus (5)

       SELECT
         rekvid,
         'Rahavood põhitegevusest'       AS grupp,
         ''                              AS all_grupp,
         '60'                            AS konto,
         'Rahavood põhitegevusest kokku' AS nimetus,
         sum(summa)                      AS summa
       FROM qrySaldo S
       WHERE S.konto IN ('3', '4', '5')
       GROUP BY rekvid
       UNION ALL
       SELECT
         rekvid,
         'Rahavood investeerimistegevusest'                               AS grupp,
         'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
         '710'                                                            AS konto,
         'Tasutud põhivara eest (v.a. finantsinvesteeringud ja osalused)' AS nimetus,
         sum(summa)                                                       AS summa
       FROM qrySaldo S
       WHERE S.konto IN ('71')
       GROUP BY rekvid
       UNION ALL
       SELECT
         rekvid,
         'Rahavood investeerimistegevusest'                                   AS grupp,
         'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS all_grupp,
         '720'                                                                AS konto,
         'Laekunud põhivara müügist (v.a. finantsinvesteeringud ja osalused)' AS nimetus,
         sum(summa)                                                           AS summa
       FROM qrySaldo S
       WHERE S.konto IN ('72')
       GROUP BY rekvid
       UNION ALL
       SELECT
         rekvid,
         'Rahavood investeerimistegevusest'       AS grupp,
         ''                                       AS all_grupp,
         '79'                                     AS konto,
         'Rahavood investeerimistegevusest kokku' AS nimetus,
         sum(summa)                               AS summa
       FROM qrySaldo S
       WHERE S.konto IN ('710', '711', '712', '713', '720')
       GROUP BY rekvid
       UNION ALL
       SELECT
         rekvid,
         'Rahavood finantseerimistegevusest'       AS grupp,
         ''                                        AS all_grupp,
         '80'                                      AS konto,
         'Rahavood finantseerimistegevusest kokku' AS nimetus,
         sum(summa)                                AS summa
       FROM qrySaldo S
       WHERE S.konto = '8'
       GROUP BY rekvid
       UNION ALL
       SELECT
         rekvid,
         ''               AS grupp,
         ''               AS all_grupp,
         '90'             AS konto,
         'Puhas rahavoog' AS nimetus,
         sum(summa)       AS summa
       FROM qrySaldo S
       WHERE S.konto IN ('8', '710', '711', '712', '713', '720', '3', '4', '5')
       GROUP BY rekvid
       UNION ALL
       SELECT
         rekvid,
         ''                                                                                      AS grupp,
         ''                                                                                      AS all_grupp,
         '93'                                                                                    AS konto,
         'Raha ja selle ekvivalentide muutus'                                                    AS nimetus,
         coalesce(sum(summa)
                    FILTER (WHERE konto = '91'), 0) - coalesce(sum(summa)
                                                                 FILTER (WHERE konto = '92'), 0) AS summa
       FROM qrySaldo S
       GROUP BY rekvid

     ) qry
WHERE rekvid = (CASE WHEN l_kond = 1
  THEN qry.rekvid
                ELSE l_rekvid END)
      AND qry.rekvid IN (SELECT rekv_id
                         FROM get_asutuse_struktuur(l_rekvid))
GROUP BY rekv_id, grupp, all_grupp, konto, nimetus

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.rahavoog_aruanne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbvaatleja;

/*
SELECT sum(summa)
FROM (
       SELECT
         rekv_id,
         summa,
         grupp,
         all_grupp,
         konto,
         nimetus
       FROM eelarve.rahavoog_aruanne('2018-06-30' :: DATE, 63, 1)
     ) qry
WHERE nimetus = 'Kinnisvarainvesteeringute soetus'
*/