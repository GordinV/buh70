DROP FUNCTION IF EXISTS palk.palk_kaart( DATE, DATE, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.palk_kaart(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    isikukood VARCHAR(20),
    isik      VARCHAR(254),
    leping_id INTEGER,
    koormus   NUMERIC(6, 2),
    pohikoht  INTEGER,
    toopaev   INTEGER,
    osakond   VARCHAR(254),
    amet      VARCHAR(254),
    palk      NUMERIC(12, 2),
    summa1    NUMERIC,
    summa2    NUMERIC,
    summa3    NUMERIC,
    summa4    NUMERIC,
    summa5    NUMERIC,
    summa6    NUMERIC,
    summa7    NUMERIC,
    summa8    NUMERIC,
    summa9    NUMERIC,
    summa10   NUMERIC,
    summa11   NUMERIC,
    summa12   NUMERIC,
    nimetus   VARCHAR(254),
    haig_1    INTEGER,
    haig_2    INTEGER,
    haig_3    INTEGER,
    haig_4    INTEGER,
    haig_5    INTEGER,
    haig_6    INTEGER,
    haig_7    INTEGER,
    haig_8    INTEGER,
    haig_9    INTEGER,
    haig_10   INTEGER,
    haig_11   INTEGER,
    haig_12   INTEGER,
    puhk1_1   INTEGER,
    puhk1_2   INTEGER,
    puhk1_3   INTEGER,
    puhk1_4   INTEGER,
    puhk1_5   INTEGER,
    puhk1_6   INTEGER,
    puhk1_7   INTEGER,
    puhk1_8   INTEGER,
    puhk1_9   INTEGER,
    puhk1_10  INTEGER,
    puhk1_11  INTEGER,
    puhk1_12  INTEGER,
    puhk2_1   INTEGER,
    puhk2_2   INTEGER,
    puhk2_3   INTEGER,
    puhk2_4   INTEGER,
    puhk2_5   INTEGER,
    puhk2_6   INTEGER,
    puhk2_7   INTEGER,
    puhk2_8   INTEGER,
    puhk2_9   INTEGER,
    puhk2_10  INTEGER,
    puhk2_11  INTEGER,
    puhk2_12  INTEGER,
    puhk3_1   INTEGER,
    puhk3_2   INTEGER,
    puhk3_3   INTEGER,
    puhk3_4   INTEGER,
    puhk3_5   INTEGER,
    puhk3_6   INTEGER,
    puhk3_7   INTEGER,
    puhk3_8   INTEGER,
    puhk3_9   INTEGER,
    puhk3_10  INTEGER,
    puhk3_11  INTEGER,
    puhk3_12  INTEGER,
    puhk4_1   INTEGER,
    puhk4_2   INTEGER,
    puhk4_3   INTEGER,
    puhk4_4   INTEGER,
    puhk4_5   INTEGER,
    puhk4_6   INTEGER,
    puhk4_7   INTEGER,
    puhk4_8   INTEGER,
    puhk4_9   INTEGER,
    puhk4_10  INTEGER,
    puhk4_11  INTEGER,
    puhk4_12  INTEGER,
    puhk5_1   INTEGER,
    puhk5_2   INTEGER,
    puhk5_3   INTEGER,
    puhk5_4   INTEGER,
    puhk5_5   INTEGER,
    puhk5_6   INTEGER,
    puhk5_7   INTEGER,
    puhk5_8   INTEGER,
    puhk5_9   INTEGER,
    puhk5_10  INTEGER,
    puhk5_11  INTEGER,
    puhk5_12  INTEGER,
    kom_1     INTEGER,
    kom_2     INTEGER,
    kom_3     INTEGER,
    kom_4     INTEGER,
    kom_5     INTEGER,
    kom_6     INTEGER,
    kom_7     INTEGER,
    kom_8     INTEGER,
    kom_9     INTEGER,
    kom_10    INTEGER,
    kom_11    INTEGER,
    kom_12    INTEGER,
    muu_1     INTEGER,
    muu_2     INTEGER,
    muu_3     INTEGER,
    muu_4     INTEGER,
    muu_5     INTEGER,
    muu_6     INTEGER,
    muu_7     INTEGER,
    muu_8     INTEGER,
    muu_9     INTEGER,
    muu_10    INTEGER,
    muu_11    INTEGER,
    muu_12    INTEGER

  ) AS
$BODY$
WITH qryPalkOper AS (
  -- предварительно выберем операции с ЗП суммированные по месяцам в разрезе договоров
    SELECT
      qryPalkOper.lepingid,
      qryPalkOper.kuu,
      qryPalkOper.aasta,
      qryPalkOper.liik,
      qryPalkOper.asutusest,
      qryPalkOper.konto,
      sum(qryPalkOper.summa1)  AS summa1,
      sum(qryPalkOper.summa2)  AS summa2,
      sum(qryPalkOper.summa3)  AS summa3,
      sum(qryPalkOper.summa4)  AS summa4,
      sum(qryPalkOper.summa5)  AS summa5,
      sum(qryPalkOper.summa6)  AS summa6,
      sum(qryPalkOper.summa7)  AS summa7,
      sum(qryPalkOper.summa8)  AS summa8,
      sum(qryPalkOper.summa9)  AS summa9,
      sum(qryPalkOper.summa10) AS summa10,
      sum(qryPalkOper.summa11) AS summa11,
      sum(qryPalkOper.summa12) AS summa12
    FROM (
           -- разбиваем суммы по месяцам
           SELECT
             (CASE WHEN month(po.kpv) = 1
               THEN summa
              ELSE 0 END)                                         AS summa1,
             (CASE WHEN month(po.kpv) = 2
               THEN summa
              ELSE 0 END)                                         AS summa2,
             (CASE WHEN month(po.kpv) = 3
               THEN summa
              ELSE 0 END)                                         AS summa3,
             (CASE WHEN month(po.kpv) = 4
               THEN summa
              ELSE 0 END)                                         AS summa4,
             (CASE WHEN month(po.kpv) = 5
               THEN summa
              ELSE 0 END)                                         AS summa5,
             (CASE WHEN month(po.kpv) = 6
               THEN summa
              ELSE 0 END)                                         AS summa6,
             (CASE WHEN month(po.kpv) = 7
               THEN summa
              ELSE 0 END)                                         AS summa7,
             (CASE WHEN month(po.kpv) = 8
               THEN summa
              ELSE 0 END)                                         AS summa8,
             (CASE WHEN month(po.kpv) = 9
               THEN summa
              ELSE 0 END)                                         AS summa9,
             (CASE WHEN month(po.kpv) = 10
               THEN summa
              ELSE 0 END)                                         AS summa10,
             (CASE WHEN month(po.kpv) = 11
               THEN summa
              ELSE 0 END)                                         AS summa11,
             (CASE WHEN month(po.kpv) = 12
               THEN summa
              ELSE 0 END)                                         AS summa12,
             po.lepingid,
             month(po.kpv)                                        AS kuu,
             year(po.kpv)                                         AS aasta,
             po.rekvid,
             ((l.properties :: JSONB ->> 'liik')) :: INTEGER      AS liik,
             ((l.properties :: JSONB ->> 'asutusest')) :: INTEGER AS asutusest,
             po.konto
           FROM palk.palk_oper po
             INNER JOIN libs.library l ON l.id = po.libid
           WHERE po.kpv >= l_kpv1 AND po.kpv <= l_kpv2
                 AND po.rekvid = (CASE WHEN l_kond IS NOT NULL AND NOT empty(l_kond)
             THEN l_rekvid
                                  ELSE po.rekvid END)
                 AND po.rekvid IN (SELECT rekv_id
                                   FROM get_asutuse_struktuur(l_rekvid))
         ) qryPalkOper
    GROUP BY qryPalkOper.lepingid, kuu, aasta, liik, konto, asutusest
)
SELECT
  a.regkood :: VARCHAR(20)                  AS isikukood,
  a.nimetus :: VARCHAR(254)                 AS isik,
  po.lepingid,
  t.koormus :: NUMERIC(6, 2),
  t.pohikoht :: INTEGER,
  t.toopaev :: INTEGER,
  o.nimetus :: VARCHAR(254)                 AS osakond,
  amet.nimetus :: VARCHAR(254)              AS amet,
  t.palk,
  po.summa1,
  po.summa2,
  po.summa3,
  po.summa4,
  po.summa5,
  po.summa6,
  po.summa7,
  po.summa8,
  po.summa9,
  po.summa10,
  po.summa11,
  po.summa12,
  po.nimetus,
  coalesce(qryPuudu.haig_1, 0) :: INTEGER   AS haig_1,
  coalesce(qryPuudu.haig_2, 0) :: INTEGER   AS haig_2,
  coalesce(qryPuudu.haig_3, 0) :: INTEGER   AS haig_3,
  coalesce(qryPuudu.haig_4, 0) :: INTEGER   AS haig_4,
  coalesce(qryPuudu.haig_5, 0) :: INTEGER   AS haig_5,
  coalesce(qryPuudu.haig_6, 0) :: INTEGER   AS haig_6,
  coalesce(qryPuudu.haig_7, 0) :: INTEGER   AS haig_7,
  coalesce(qryPuudu.haig_8, 0) :: INTEGER   AS haig_8,
  coalesce(qryPuudu.haig_9, 0) :: INTEGER   AS haig_9,
  coalesce(qryPuudu.haig_10, 0) :: INTEGER  AS haig_10,
  coalesce(qryPuudu.haig_11, 0) :: INTEGER  AS haig_11,
  coalesce(qryPuudu.haig_12, 0) :: INTEGER  AS haig_12,
  coalesce(qryPuudu.puhk1_1, 0) :: INTEGER  AS Puhk1_1,
  coalesce(qryPuudu.puhk1_2, 0) :: INTEGER  AS Puhk1_2,
  coalesce(qryPuudu.puhk1_3, 0) :: INTEGER  AS Puhk1_3,
  coalesce(qryPuudu.puhk1_4, 0) :: INTEGER  AS Puhk1_4,
  coalesce(qryPuudu.puhk1_5, 0) :: INTEGER  AS Puhk1_5,
  coalesce(qryPuudu.puhk1_6, 0) :: INTEGER  AS Puhk1_6,
  coalesce(qryPuudu.puhk1_7, 0) :: INTEGER  AS Puhk1_7,
  coalesce(qryPuudu.puhk1_8, 0) :: INTEGER  AS Puhk1_8,
  coalesce(qryPuudu.puhk1_9, 0) :: INTEGER  AS Puhk1_9,
  coalesce(qryPuudu.puhk1_10, 0) :: INTEGER AS Puhk1_10,
  coalesce(qryPuudu.puhk1_11, 0) :: INTEGER AS Puhk1_11,
  coalesce(qryPuudu.puhk1_12, 0) :: INTEGER AS Puhk1_12,
  coalesce(qryPuudu.puhk2_1, 0) :: INTEGER  AS Puhk2_1,
  coalesce(qryPuudu.puhk2_2, 0) :: INTEGER  AS Puhk2_2,
  coalesce(qryPuudu.puhk2_3, 0) :: INTEGER  AS Puhk2_3,
  coalesce(qryPuudu.puhk2_4, 0) :: INTEGER  AS Puhk2_4,
  coalesce(qryPuudu.puhk2_5, 0) :: INTEGER  AS Puhk2_5,
  coalesce(qryPuudu.puhk2_6, 0) :: INTEGER  AS Puhk2_6,
  coalesce(qryPuudu.puhk2_7, 0) :: INTEGER  AS Puhk2_7,
  coalesce(qryPuudu.puhk2_8, 0) :: INTEGER  AS Puhk2_8,
  coalesce(qryPuudu.puhk2_9, 0) :: INTEGER  AS Puhk2_9,
  coalesce(qryPuudu.puhk2_10, 0) :: INTEGER AS Puhk2_10,
  coalesce(qryPuudu.puhk2_11, 0) :: INTEGER AS Puhk2_11,
  coalesce(qryPuudu.puhk2_12, 0) :: INTEGER AS Puhk2_12,
  coalesce(qryPuudu.puhk3_1, 0) :: INTEGER  AS Puhk3_1,
  coalesce(qryPuudu.puhk3_2, 0) :: INTEGER  AS Puhk3_2,
  coalesce(qryPuudu.puhk3_3, 0) :: INTEGER  AS Puhk3_3,
  coalesce(qryPuudu.puhk3_4, 0) :: INTEGER  AS Puhk3_4,
  coalesce(qryPuudu.puhk3_5, 0) :: INTEGER  AS Puhk3_5,
  coalesce(qryPuudu.puhk3_6, 0) :: INTEGER  AS Puhk3_6,
  coalesce(qryPuudu.puhk3_7, 0) :: INTEGER  AS Puhk3_7,
  coalesce(qryPuudu.puhk3_8, 0) :: INTEGER  AS Puhk3_8,
  coalesce(qryPuudu.puhk3_9, 0) :: INTEGER  AS Puhk3_9,
  coalesce(qryPuudu.puhk3_10, 0) :: INTEGER AS Puhk3_10,
  coalesce(qryPuudu.puhk3_11, 0) :: INTEGER AS Puhk3_11,
  coalesce(qryPuudu.puhk3_12, 0) :: INTEGER AS Puhk3_12,
  coalesce(qryPuudu.puhk4_1, 0) :: INTEGER  AS Puhk4_1,
  coalesce(qryPuudu.puhk4_2, 0) :: INTEGER  AS Puhk4_2,
  coalesce(qryPuudu.puhk4_3, 0) :: INTEGER  AS Puhk4_3,
  coalesce(qryPuudu.puhk4_4, 0) :: INTEGER  AS Puhk4_4,
  coalesce(qryPuudu.puhk4_5, 0) :: INTEGER  AS Puhk4_5,
  coalesce(qryPuudu.puhk4_6, 0) :: INTEGER  AS Puhk4_6,
  coalesce(qryPuudu.puhk4_7, 0) :: INTEGER  AS Puhk4_7,
  coalesce(qryPuudu.puhk4_8, 0) :: INTEGER  AS Puhk4_8,
  coalesce(qryPuudu.puhk4_9, 0) :: INTEGER  AS Puhk4_9,
  coalesce(qryPuudu.puhk4_10, 0) :: INTEGER AS Puhk4_10,
  coalesce(qryPuudu.puhk4_11, 0) :: INTEGER AS Puhk4_11,
  coalesce(qryPuudu.puhk4_12, 0) :: INTEGER AS Puhk4_12,
  coalesce(qryPuudu.puhk5_1, 0) :: INTEGER  AS Puhk5_1,
  coalesce(qryPuudu.puhk5_2, 0) :: INTEGER  AS Puhk5_2,
  coalesce(qryPuudu.puhk5_3, 0) :: INTEGER  AS Puhk5_3,
  coalesce(qryPuudu.puhk5_4, 0) :: INTEGER  AS Puhk5_4,
  coalesce(qryPuudu.puhk5_5, 0) :: INTEGER  AS Puhk5_5,
  coalesce(qryPuudu.puhk5_6, 0) :: INTEGER  AS Puhk5_6,
  coalesce(qryPuudu.puhk5_7, 0) :: INTEGER  AS Puhk5_7,
  coalesce(qryPuudu.puhk5_8, 0) :: INTEGER  AS Puhk5_8,
  coalesce(qryPuudu.puhk5_9, 0) :: INTEGER  AS Puhk5_9,
  coalesce(qryPuudu.puhk5_10, 0) :: INTEGER AS Puhk5_10,
  coalesce(qryPuudu.puhk5_11, 0) :: INTEGER AS Puhk5_11,
  coalesce(qryPuudu.puhk5_12, 0) :: INTEGER AS Puhk5_12,
  coalesce(qryPuudu.kom_1, 0) :: INTEGER    AS kom_1,
  coalesce(qryPuudu.kom_2, 0) :: INTEGER    AS kom_2,
  coalesce(qryPuudu.kom_3, 0) :: INTEGER    AS kom_3,
  coalesce(qryPuudu.kom_4, 0) :: INTEGER    AS kom_4,
  coalesce(qryPuudu.kom_5, 0) :: INTEGER    AS kom_5,
  coalesce(qryPuudu.kom_6, 0) :: INTEGER    AS kom_6,
  coalesce(qryPuudu.kom_7, 0) :: INTEGER    AS kom_7,
  coalesce(qryPuudu.kom_8, 0) :: INTEGER    AS kom_8,
  coalesce(qryPuudu.kom_9, 0) :: INTEGER    AS kom_9,
  coalesce(qryPuudu.kom_10, 0) :: INTEGER   AS kom_10,
  coalesce(qryPuudu.kom_11, 0) :: INTEGER   AS kom_11,
  coalesce(qryPuudu.kom_12, 0) :: INTEGER   AS kom_12,
  coalesce(qryPuudu.muu_1, 0) :: INTEGER    AS muu_1,
  coalesce(qryPuudu.muu_2, 0) :: INTEGER    AS muu_2,
  coalesce(qryPuudu.muu_3, 0) :: INTEGER    AS muu_3,
  coalesce(qryPuudu.muu_4, 0) :: INTEGER    AS muu_4,
  coalesce(qryPuudu.muu_5, 0) :: INTEGER    AS muu_5,
  coalesce(qryPuudu.muu_6, 0) :: INTEGER    AS muu_6,
  coalesce(qryPuudu.muu_7, 0) :: INTEGER    AS muu_7,
  coalesce(qryPuudu.muu_8, 0) :: INTEGER    AS muu_8,
  coalesce(qryPuudu.muu_9, 0) :: INTEGER    AS muu_9,
  coalesce(qryPuudu.muu_10, 0) :: INTEGER   AS muu_10,
  coalesce(qryPuudu.muu_11, 0) :: INTEGER   AS muu_11,
  coalesce(qryPuudu.muu_12, 0) :: INTEGER   AS muu_12
FROM
  (
    -- Основная ЗП
    SELECT
      po.lepingid,
      sum(summa1)                AS summa1,
      sum(summa2)                AS summa2,
      sum(summa3)                AS summa3,
      sum(summa4)                AS summa4,
      sum(summa5)                AS summa5,
      sum(summa6)                AS summa6,
      sum(summa7)                AS summa7,
      sum(summa8)                AS summa8,
      sum(summa9)                AS summa9,
      sum(summa10)               AS summa10,
      sum(summa11)               AS summa11,
      sum(summa12)               AS summa12,
      'Põhipalk' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE (po.konto IN (SELECT unnest('{50000001,50010001,50012001,50014001,50021001,;
						50024001,	50025001,	50026001,	50027001,	50028001,	50029001, 50024001}' :: TEXT[]))
      OR left(po.konto,6) in ('500150','500200')
    )
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    -- Доп. плата
    SELECT
      po.lepingid,
      sum(summa1)                 AS summa1,
      sum(summa2)                 AS summa2,
      sum(summa3)                 AS summa3,
      sum(summa4)                 AS summa4,
      sum(summa5)                 AS summa5,
      sum(summa6)                 AS summa6,
      sum(summa7)                 AS summa7,
      sum(summa8)                 AS summa8,
      sum(summa9)                 AS summa9,
      sum(summa10)                AS summa10,
      sum(summa11)                AS summa11,
      sum(summa12)                AS summa12,
      'Lisatasud' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE (ltrim(rtrim(po.konto)) IN (SELECT unnest(
        '{5000001,5001001,5001201,5001401,5002101,5002401,5002501,5002701,5002801,5002601,5002901}' :: TEXT []))
        or left(po.konto,7) IN (SELECT unnest(
                                               '{5000001,5001001,5001201,5001401,5002101,5002401,5002501,5002701,5002801,5002601,5002901}' :: TEXT[])
      ))

          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    --Премии
    SELECT
      po.lepingid,
      sum(summa1)                             AS summa1,
      sum(summa2)                             AS summa2,
      sum(summa3)                             AS summa3,
      sum(summa4)                             AS summa4,
      sum(summa5)                             AS summa5,
      sum(summa6)                             AS summa6,
      sum(summa7)                             AS summa7,
      sum(summa8)                             AS summa8,
      sum(summa9)                             AS summa9,
      sum(summa10)                            AS summa10,
      sum(summa11)                            AS summa11,
      sum(summa12)                            AS summa12,
      'Preemiad, tulemuspalk' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.konto IN (SELECT unnest(
        '{50000301,50000302,50010301,50010302,50012301,50012302,50014301,50014302,50021301,50021302,50024301,50024302,50025301,50025302,
         50026301,50026302,50027301,50027302,50028301,50028302,50029301,50029302,50027301,50027302}' :: TEXT [])
    )
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                         AS summa1,
      sum(summa2)                         AS summa2,
      sum(summa3)                         AS summa3,
      sum(summa4)                         AS summa4,
      sum(summa5)                         AS summa5,
      sum(summa6)                         AS summa6,
      sum(summa7)                         AS summa7,
      sum(summa8)                         AS summa8,
      sum(summa9)                         AS summa9,
      sum(summa10)                        AS summa10,
      sum(summa11)                        AS summa11,
      sum(summa12)                        AS summa12,
      'Tööandja toetused' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE (po.konto IN (SELECT unnest(
        '{50000303,50010303,50012303,50014303,50021303,50024303,50025303,50026303,50027303,50028303,50029303}' :: TEXT [])
        )
        or left(po.konto,6) in ('500153','500203')
    )
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                                  AS summa1,
      sum(summa2)                                  AS summa2,
      sum(summa3)                                  AS summa3,
      sum(summa4)                                  AS summa4,
      sum(summa5)                                  AS summa5,
      sum(summa6)                                  AS summa6,
      sum(summa7)                                  AS summa7,
      sum(summa8)                                  AS summa8,
      sum(summa9)                                  AS summa9,
      sum(summa10)                                 AS summa10,
      sum(summa11)                                 AS summa11,
      sum(summa12)                                 AS summa12,
      'Puhkusetasud,ja -hüvitised' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE (left(po.konto, 7) IN (SELECT unnest(
        '{5000002, 5002902,5001002,5001202,5001402,5002102,
           5002402,5002502,5002602,5002702,5002802}' :: TEXT [])
    )
        )
          AND konto NOT IN (SELECT unnest('{50000023,50010023,50012023,50014023,50021023,50024023,50025023,
						50026023,50027023,50028023,50029023}' :: TEXT [])
    )
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                       AS summa1,
      sum(summa2)                       AS summa2,
      sum(summa3)                       AS summa3,
      sum(summa4)                       AS summa4,
      sum(summa5)                       AS summa5,
      sum(summa6)                       AS summa6,
      sum(summa7)                       AS summa7,
      sum(summa8)                       AS summa8,
      sum(summa9)                       AS summa9,
      sum(summa10)                      AS summa10,
      sum(summa11)                      AS summa11,
      sum(summa12)                      AS summa12,
      'Õppepuhkusetasu' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.konto IN (SELECT unnest(
        '{50000023,50010023,50012023,50014023,50021023,50024023,50025023,
             50026023,50027023,50028023,50029023}' :: TEXT [])
    )
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                           AS summa1,
      sum(summa2)                           AS summa2,
      sum(summa3)                           AS summa3,
      sum(summa4)                           AS summa4,
      sum(summa5)                           AS summa5,
      sum(summa6)                           AS summa6,
      sum(summa7)                           AS summa7,
      sum(summa8)                           AS summa8,
      sum(summa9)                           AS summa9,
      sum(summa10)                          AS summa10,
      sum(summa11)                          AS summa11,
      sum(summa12)                          AS summa12,
      'Täiendavad puhkused' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE left(po.konto, 6) IN ('103560')
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                AS summa1,
      sum(summa2)                AS summa2,
      sum(summa3)                AS summa3,
      sum(summa4)                AS summa4,
      sum(summa5)                AS summa5,
      sum(summa6)                AS summa6,
      sum(summa7)                AS summa7,
      sum(summa8)                AS summa8,
      sum(summa9)                AS summa9,
      sum(summa10)               AS summa10,
      sum(summa11)               AS summa11,
      sum(summa12)               AS summa12,
      'Hüvitised ja toetused' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE left(po.konto,6) IN (SELECT unnest('{500007,500107,500127,500147,500217, 500147,500257,500267,500277,500287,500297,500157,500207}' :: TEXT []))
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                 AS summa1,
      sum(summa2)                 AS summa2,
      sum(summa3)                 AS summa3,
      sum(summa4)                 AS summa4,
      sum(summa5)                 AS summa5,
      sum(summa6)                 AS summa6,
      sum(summa7)                 AS summa7,
      sum(summa8)                 AS summa8,
      sum(summa9)                 AS summa9,
      sum(summa10)                AS summa10,
      sum(summa11)                AS summa11,
      sum(summa12)                AS summa12,
      'Hüvitised' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.konto IN (SELECT unnest(
        '{500007,50029701,50000701,500107,500147,500157,500217,500247,500257,500287, 500267, 500207}' :: TEXT []))
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                               AS summa1,
      sum(summa2)                               AS summa2,
      sum(summa3)                               AS summa3,
      sum(summa4)                               AS summa4,
      sum(summa5)                               AS summa5,
      sum(summa6)                               AS summa6,
      sum(summa7)                               AS summa7,
      sum(summa8)                               AS summa8,
      sum(summa9)                               AS summa9,
      sum(summa10)                              AS summa10,
      sum(summa11)                              AS summa11,
      sum(summa12)                              AS summa12,
      'Võlaõiguslikud lepingud' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE (po.konto IN ('50026801','50029801')
               or left (po.konto,6) in ('500500')
        )
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                        AS summa1,
      sum(summa2)                        AS summa2,
      sum(summa3)                        AS summa3,
      sum(summa4)                        AS summa4,
      sum(summa5)                        AS summa5,
      sum(summa6)                        AS summa6,
      sum(summa7)                        AS summa7,
      sum(summa8)                        AS summa8,
      sum(summa9)                        AS summa9,
      sum(summa10)                       AS summa10,
      sum(summa11)                       AS summa11,
      sum(summa12)                       AS summa12,
      'Tootasu ettemaks' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.konto IN ('103930')
          AND po.liik = 1
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                    AS summa1,
      sum(summa2)                    AS summa2,
      sum(summa3)                    AS summa3,
      sum(summa4)                    AS summa4,
      sum(summa5)                    AS summa5,
      sum(summa6)                    AS summa6,
      sum(summa7)                    AS summa7,
      sum(summa8)                    AS summa8,
      sum(summa9)                    AS summa9,
      sum(summa10)                   AS summa10,
      sum(summa11)                   AS summa11,
      sum(summa12)                   AS summa12,
      'Sotsiaalmaks' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.konto IN ('506000', '103931')
          AND po.liik = 5
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                             AS summa1,
      sum(summa2)                             AS summa2,
      sum(summa3)                             AS summa3,
      sum(summa4)                             AS summa4,
      sum(summa5)                             AS summa5,
      sum(summa6)                             AS summa6,
      sum(summa7)                             AS summa7,
      sum(summa8)                             AS summa8,
      sum(summa9)                             AS summa9,
      sum(summa10)                            AS summa10,
      sum(summa11)                            AS summa11,
      sum(summa12)                            AS summa12,
      'TÖÖTUSKINDLUSTUSMAKS ' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.liik = 7 AND empty(po.asutusest)
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                            AS summa1,
      sum(summa2)                            AS summa2,
      sum(summa3)                            AS summa3,
      sum(summa4)                            AS summa4,
      sum(summa5)                            AS summa5,
      sum(summa6)                            AS summa6,
      sum(summa7)                            AS summa7,
      sum(summa8)                            AS summa8,
      sum(summa9)                            AS summa9,
      sum(summa10)                           AS summa10,
      sum(summa11)                           AS summa11,
      sum(summa12)                           AS summa12,
      'TÖÖTUSKINDLUSTUSMAKS' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.liik = 7 AND NOT empty(po.asutusest)
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                     AS summa1,
      sum(summa2)                     AS summa2,
      sum(summa3)                     AS summa3,
      sum(summa4)                     AS summa4,
      sum(summa5)                     AS summa5,
      sum(summa6)                     AS summa6,
      sum(summa7)                     AS summa7,
      sum(summa8)                     AS summa8,
      sum(summa9)                     AS summa9,
      sum(summa10)                    AS summa10,
      sum(summa11)                    AS summa11,
      sum(summa12)                    AS summa12,
      'Pensioonimaks' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.liik = 8
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)            AS summa1,
      sum(summa2)            AS summa2,
      sum(summa3)            AS summa3,
      sum(summa4)            AS summa4,
      sum(summa5)            AS summa5,
      sum(summa6)            AS summa6,
      sum(summa7)            AS summa7,
      sum(summa8)            AS summa8,
      sum(summa9)            AS summa9,
      sum(summa10)           AS summa10,
      sum(summa11)           AS summa11,
      sum(summa12)           AS summa12,
      'Tasu' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.liik = 6
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)                AS summa1,
      sum(summa2)                AS summa2,
      sum(summa3)                AS summa3,
      sum(summa4)                AS summa4,
      sum(summa5)                AS summa5,
      sum(summa6)                AS summa6,
      sum(summa7)                AS summa7,
      sum(summa8)                AS summa8,
      sum(summa9)                AS summa9,
      sum(summa10)               AS summa10,
      sum(summa11)               AS summa11,
      sum(summa12)               AS summa12,
      'Tulumaks' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.liik = 4
    GROUP BY lepingid
    UNION ALL
    SELECT
      po.lepingid,
      sum(summa1)            AS summa1,
      sum(summa2)            AS summa2,
      sum(summa3)            AS summa3,
      sum(summa4)            AS summa4,
      sum(summa5)            AS summa5,
      sum(summa6)            AS summa6,
      sum(summa7)            AS summa7,
      sum(summa8)            AS summa8,
      sum(summa9)            AS summa9,
      sum(summa10)           AS summa10,
      sum(summa11)           AS summa11,
      sum(summa12)           AS summa12,
      'Muud' :: VARCHAR(254) AS NIMETUS
    FROM qryPalkOper po
    WHERE po.liik = 2
    GROUP BY lepingid

  ) po

  LEFT OUTER JOIN (
                    WITH qryPuudumine AS (
                      -- собираем здесь данные о пропусках раб. места, сгруппированные по договорам , по месяцам
                      WITH qryPeriods AS (
                        -- сделаем периоды
                          SELECT
                            kuu,
                            year(date()) AS aasta,
                            t.id         AS lepingid
                          FROM unnest('{1,2,3,4,5,6,7,8,9,10,11,12}' :: INTEGER []) AS kuu, palk.tooleping t
                          WHERE t.rekvid = l_rekvid
                          ORDER BY lepingid, kuu, aasta
                      )
                      -- разбиваем дни по периодам
                      SELECT
                        lepingid,
                        CASE WHEN kuu = 1
                          THEN paevad
                        ELSE 0 END AS paevad1,
                        CASE WHEN kuu = 2
                          THEN paevad
                        ELSE 0 END AS paevad2,
                        CASE WHEN kuu = 3
                          THEN paevad
                        ELSE 0 END AS paevad3,
                        CASE WHEN kuu = 4
                          THEN paevad
                        ELSE 0 END AS paevad4,
                        CASE WHEN kuu = 5
                          THEN paevad
                        ELSE 0 END AS paevad5,
                        CASE WHEN kuu = 6
                          THEN paevad
                        ELSE 0 END AS paevad6,
                        CASE WHEN kuu = 7
                          THEN paevad
                        ELSE 0 END AS paevad7,
                        CASE WHEN kuu = 8
                          THEN paevad
                        ELSE 0 END AS paevad8,
                        CASE WHEN kuu = 9
                          THEN paevad
                        ELSE 0 END AS paevad9,
                        CASE WHEN kuu = 10
                          THEN paevad
                        ELSE 0 END AS paevad10,
                        CASE WHEN kuu = 11
                          THEN paevad
                        ELSE 0 END AS paevad11,
                        CASE WHEN kuu = 12
                          THEN paevad
                        ELSE 0 END AS paevad12,
                        puudumiste_liik,
                        tyyp
                      FROM (
                             SELECT
                               qryPeriods.kuu,
                               qryPeriods.aasta,
                               palk.get_days_of_month_in_period(qryPeriods.kuu, qryPeriods.aasta, p.kpv1,
                                                                p.kpv2) AS paevad,
                               p.puudumiste_liik,
                               p.tyyp,
                               p.lepingid
                             FROM qryPeriods
                               INNER JOIN palk.tooleping t ON t.id = qryPeriods.lepingid
                               INNER JOIN palk.puudumine p
                                 ON ((YEAR(p.kpv1) = qryPeriods.aasta AND MONTH(p.kpv1) = qryPeriods.kuu)
                                     OR (YEAR(p.kpv2) = qryPeriods.aasta AND MONTH(p.kpv2) = qryPeriods.kuu)) AND
                                    qryPeriods.lepingid = p.lepingid
                             WHERE t.rekvid = l_rekvid
                           ) qry
                      WHERE kuu >= month(l_kpv1) AND kuu <= month(l_kpv2) AND aasta = year(l_kpv1)
                      ORDER BY lepingid, kuu, aasta
                    )
                    -- выбираем больничные
                    SELECT
                      lepingid,
                      sum(paevad1)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_1,
                      sum(paevad2)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_2,
                      sum(paevad3)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_3,
                      sum(paevad4)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_4,
                      sum(paevad5)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_5,
                      sum(paevad6)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_6,
                      sum(paevad7)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_7,
                      sum(paevad8)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_8,
                      sum(paevad9)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_9,
                      sum(paevad10)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_10,
                      sum(paevad11)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_11,
                      sum(paevad12)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS')              AS haig_12,
                      sum(paevad1)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_1,
                      -- pohipuhkus
                      sum(paevad2)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_2,
                      sum(paevad3)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_3,
                      sum(paevad4)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_4,
                      sum(paevad5)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_5,
                      sum(paevad6)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_6,
                      sum(paevad7)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_7,
                      sum(paevad8)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_8,
                      sum(paevad9)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_9,
                      sum(paevad10)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_10,
                      sum(paevad11)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_11,
                      sum(paevad12)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 1) AS puhk1_12,
                      sum(paevad1)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_1,
                      -- lisa staaz
                      sum(paevad2)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_2,
                      sum(paevad3)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_3,
                      sum(paevad4)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_4,
                      sum(paevad5)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_5,
                      sum(paevad6)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_6,
                      sum(paevad7)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_7,
                      sum(paevad8)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_8,
                      sum(paevad9)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_9,
                      sum(paevad10)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_10,
                      sum(paevad11)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_11,
                      sum(paevad12)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 2) AS puhk2_12,
                      sum(paevad1)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_1,
                      sum(paevad2)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_2,
                      -- lapsepuhkus
                      sum(paevad3)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_3,
                      sum(paevad4)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_4,
                      sum(paevad5)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_5,
                      sum(paevad6)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_6,
                      sum(paevad7)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_7,
                      sum(paevad8)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_8,
                      sum(paevad9)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_9,
                      sum(paevad10)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_10,
                      sum(paevad11)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_11,
                      sum(paevad12)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 3) AS puhk3_12,
                      sum(paevad1)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_1,
                      sum(paevad2)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_2,
                      -- oma arvelt
                      sum(paevad3)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_3,
                      sum(paevad4)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_4,
                      sum(paevad5)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_5,
                      sum(paevad6)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_6,
                      sum(paevad7)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_7,
                      sum(paevad8)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_8,
                      sum(paevad9)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_9,
                      sum(paevad10)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_10,
                      sum(paevad11)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_11,
                      sum(paevad12)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 4) AS puhk4_12,
                      sum(paevad1)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_1,
                      sum(paevad2)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_2,
                      -- õppepuhkus
                      sum(paevad3)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_3,
                      sum(paevad4)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_4,
                      sum(paevad5)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_5,
                      sum(paevad6)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_6,
                      sum(paevad7)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_7,
                      sum(paevad8)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_8,
                      sum(paevad9)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_9,
                      sum(paevad10)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_10,
                      sum(paevad11)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_11,
                      sum(paevad12)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS' AND tyyp = 5) AS puhk5_12,
                      sum(paevad1)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_1,
                      sum(paevad2)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_2,
                      -- komandeeringud
                      sum(paevad3)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_3,
                      sum(paevad4)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_4,
                      sum(paevad5)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_5,
                      sum(paevad6)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_6,
                      sum(paevad7)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_7,
                      sum(paevad8)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_8,
                      sum(paevad9)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_9,
                      sum(paevad10)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_10,
                      sum(paevad11)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_11,
                      sum(paevad12)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOMANDEERING')        AS kom_12,
                      sum(paevad1)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_1,
                      sum(paevad2)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_2,
                      -- komandeeringud
                      sum(paevad3)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_3,
                      sum(paevad4)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_4,
                      sum(paevad5)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_5,
                      sum(paevad6)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_6,
                      sum(paevad7)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_7,
                      sum(paevad8)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_8,
                      sum(paevad9)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_9,
                      sum(paevad10)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_10,
                      sum(paevad11)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_11,
                      sum(paevad12)
                        FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU')                 AS muu_12
                    FROM qryPuudumine
                    GROUP BY lepingid
                  ) qryPuudu ON qryPuudu.lepingid = po.lepingid
  INNER JOIN palk.tooleping t ON t.id = po.lepingid
  INNER JOIN libs.asutus a ON a.id = t.parentid
  INNER JOIN libs.library o ON t.osakondid = o.id
  INNER JOIN libs.library amet ON t.ametid = amet.id

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.palk_kaart( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.palk_kaart( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.palk_kaart( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;


/*

SELECT *
FROM palk.palk_kaart('2021-01-01', '2021-01-31', 132, 0 :: INTEGER)
where isikukood = '36903122245'
*/