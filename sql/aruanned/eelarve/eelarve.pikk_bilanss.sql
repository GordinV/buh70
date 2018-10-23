DROP FUNCTION IF EXISTS eelarve.pikk_bilanss( DATE, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.pikk_bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    rekv_id INTEGER,
    konto   VARCHAR(20),
    nimetus VARCHAR(254),
    summa   NUMERIC(14, 2)
  ) AS
$BODY$

WITH qrySaldo AS (
  SELECT
    s.rekvid,
    s.konto,
    sum(coalesce(s.db, 0)) AS db,
    sum(coalesce(s.kr, 0)) AS kr
  FROM eelarve.saldoandmik s
  WHERE s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
        AND rekvid = (CASE WHEN l_kond = 1
    THEN s.rekvid
                      ELSE l_rekvid END)
        AND s.rekvid IN (SELECT rekv_id
                         FROM get_asutuse_struktuur(l_rekvid))

  GROUP BY s.konto, s.rekvid
  UNION ALL
  -- 299000
  --Saldoandmikust (Sum: Kontod 3*kuni 6* Kreedit) - (Sum: Kontod 3* kuni 6* Deebet)
  SELECT
    s.rekvid                AS rekv_id,
    '299000' :: VARCHAR(20) AS konto,
    sum(kr) - sum(db)       AS db,
    0 :: NUMERIC(14, 2)     AS kr
  FROM eelarve.saldoandmik s
  WHERE
    s.aasta = year(l_kpv) AND s.kuu = month(l_kpv)
    AND rekvid = (CASE WHEN l_kond = 1
      THEN s.rekvid
                  ELSE l_rekvid END)
    AND s.rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid))

    AND left(konto, 1) IN ('3', '4', '5', '6')
  GROUP BY s.rekvid

)
SELECT
  rekv_id,
  konto,
  nimetus,
  sum(summa) AS summa
FROM (
       -- 10
       SELECT
         q.rekvid                    AS rekv_id,
         '10' :: VARCHAR(20)         AS konto,
         'Käibevara' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)           AS summa
       FROM qrySaldo q
       WHERE konto LIKE '10%'
       GROUP BY q.rekvid
       UNION ALL
       -- 103
       SELECT
         q.rekvid                                    AS rekv_id,
         '103' :: VARCHAR(20)                        AS konto,
         'Muud nouded ja ettemaksed' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                           AS summa
       FROM qrySaldo q
       WHERE konto LIKE '103%'
       GROUP BY q.rekvid
       UNION ALL
       --100
       SELECT
         q.rekvid                              AS rekv_id,
         '100' :: VARCHAR(20)                  AS konto,
         'Raha ja pangakontod' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                     AS summa
       FROM qrySaldo q
       WHERE konto LIKE '100%'
       GROUP BY q.rekvid
       UNION ALL
       --101
       SELECT
         q.rekvid                                AS rekv_id,
         '101' :: VARCHAR(20)                    AS konto,
         'Finantsinvesteeringud' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                       AS summa
       FROM qrySaldo q
       WHERE konto LIKE '101%'
       GROUP BY q.rekvid
       UNION ALL
       --1011
       SELECT
         q.rekvid                                          AS rekv_id,
         '1011' :: VARCHAR(20)                             AS konto,
         'Kauplemisportfelli väärtpaberid' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                 AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1011%'
       GROUP BY q.rekvid
       UNION ALL
       --1012
       SELECT
         q.rekvid                                          AS rekv_id,
         '1012' :: VARCHAR(20)                             AS konto,
         'Tähtajani hoitavad väärtpaberid' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                 AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1012%'
       GROUP BY q.rekvid
       UNION ALL
       --1019
       SELECT
         q.rekvid                                     AS rekv_id,
         '1019' :: VARCHAR(20)                        AS konto,
         'Muud finantsinvesteeringud' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                            AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1019%'
       GROUP BY q.rekvid
       UNION ALL
       --102
       SELECT
         q.rekvid                                         AS rekv_id,
         '102' :: VARCHAR(20)                             AS konto,
         'Maksu-, lõivu- ja trahvinõuded' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                AS summa
       FROM qrySaldo q
       WHERE konto LIKE '102%'
       GROUP BY q.rekvid
       UNION ALL
       --1020
       SELECT
         q.rekvid                                                AS rekv_id,
         '1020' :: VARCHAR(20)                                   AS konto,
         'Maksu-, lõivu ja trahvinõuded (bruto)' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                       AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1020%'
       GROUP BY q.rekvid
       UNION ALL
       --1021
       SELECT
         q.rekvid                                                                 AS rekv_id,
         '1021' :: VARCHAR(20)                                                    AS konto,
         'Ebatõenäoliselt laekuvad maksu-, lõivu ja trahvinõuded' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                                        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1021%'
       GROUP BY q.rekvid
       UNION ALL
       --1030
       SELECT
         q.rekvid                               AS rekv_id,
         '1030' :: VARCHAR(20)                  AS konto,
         'Nouded ostjate vastu' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1030%'
       GROUP BY q.rekvid
       UNION ALL
       --1031
       SELECT
         q.rekvid                         AS rekv_id,
         '1031' :: VARCHAR(20)            AS konto,
         'Viitlaekumised' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1031%'
       GROUP BY q.rekvid
       UNION ALL
       --1032
       SELECT
         q.rekvid                                  AS rekv_id,
         '1032' :: VARCHAR(20)                     AS konto,
         'Laenu- ja liisingnõuded' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                         AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1032%'
       GROUP BY q.rekvid
       UNION ALL
       --1035
       -- Saldoandmikust (Sum: Kontod 1035* Deebet) - (Sum: Kontod 1035* Kreedit) - konto 103500 deebet + konto 103500 kreedit
       SELECT
         q.rekvid                                          AS rekv_id,
         '1035' :: VARCHAR(20)                             AS konto,
         'Nõuded toetuste ja siirete eest' :: VARCHAR(254) AS nimetus,
         coalesce(sum(db)
                    FILTER (WHERE left(konto, 4) = '1035'), 0) -
         coalesce(sum(kr)
                    FILTER (WHERE left(konto, 4) = '1035'), 0) -
         coalesce(sum(db + kr)
                    FILTER (WHERE konto LIKE '103500%'), 0)
                                                           AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1035%'
       GROUP BY q.rekvid
       UNION ALL
       --1036
       SELECT
         q.rekvid                      AS rekv_id,
         '1036' :: VARCHAR(20)         AS konto,
         'Muud nõuded' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)             AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1036%'
       GROUP BY q.rekvid
       UNION ALL
       --1037
       SELECT
         q.rekvid                                                AS rekv_id,
         '1037' :: VARCHAR(20)                                   AS konto,
         'Maksude, lõivude, trahvide ettemaksed' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                       AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1037%'
       GROUP BY q.rekvid
       UNION ALL
       --1038
       SELECT
         q.rekvid                               AS rekv_id,
         '1038' :: VARCHAR(20)                  AS konto,
         'Ettemakstud toetused' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1038%'
       GROUP BY q.rekvid
       UNION ALL
       --1039
       SELECT
         q.rekvid                                                 AS rekv_id,
         '1039' :: VARCHAR(20)                                    AS konto,
         'Ettemakstud tulevaste perioodide kulud' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1039%'
       GROUP BY q.rekvid
       UNION ALL
       --108
       SELECT
         q.rekvid                AS rekv_id,
         '108' :: VARCHAR(20)    AS konto,
         'Varud' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)       AS summa
       FROM qrySaldo q
       WHERE konto LIKE '108%'
       GROUP BY q.rekvid
       UNION ALL
       --1080
       SELECT
         q.rekvid                               AS rekv_id,
         '1080' :: VARCHAR(20)                  AS konto,
         'Strateegilised varud' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1080%'
       GROUP BY q.rekvid
       UNION ALL
       --1089
       SELECT
         q.rekvid                                                      AS rekv_id,
         '1089' :: VARCHAR(20)                                         AS konto,
         'Üle andmata varud ja ettemaksed varude eest' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                             AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1089%'
       GROUP BY q.rekvid
       UNION ALL
       --109
       SELECT
         q.rekvid                              AS rekv_id,
         '109' :: VARCHAR(20)                  AS konto,
         'Müügiootel põhivara' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                     AS summa
       FROM qrySaldo q
       WHERE konto LIKE '109%'
       GROUP BY q.rekvid
       UNION ALL
       --15
       SELECT
         q.rekvid                   AS rekv_id,
         '15' :: VARCHAR(20)        AS konto,
         'Põhivara' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)          AS summa
       FROM qrySaldo q
       WHERE konto LIKE '15%'
       GROUP BY q.rekvid
       UNION ALL
       --150
       SELECT
         q.rekvid                                                    AS rekv_id,
         '150' :: VARCHAR(20)                                        AS konto,
         'Osalused avaliku sektori ja sidusüksustes' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                           AS summa
       FROM qrySaldo q
       WHERE konto LIKE '150%'
       GROUP BY q.rekvid
       UNION ALL
       --1502
       SELECT
         q.rekvid                                               AS rekv_id,
         '1502' :: VARCHAR(20)                                  AS konto,
         'Osalused tütar- ja sidusettevõtjates' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1502%'
       GROUP BY q.rekvid
       UNION ALL
       --151
       SELECT
         q.rekvid                                AS rekv_id,
         '151' :: VARCHAR(20)                    AS konto,
         'Finantsinvesteeringud' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                       AS summa
       FROM qrySaldo q
       WHERE konto LIKE '151%'
       GROUP BY q.rekvid
       UNION ALL
       --1511
       SELECT
         q.rekvid                                              AS rekv_id,
         '1511' :: VARCHAR(20)                                 AS konto,
         'Investeerimisportfelli väärtpaberid' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                     AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1511%'
       GROUP BY q.rekvid
       UNION ALL
       --1512
       SELECT
         q.rekvid                                        AS rekv_id,
         '1512' :: VARCHAR(20)                           AS konto,
         'Tähtajani hoitavad võlakirjad' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                               AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1512%'
       GROUP BY q.rekvid
       UNION ALL
       --1519
       SELECT
         q.rekvid                                     AS rekv_id,
         '1519' :: VARCHAR(20)                        AS konto,
         'Muud finantsinvesteeringud' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                            AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1519%'
       GROUP BY q.rekvid
       UNION ALL
       --152
       SELECT
         q.rekvid                                         AS rekv_id,
         '152' :: VARCHAR(20)                             AS konto,
         'Maksu-, lõivu- ja trahvinõuded' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                AS summa
       FROM qrySaldo q
       WHERE konto LIKE '152%'
       GROUP BY q.rekvid
       UNION ALL
       --1520
       SELECT
         q.rekvid                                                AS rekv_id,
         '1520' :: VARCHAR(20)                                   AS konto,
         'Maksu-, lõivu ja trahvinõuded (bruto)' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                       AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1520%'
       GROUP BY q.rekvid
       UNION ALL
       --1521
       SELECT
         q.rekvid                                                                 AS rekv_id,
         '1521' :: VARCHAR(20)                                                    AS konto,
         'Ebatõenäoliselt laekuvad maksu-, lõivu ja trahvinõuded' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                                        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1521%'
       GROUP BY q.rekvid
       UNION ALL
       --153
       SELECT
         q.rekvid                                    AS rekv_id,
         '153' :: VARCHAR(20)                        AS konto,
         'Muud nõuded ja ettemaksed' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                           AS summa
       FROM qrySaldo q
       WHERE konto LIKE '153%'
       GROUP BY q.rekvid
       UNION ALL
       --1530
       SELECT
         q.rekvid                               AS rekv_id,
         '1530' :: VARCHAR(20)                  AS konto,
         'Nõuded ostjate vastu' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1530%'
       GROUP BY q.rekvid
       UNION ALL
       --1532
       SELECT
         q.rekvid                                  AS rekv_id,
         '1532' :: VARCHAR(20)                     AS konto,
         'Laenu- ja liisingnõuded' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                         AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1532%'
       GROUP BY q.rekvid
       UNION ALL
       --1535
       SELECT
         q.rekvid                               AS rekv_id,
         '1535' :: VARCHAR(20)                  AS konto,
         'Nõuded toetuste eest' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1535%'
       GROUP BY q.rekvid
       UNION ALL
       --1536
       SELECT
         q.rekvid                                   AS rekv_id,
         '1536' :: VARCHAR(20)                      AS konto,
         'Muud pikaajalised nõuded' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                          AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1536%'
       GROUP BY q.rekvid
       UNION ALL
       --1537
       SELECT
         q.rekvid                                    AS rekv_id,
         '1537' :: VARCHAR(20)                       AS konto,
         'Antud sihtfinantseerimine' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                           AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1537%'
       GROUP BY q.rekvid
       UNION ALL
       --154
       SELECT
         q.rekvid                                   AS rekv_id,
         '154' :: VARCHAR(20)                       AS konto,
         'Kinnisvarainvesteeringud' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                          AS summa
       FROM qrySaldo q
       WHERE konto LIKE '154%'
       GROUP BY q.rekvid
       UNION ALL
       --155
       SELECT
         q.rekvid                               AS rekv_id,
         '155' :: VARCHAR(20)                   AS konto,
         'Materiaalne põhivara' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '155%'
       GROUP BY q.rekvid
       UNION ALL
       --1551
       SELECT
         q.rekvid                              AS rekv_id,
         '1551' :: VARCHAR(20)                 AS konto,
         'Hooned ja rajatised' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                     AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1551%'
       GROUP BY q.rekvid
       UNION ALL
       --15510
       SELECT
         q.rekvid                                               AS rekv_id,
         '15510' :: VARCHAR(20)                                 AS konto,
         'Hooned ja rajatised soetusmaksumuses' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '15510%'
       GROUP BY q.rekvid
       UNION ALL
       --15511
       SELECT
         q.rekvid                                               AS rekv_id,
         '15511' :: VARCHAR(20)                                 AS konto,
         'Hoonete ja rajatiste kogunenud kulum' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '15511%'
       GROUP BY q.rekvid
       UNION ALL
       --1553
       SELECT
         q.rekvid                                      AS rekv_id,
         '1553' :: VARCHAR(20)                         AS konto,
         'Kaitseotstarbeline põhivara' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                             AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1553%'
       GROUP BY q.rekvid
       UNION ALL
       --1554
       SELECT
         q.rekvid                             AS rekv_id,
         '1554' :: VARCHAR(20)                AS konto,
         'Masinad ja seadmed' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                    AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1554%'
       GROUP BY q.rekvid
       UNION ALL
       --15540
       SELECT
         q.rekvid                                              AS rekv_id,
         '15540' :: VARCHAR(20)                                AS konto,
         'Masinad ja seadmed soetusmaksumuses' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                     AS summa
       FROM qrySaldo q
       WHERE konto LIKE '15540%'
       GROUP BY q.rekvid
       UNION ALL
       --15541
       SELECT
         q.rekvid                                               AS rekv_id,
         '15541' :: VARCHAR(20)                                 AS konto,
         'Masinate ja seadmete kogunenud kulum' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '15541%'
       GROUP BY q.rekvid
       UNION ALL
       --1555
       SELECT
         q.rekvid                                                       AS rekv_id,
         '1555' :: VARCHAR(20)                                          AS konto,
         'Info- ja kommunikatsioonitehnoloogia seadmed' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                              AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1555%'
       GROUP BY q.rekvid
       UNION ALL
       --1556
       SELECT
         q.rekvid                                                AS rekv_id,
         '1556' :: VARCHAR(20)                                   AS konto,
         'Muu amortiseeruv materiaalne põhivara' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                       AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1556%'
       GROUP BY q.rekvid
       UNION ALL
       --1559
       SELECT
         q.rekvid                                                 AS rekv_id,
         '1559' :: VARCHAR(20)                                    AS konto,
         'Kasutusele võtmata varad ja ettemaksed' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1559%'
       GROUP BY q.rekvid
       UNION ALL
       --156
       SELECT
         q.rekvid                                 AS rekv_id,
         '156' :: VARCHAR(20)                     AS konto,
         'Immateriaalne põhivara' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '156%'
       GROUP BY q.rekvid
       UNION ALL
       --1560
       SELECT
         q.rekvid                   AS rekv_id,
         '1560' :: VARCHAR(20)      AS konto,
         'Tarkvara' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)          AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1560%'
       GROUP BY q.rekvid
       UNION ALL
       --1562
       SELECT
         q.rekvid                                AS rekv_id,
         '1562' :: VARCHAR(20)                   AS konto,
         'Õigused ja litsentsid' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                       AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1562%'
       GROUP BY q.rekvid
       UNION ALL
       --1564
       SELECT
         q.rekvid                              AS rekv_id,
         '1564' :: VARCHAR(20)                 AS konto,
         'Arenguväljaminekud ' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                     AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1564%'
       GROUP BY q.rekvid
       UNION ALL
       --1565
       SELECT
         q.rekvid                       AS rekv_id,
         '1565' :: VARCHAR(20)          AS konto,
         'Firmaväärtus' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)              AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1565%'
       GROUP BY q.rekvid
       UNION ALL
       --1566
       SELECT
         q.rekvid                                     AS rekv_id,
         '1566' :: VARCHAR(20)                        AS konto,
         'Muu immateriaalne põhivara' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                            AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1566%'
       GROUP BY q.rekvid
       UNION ALL
       --1566
       SELECT
         q.rekvid                                                 AS rekv_id,
         '1569' :: VARCHAR(20)                                    AS konto,
         'Kasutusele võtmata varad ja ettemaksed' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                                        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '1569%'
       GROUP BY q.rekvid
       UNION ALL
       --157
       SELECT
         q.rekvid                              AS rekv_id,
         '157' :: VARCHAR(20)                  AS konto,
         'Bioloogilised varad' :: VARCHAR(254) AS nimetus,
         sum(db) - sum(kr)                     AS summa
       FROM qrySaldo q
       WHERE konto LIKE '157%'
       GROUP BY q.rekvid
       UNION ALL
       --2
       --Saldoandmikust (Sum: Kontod 2* Kreedit) - (Sum: Kontod 2* Deebet) + konto 103500 kreedit - konto 103500 deebet
       SELECT
         q.rekvid                                 AS rekv_id,
         '2' :: VARCHAR(20)                       AS konto,
         'Kohustused ja netovara' :: VARCHAR(254) AS nimetus,
         coalesce(sum(kr)
                    FILTER (WHERE konto LIKE '2%'), 0) -
         coalesce(sum(db)
                    FILTER (WHERE konto LIKE '2%'), 0) +
         coalesce(sum(kr)
                    FILTER (WHERE konto LIKE '103500%'), 0) -
         coalesce(sum(db)
                    FILTER (WHERE konto LIKE '103500%'), 0)
                                                  AS summa
       FROM qrySaldo q
       GROUP BY q.rekvid
       UNION ALL
       --20
       SELECT
         q.rekvid                                  AS rekv_id,
         '20' :: VARCHAR(20)                       AS konto,
         'Luhiajalised kohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db) -
         coalesce(sum(kr)
                    FILTER (WHERE konto LIKE '2035%'), 0) +
         coalesce(sum(db)
                    FILTER (WHERE konto LIKE '2035%'), 0)
                                                   AS summa
       FROM qrySaldo q
       WHERE konto LIKE '20%'
       GROUP BY q.rekvid
       UNION ALL
       --200
       SELECT
         q.rekvid                                                         AS rekv_id,
         '200' :: VARCHAR(20)                                             AS konto,
         'Saadud maksude, lõivude ja trahvide ettemaksed' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                                                AS summa
       FROM qrySaldo q
       WHERE konto LIKE '200%'
       GROUP BY q.rekvid
       UNION ALL
       --201
       SELECT
         q.rekvid                            AS rekv_id,
         '201' :: VARCHAR(20)                AS konto,
         'Võlad tarnijatele' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                   AS summa
       FROM qrySaldo q
       WHERE konto LIKE '201%'
       GROUP BY q.rekvid
       UNION ALL
       --202
       SELECT
         q.rekvid                            AS rekv_id,
         '202' :: VARCHAR(20)                AS konto,
         'Võlad töötajatele' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                   AS summa
       FROM qrySaldo q
       WHERE konto LIKE '202%'
       GROUP BY q.rekvid
       UNION ALL
       --203
       SELECT
         q.rekvid                                               AS rekv_id,
         '203' :: VARCHAR(20)                                   AS konto,
         'Muud kohustused ja saadud ettemaksed' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '203%'
       GROUP BY q.rekvid
       UNION ALL
       --2030
       SELECT
         q.rekvid                                             AS rekv_id,
         '2030' :: VARCHAR(20)                                AS konto,
         'Maksu-, lõivu- ja trahvikohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                                    AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2030%'
       GROUP BY q.rekvid
       UNION ALL
       --2032
       SELECT
         q.rekvid                    AS rekv_id,
         '2032' :: VARCHAR(20)       AS konto,
         'Viitvõlad' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)           AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2032%'
       GROUP BY q.rekvid
       UNION ALL
       --2035
       SELECT
         q.rekvid                                         AS rekv_id,
         '2035' :: VARCHAR(20)                            AS konto,
         'Toetuste ja siirete kohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                                AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2035%'
       GROUP BY q.rekvid
       UNION ALL
       --2036
       SELECT
         q.rekvid                          AS rekv_id,
         '2036' :: VARCHAR(20)             AS konto,
         'Muud kohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                 AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2036%'
       GROUP BY q.rekvid
       UNION ALL
       --2038
       SELECT
         q.rekvid                                       AS rekv_id,
         '2038' :: VARCHAR(20)                          AS konto,
         'Toetusteks saadud ettemaksed' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                              AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2038%'
       GROUP BY q.rekvid
       UNION ALL
       --2039
       SELECT
         q.rekvid                                                               AS rekv_id,
         '2039' :: VARCHAR(20)                                                  AS konto,
         'Muud saadud ettemaksed ja tulevaste perioodide tulud' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                                                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2039%'
       GROUP BY q.rekvid
       UNION ALL
       --206
       SELECT
         q.rekvid                          AS rekv_id,
         '206' :: VARCHAR(20)              AS konto,
         'Laenukohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                 AS summa
       FROM qrySaldo q
       WHERE konto LIKE '206%'
       GROUP BY q.rekvid
       UNION ALL
       --2080
       SELECT
         q.rekvid                                 AS rekv_id,
         '2080' :: VARCHAR(20)                    AS konto,
         'Emiteeritud võlakirjad' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2080%'
       GROUP BY q.rekvid
       UNION ALL
       --2081
       SELECT
         q.rekvid                 AS rekv_id,
         '2081' :: VARCHAR(20)    AS konto,
         'Laenud' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2081%'
       GROUP BY q.rekvid
       UNION ALL
       --2083
       SELECT
         q.rekvid                               AS rekv_id,
         '2083' :: VARCHAR(20)                  AS konto,
         'Faktooringkohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                      AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2083%'
       GROUP BY q.rekvid
       UNION ALL
       --25
       SELECT
         q.rekvid                                  AS rekv_id,
         '25' :: VARCHAR(20)                       AS konto,
         'Pikaajalised kohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                         AS summa
       FROM qrySaldo q
       WHERE konto LIKE '25%'
       GROUP BY q.rekvid
       UNION ALL
       --250
       SELECT
         q.rekvid                            AS rekv_id,
         '250' :: VARCHAR(20)                AS konto,
         'Võlad tarnijatele' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                   AS summa
       FROM qrySaldo q
       WHERE konto LIKE '250%'
       GROUP BY q.rekvid
       UNION ALL
       --253
       SELECT
         q.rekvid                                              AS rekv_id,
         '253' :: VARCHAR(20)                                  AS konto,
         'Muud kohustusd ja saadud ettemaksed' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                                     AS summa
       FROM qrySaldo q
       WHERE konto LIKE '253%'
       GROUP BY q.rekvid
       UNION ALL
       --2530
       SELECT
         q.rekvid                                             AS rekv_id,
         '2530' :: VARCHAR(20)                                AS konto,
         'Maksu-, lõivu- ja trahvikohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                                    AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2530%'
       GROUP BY q.rekvid
       UNION ALL
       --2535
       SELECT
         q.rekvid                                      AS rekv_id,
         '2535' :: VARCHAR(20)                         AS konto,
         'Toetuste andmise kohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                             AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2535%'
       GROUP BY q.rekvid
       UNION ALL
       --2536
       SELECT
         q.rekvid                          AS rekv_id,
         '2536' :: VARCHAR(20)             AS konto,
         'Muud kohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                 AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2536%'
       GROUP BY q.rekvid
       UNION ALL
       --2538
       SELECT
         q.rekvid                                                   AS rekv_id,
         '2538' :: VARCHAR(20)                                      AS konto,
         'Ettemaksed ja tulevaste perioodide tulud' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                                          AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2538%'
       GROUP BY q.rekvid
       UNION ALL
       --256
       SELECT
         q.rekvid                    AS rekv_id,
         '256' :: VARCHAR(20)        AS konto,
         'Eraldised' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)           AS summa
       FROM qrySaldo q
       WHERE konto LIKE '256%'
       GROUP BY q.rekvid
       UNION ALL
       --257
       SELECT
         q.rekvid                              AS rekv_id,
         '257' :: VARCHAR(20)                  AS konto,
         'Sihtfinantseerimine' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                     AS summa
       FROM qrySaldo q
       WHERE konto LIKE '257%'
       GROUP BY q.rekvid
       UNION ALL
       --258
       SELECT
         q.rekvid                          AS rekv_id,
         '258' :: VARCHAR(20)              AS konto,
         'Laenukohustused' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                 AS summa
       FROM qrySaldo q
       WHERE konto LIKE '258%'
       GROUP BY q.rekvid
       UNION ALL
       --2580
       SELECT
         q.rekvid                                 AS rekv_id,
         '2580' :: VARCHAR(20)                    AS konto,
         'Emiteeritud võlakirjad' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2580%'
       GROUP BY q.rekvid
       UNION ALL
       --2581
       SELECT
         q.rekvid                 AS rekv_id,
         '2581' :: VARCHAR(20)    AS konto,
         'Laenud' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)        AS summa
       FROM qrySaldo q
       WHERE konto LIKE '2581%'
       GROUP BY q.rekvid
       UNION ALL
       --290
       SELECT
         q.rekvid                   AS rekv_id,
         '290' :: VARCHAR(20)       AS konto,
         'Reservid' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)          AS summa
       FROM qrySaldo q
       WHERE konto LIKE '290%'
       GROUP BY q.rekvid
       UNION ALL
       --291
       SELECT
         q.rekvid                                             AS rekv_id,
         '291' :: VARCHAR(20)                                 AS konto,
         'Aktsia- või osakapital ja ülekurss' :: VARCHAR(254) AS nimetus,
         sum(kr) - sum(db)                                    AS summa
       FROM qrySaldo q
       WHERE konto LIKE '291%'
       GROUP BY q.rekvid
       UNION ALL
       --29
       SELECT
         q.rekvid                                          AS rekv_id,
         '29' :: VARCHAR(20)                               AS konto,
         'Netovara' :: VARCHAR(254)                        AS nimetus,
         sum(db)
           FILTER (WHERE left(konto, 3) IN ('298', '299')) AS summa
       FROM qrySaldo q
       GROUP BY q.rekvid
       UNION ALL
       --1
       --Saldoandmikust (Sum: Kontod 1* Deebet) - (Sum: Kontod 1* Kreedit) - konto 103500 deebet + konto 103500 kreedit
       SELECT
         q.rekvid                AS rekv_id,
         '1' :: VARCHAR(20)      AS konto,
         'Varad' :: VARCHAR(254) AS nimetus,
         sum(db)
           FILTER (WHERE konto LIKE '1%') -
         sum(kr)
           FILTER (WHERE konto LIKE '1%') -
         sum(db)
           FILTER (WHERE konto LIKE '103500%') +
         sum(kr)
           FILTER (WHERE konto LIKE '103500%')
                                 AS summa
       FROM qrySaldo q
       GROUP BY q.rekvid

       UNION ALL
       -- põhiosa
       SELECT
         q.rekvid                           AS rekv_id,
         q.konto,
         l.nimetus,
         CASE WHEN COALESCE(l.tyyp, 1) = 1
           THEN coalesce(db, 0) - COALESCE(kr, 0)
         ELSE kr - db END :: NUMERIC(14, 2) AS summa
       FROM qrySaldo q
         LEFT OUTER JOIN com_kontoplaan l ON ltrim(rtrim(l.kood)) = ltrim(rtrim(q.konto))
       WHERE val(left(ltrim(rtrim(q.konto)), 1)) < 3

     ) qry
GROUP BY rekv_id, konto, nimetus
$BODY$
LANGUAGE SQL VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION eelarve.pikk_bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.pikk_bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.pikk_bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.pikk_bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbvaatleja;

/*
SELECT
  sum(summa),
  konto,
  nimetus
FROM eelarve.pikk_bilanss('2018-06-30' :: DATE, 63, 1)
GROUP BY konto, nimetus
ORDER BY konto
*/