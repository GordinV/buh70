DROP FUNCTION IF EXISTS palk.palk_kaart_(DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.palk_kaart_2025(DATE, DATE, INTEGER, INTEGER);

-- uuendatud 28.02.2025 V. Beshekerskas
CREATE OR REPLACE FUNCTION palk.palk_kaart_2025(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE
            (
                isikukood     VARCHAR(20),
                isik          VARCHAR(254),
                leping_id     INTEGER,
                koormus       NUMERIC(6, 2),
                pohikoht      INTEGER,
                toopaev       INTEGER,
                osakonna_kood VARCHAR(20),
                osakond       VARCHAR(254),
                amet          VARCHAR(254),
                palk          NUMERIC(12, 2),
                summa1        NUMERIC,
                summa2        NUMERIC,
                summa3        NUMERIC,
                summa4        NUMERIC,
                summa5        NUMERIC,
                summa6        NUMERIC,
                summa7        NUMERIC,
                summa8        NUMERIC,
                summa9        NUMERIC,
                summa10       NUMERIC,
                summa11       NUMERIC,
                summa12       NUMERIC,
                arv_1         NUMERIC,
                arv_2         NUMERIC,
                arv_3         NUMERIC,
                arv_4         NUMERIC,
                arv_5         NUMERIC,
                arv_6         NUMERIC,
                arv_7         NUMERIC,
                arv_8         NUMERIC,
                arv_9         NUMERIC,
                arv_10        NUMERIC,
                arv_11        NUMERIC,
                arv_12        NUMERIC,
                kinni_1       NUMERIC,
                kinni_2       NUMERIC,
                kinni_3       NUMERIC,
                kinni_4       NUMERIC,
                kinni_5       NUMERIC,
                kinni_6       NUMERIC,
                kinni_7       NUMERIC,
                kinni_8       NUMERIC,
                kinni_9       NUMERIC,
                kinni_10      NUMERIC,
                kinni_11      NUMERIC,
                kinni_12      NUMERIC,
                nimetus       VARCHAR(254),
                haig_1        INTEGER,
                haig_2        INTEGER,
                haig_3        INTEGER,
                haig_4        INTEGER,
                haig_5        INTEGER,
                haig_6        INTEGER,
                haig_7        INTEGER,
                haig_8        INTEGER,
                haig_9        INTEGER,
                haig_10       INTEGER,
                haig_11       INTEGER,
                haig_12       INTEGER,
                puhk1_1       INTEGER,
                puhk1_2       INTEGER,
                puhk1_3       INTEGER,
                puhk1_4       INTEGER,
                puhk1_5       INTEGER,
                puhk1_6       INTEGER,
                puhk1_7       INTEGER,
                puhk1_8       INTEGER,
                puhk1_9       INTEGER,
                puhk1_10      INTEGER,
                puhk1_11      INTEGER,
                puhk1_12      INTEGER,
                puhk2_1       INTEGER,
                puhk2_2       INTEGER,
                puhk2_3       INTEGER,
                puhk2_4       INTEGER,
                puhk2_5       INTEGER,
                puhk2_6       INTEGER,
                puhk2_7       INTEGER,
                puhk2_8       INTEGER,
                puhk2_9       INTEGER,
                puhk2_10      INTEGER,
                puhk2_11      INTEGER,
                puhk2_12      INTEGER,
                puhk3_1       INTEGER,
                puhk3_2       INTEGER,
                puhk3_3       INTEGER,
                puhk3_4       INTEGER,
                puhk3_5       INTEGER,
                puhk3_6       INTEGER,
                puhk3_7       INTEGER,
                puhk3_8       INTEGER,
                puhk3_9       INTEGER,
                puhk3_10      INTEGER,
                puhk3_11      INTEGER,
                puhk3_12      INTEGER,
                puhk4_1       INTEGER,
                puhk4_2       INTEGER,
                puhk4_3       INTEGER,
                puhk4_4       INTEGER,
                puhk4_5       INTEGER,
                puhk4_6       INTEGER,
                puhk4_7       INTEGER,
                puhk4_8       INTEGER,
                puhk4_9       INTEGER,
                puhk4_10      INTEGER,
                puhk4_11      INTEGER,
                puhk4_12      INTEGER,
                puhk5_1       INTEGER,
                puhk5_2       INTEGER,
                puhk5_3       INTEGER,
                puhk5_4       INTEGER,
                puhk5_5       INTEGER,
                puhk5_6       INTEGER,
                puhk5_7       INTEGER,
                puhk5_8       INTEGER,
                puhk5_9       INTEGER,
                puhk5_10      INTEGER,
                puhk5_11      INTEGER,
                puhk5_12      INTEGER,
                puhk6_1       INTEGER,
                puhk6_2       INTEGER,
                puhk6_3       INTEGER,
                puhk6_4       INTEGER,
                puhk6_5       INTEGER,
                puhk6_6       INTEGER,
                puhk6_7       INTEGER,
                puhk6_8       INTEGER,
                puhk6_9       INTEGER,
                puhk6_10      INTEGER,
                puhk6_11      INTEGER,
                puhk6_12      INTEGER,
                puhk7_1       INTEGER,
                puhk7_2       INTEGER,
                puhk7_3       INTEGER,
                puhk7_4       INTEGER,
                puhk7_5       INTEGER,
                puhk7_6       INTEGER,
                puhk7_7       INTEGER,
                puhk7_8       INTEGER,
                puhk7_9       INTEGER,
                puhk7_10      INTEGER,
                puhk7_11      INTEGER,
                puhk7_12      INTEGER,
                kom_1         INTEGER,
                kom_2         INTEGER,
                kom_3         INTEGER,
                kom_4         INTEGER,
                kom_5         INTEGER,
                kom_6         INTEGER,
                kom_7         INTEGER,
                kom_8         INTEGER,
                kom_9         INTEGER,
                kom_10        INTEGER,
                kom_11        INTEGER,
                kom_12        INTEGER,
                muu_1         INTEGER,
                muu_2         INTEGER,
                muu_3         INTEGER,
                muu_4         INTEGER,
                muu_5         INTEGER,
                muu_6         INTEGER,
                muu_7         INTEGER,
                muu_8         INTEGER,
                muu_9         INTEGER,
                muu_10        INTEGER,
                muu_11        INTEGER,
                muu_12        INTEGER,
                idx           INTEGER,
                liik          INTEGER

            )
AS
$BODY$
with
    params as (select *,
                      l_kpv1                                                                                                                    as kpv_1,
                      l_kpv2                                                                                                                    as kpv_2,
                      l_rekvid as rekv_id
                          from palk.palk_kulu_kontod
              ),
    qryPalkOper AS (
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
                  FROM
                      (
                          -- разбиваем суммы по месяцам
                          SELECT
                              (CASE
                                   WHEN month(po.kpv) = 1
                                       THEN summa
                                   ELSE 0 END)                                     AS summa1,
                              (CASE
                                   WHEN month(po.kpv) = 2
                                       THEN summa
                                   ELSE 0 END)                                     AS summa2,
                              (CASE
                                   WHEN month(po.kpv) = 3
                                       THEN summa
                                   ELSE 0 END)                                     AS summa3,
                              (CASE
                                   WHEN month(po.kpv) = 4
                                       THEN summa
                                   ELSE 0 END)                                     AS summa4,
                              (CASE
                                   WHEN month(po.kpv) = 5
                                       THEN summa
                                   ELSE 0 END)                                     AS summa5,
                              (CASE
                                   WHEN month(po.kpv) = 6
                                       THEN summa
                                   ELSE 0 END)                                     AS summa6,
                              (CASE
                                   WHEN month(po.kpv) = 7
                                       THEN summa
                                   ELSE 0 END)                                     AS summa7,
                              (CASE
                                   WHEN month(po.kpv) = 8
                                       THEN summa
                                   ELSE 0 END)                                     AS summa8,
                              (CASE
                                   WHEN month(po.kpv) = 9
                                       THEN summa
                                   ELSE 0 END)                                     AS summa9,
                              (CASE
                                   WHEN month(po.kpv) = 10
                                       THEN summa
                                   ELSE 0 END)                                     AS summa10,
                              (CASE
                                   WHEN month(po.kpv) = 11
                                       THEN summa
                                   ELSE 0 END)                                     AS summa11,
                              (CASE
                                   WHEN month(po.kpv) = 12
                                       THEN summa
                                   ELSE 0 END)                                     AS summa12,
                              po.lepingid,
                              month(po.kpv)                                        AS kuu,
                              year(po.kpv)                                         AS aasta,
                              po.rekvid,
                              ((l.properties :: JSONB ->> 'liik')) :: INTEGER      AS liik,
                              ((l.properties :: JSONB ->> 'asutusest')) :: INTEGER AS asutusest,
                              po.konto
                          FROM
                              palk.palk_oper              po
                                  INNER JOIN libs.library l ON l.id = po.libid,
                              params                      p
                          WHERE
                                po.kpv >= p.kpv_1
                            AND po.kpv <= p.kpv_2
                            AND po.rekvid = (CASE
                                                 WHEN l_kond IS NOT NULL AND NOT empty(l_kond)
                                                     THEN p.rekv_id
                                                 ELSE po.rekvid END)
                            AND po.rekvid IN (
                                                 SELECT
                                                     rekv_id
                                                 FROM
                                                     get_asutuse_struktuur(p.rekv_id)
                                             )
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
    o.kood::VARCHAR(20)                       AS osakonna_kood,
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
    coalesce(po.arv_1, 0)                     AS arv_1,
    coalesce(po.arv_2, 0)                     AS arv_2,
    coalesce(po.arv_3, 0)                     AS arv_3,
    coalesce(po.arv_4, 0)                     AS arv_4,
    coalesce(po.arv_5, 0)                     AS arv_5,
    coalesce(po.arv_6, 0)                     AS arv_6,
    coalesce(po.arv_7, 0)                     AS arv_7,
    coalesce(po.arv_8, 0)                     AS arv_8,
    coalesce(po.arv_9, 0)                     AS arv_9,
    coalesce(po.arv_10, 0)                    AS arv_10,
    coalesce(po.arv_11, 0)                    AS arv_11,
    coalesce(po.arv_12, 0)                    AS arv_12,
    coalesce(po.kinni_1, 0)                   AS kinni_1,
    coalesce(po.kinni_2, 0)                   AS kinni_2,
    coalesce(po.kinni_3, 0)                   AS kinni_3,
    coalesce(po.kinni_4, 0)                   AS kinni_4,
    coalesce(po.kinni_5, 0)                   AS kinni_5,
    coalesce(po.kinni_6, 0)                   AS kinni_6,
    coalesce(po.kinni_7, 0)                   AS kinni_7,
    coalesce(po.kinni_8, 0)                   AS kinni_8,
    coalesce(po.kinni_9, 0)                   AS kinni_9,
    coalesce(po.kinni_10, 0)                  AS kinni_10,
    coalesce(po.kinni_11, 0)                  AS kinni_11,
    coalesce(po.kinni_12, 0)                  AS kinni_12,
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
    0 :: INTEGER                              AS Puhk6_1,
    0 :: INTEGER                              AS Puhk6_2,
    0 :: INTEGER                              AS Puhk6_3,
    0 :: INTEGER                              AS Puhk6_4,
    0 :: INTEGER                              AS Puhk6_5,
    0 :: INTEGER                              AS Puhk6_6,
    0 :: INTEGER                              AS Puhk6_7,
    0 :: INTEGER                              AS Puhk6_8,
    0 :: INTEGER                              AS Puhk6_9,
    0 :: INTEGER                              AS Puhk6_10,
    0 :: INTEGER                              AS Puhk6_11,
    0 :: INTEGER                              AS Puhk6_12,
    0 :: INTEGER                              AS Puhk7_1,
    0 :: INTEGER                              AS Puhk7_2,
    0 :: INTEGER                              AS Puhk7_3,
    0 :: INTEGER                              AS Puhk7_4,
    0 :: INTEGER                              AS Puhk7_5,
    0 :: INTEGER                              AS Puhk7_6,
    0 :: INTEGER                              AS Puhk7_7,
    0 :: INTEGER                              AS Puhk7_8,
    0 :: INTEGER                              AS Puhk7_9,
    0 :: INTEGER                              AS Puhk7_10,
    0 :: INTEGER                              AS Puhk7_11,
    0 :: INTEGER                              AS Puhk7_12,
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
    coalesce(qryPuudu.muu_12, 0) :: INTEGER   AS muu_12,
    idx,
    CASE
        WHEN liik = 1 THEN liik
        WHEN liik IN (2, 3, 8, 4, 6, 70) THEN 2
        ELSE 3 END                            AS liik
FROM
    (
        WITH
            preArv AS (
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
                              'Põhipalk' :: VARCHAR(254) AS NIMETUS,
                              10                         AS idx,
                              po.liik
                          FROM
                              qryPalkOper po,
                              params      p
                          WHERE
                                (po.konto IN (
                                                 SELECT
                                                     unnest(p.pohi_palk_kontod)
                                             )
                                    )
                            AND po.liik = 1
                          GROUP BY lepingid, po.liik
                          UNION ALL
                          -- Lisatasud
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
                              'Lisatasud' :: VARCHAR(254) AS NIMETUS,
                              20                          AS idx,
                              po.liik
                          FROM
                              qryPalkOper po,
                              params      p
                          WHERE
                                ltrim(rtrim(po.konto)) IN (
                                                              SELECT unnest(p.lisa_tasud_kontod)
                                                          )
                            AND po.liik = 1
                          GROUP BY lepingid, po.liik
                          UNION ALL
                          -- Muud lisatasud
                          SELECT
                              po.lepingid,
                              sum(summa1)                      AS summa1,
                              sum(summa2)                      AS summa2,
                              sum(summa3)                      AS summa3,
                              sum(summa4)                      AS summa4,
                              sum(summa5)                      AS summa5,
                              sum(summa6)                      AS summa6,
                              sum(summa7)                      AS summa7,
                              sum(summa8)                      AS summa8,
                              sum(summa9)                      AS summa9,
                              sum(summa10)                     AS summa10,
                              sum(summa11)                     AS summa11,
                              sum(summa12)                     AS summa12,
                              'Muud lisatasud' :: VARCHAR(254) AS NIMETUS,
                              57                               AS idx,
                              po.liik
                          FROM
                              qryPalkOper po,
                              params      p
                          WHERE
                                ltrim(rtrim(po.konto)) IN (
                                                              SELECT unnest(p.muud_lisa_tasud_kontod)
                                                          )
                            AND po.liik = 1
                          GROUP BY lepingid, po.liik
                          UNION ALL
                          --Preemiad, tulemuspa
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
                              'Preemiad, tulemuspalk' :: VARCHAR(254) AS NIMETUS,
                              30                                      AS idx,
                              po.liik
                          FROM
                              qryPalkOper po,
                              params      p
                          WHERE
                                po.konto IN (
                                                SELECT
                                                    unnest(p.preemiad_kontod)
                                            )
                            AND po.liik = 1
                          GROUP BY lepingid, po.liik
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
                              'Puhkusetasud' :: VARCHAR(254) AS NIMETUS,
                              40                             AS idx,
                              po.liik
                          FROM
                              qryPalkOper po,
                              params      p
                          WHERE
                                (po.konto IN (
                                                 SELECT
                                                     unnest(p.puhkused_kontod)
                                             )
                                    OR left(po.konto, 6) IN ('500153', '500203')
                                    )
                            AND po.liik = 1
                          GROUP BY lepingid, po.liik
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
                              'Koolitus' :: VARCHAR(254) AS NIMETUS,
                              50                         AS idx,
                              po.liik
                          FROM
                              qryPalkOper po,
                              params      p
                          WHERE
                                (left(po.konto, 7) IN (
                                                          SELECT
                                                              unnest(p.koolitus_kontod)
                                                      )
                                    )
                            AND konto NOT IN (
                                                 SELECT
                                                     unnest('{50000023,50010023,50012023,50014023,50021023,50024023,50025023,
						50026023,50027023,50028023,50029023}' :: TEXT[])
                                             )
                            AND po.liik = 1
                          GROUP BY lepingid, po.liik
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
                              'Hüvitised ja toetused' :: VARCHAR(254) AS NIMETUS,
                              55                                      AS idx,
                              po.liik
                          FROM
                              qryPalkOper po,
                              params      p
                          WHERE
                                po.konto IN (
                                                SELECT
                                                    unnest(p.huvitised_kontod)
                                            )
                            AND po.liik = 1
                          GROUP BY lepingid, po.liik
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
                              'Võlaõiguslikud lepingud' :: VARCHAR(254) AS NIMETUS,
                              57                                        AS idx,
                              po.liik
                          FROM
                              qryPalkOper po,
                              params      p
                          WHERE
                                po.konto IN (
                                                SELECT
                                                    unnest(p.vola_kontod)
                                            )
                            AND po.liik = 1
                          GROUP BY lepingid, po.liik
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
                              'Töötasu ettemak' :: VARCHAR(254) AS NIMETUS,
                              60                                AS idx,
                              po.liik

                          FROM
                              qryPalkOper po
                          WHERE
                                left(po.konto, 6) = '103930'
                            AND po.liik = 1
                          GROUP BY lepingid, po.liik
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
                              'Sotsiaalmaks' :: VARCHAR(254) AS NIMETUS,
                              200                            AS idx,
                              po.liik
                          FROM
                              qryPalkOper po
                          WHERE
                                po.konto IN ('506000', '103931')
                            AND po.liik = 5
                          GROUP BY lepingid, po.liik
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
                              'TÖÖTUSKINDLUSTUSMAKS ' :: VARCHAR(254) AS NIMETUS,
                              120                                     AS idx,

                              70                                      AS liik
                          FROM
                              qryPalkOper po
                          WHERE
                                po.liik = 7
                            AND empty(po.asutusest)
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
                              'TÖÖTUSKINDLUSTUSMAKS' :: VARCHAR(254) AS NIMETUS,
                              210                                    AS idx,
                              71                                     AS liik
                          FROM
                              qryPalkOper po
                          WHERE
                                po.liik = 7
                            AND NOT empty(po.asutusest)
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
                              'Pensioonimaks' :: VARCHAR(254) AS NIMETUS,
                              130                             AS idx,
                              po.liik
                          FROM
                              qryPalkOper po
                          WHERE
                              po.liik = 8
                          GROUP BY lepingid, po.liik
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
                              'Tasu' :: VARCHAR(254) AS NIMETUS,
                              300                    AS idx,
                              po.liik
                          FROM
                              qryPalkOper po
                          WHERE
                              po.liik = 6
                          GROUP BY lepingid, po.liik
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
                              'Tulumaks' :: VARCHAR(254) AS NIMETUS,
                              140                        AS idx,
                              po.liik
                          FROM
                              qryPalkOper po
                          WHERE
                              po.liik = 4
                          GROUP BY lepingid, po.liik
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
                              'Muud' :: VARCHAR(254) AS NIMETUS,
                              400                    AS idx,
                              po.liik
                          FROM
                              qryPalkOper po
                          WHERE
                              po.liik = 2
                          GROUP BY lepingid, po.liik
                      ),
            qryKokku AS (
                          SELECT
                              lepingid,
                              sum(summa1) FILTER (WHERE liik = 1)                  AS arv1,
                              sum(summa2) FILTER (WHERE liik = 1)                  AS arv2,
                              sum(summa3) FILTER (WHERE liik = 1)                  AS arv3,
                              sum(summa4) FILTER (WHERE liik = 1)                  AS arv4,
                              sum(summa5) FILTER (WHERE liik = 1)                  AS arv5,
                              sum(summa6) FILTER (WHERE liik = 1)                  AS arv6,
                              sum(summa7) FILTER (WHERE liik = 1)                  AS arv7,
                              sum(summa8) FILTER (WHERE liik = 1)                  AS arv8,
                              sum(summa9) FILTER (WHERE liik = 1)                  AS arv9,
                              sum(summa10) FILTER (WHERE liik = 1)                 AS arv10,
                              sum(summa11) FILTER (WHERE liik = 1)                 AS arv11,
                              sum(summa12) FILTER (WHERE liik = 1)                 AS arv12,
                              sum(summa1) FILTER (WHERE liik IN (2, 3, 4, 8, 70))  AS kinni_1,
                              sum(summa2) FILTER (WHERE liik IN (2, 3, 4, 8, 70))  AS kinni_2,
                              sum(summa3) FILTER (WHERE liik IN (2, 3, 4, 8, 70))  AS kinni_3,
                              sum(summa4) FILTER (WHERE liik IN (2, 3, 4, 8, 70))  AS kinni_4,
                              sum(summa5) FILTER (WHERE liik IN (2, 3, 4, 8, 70))  AS kinni_5,
                              sum(summa6) FILTER (WHERE liik IN (2, 3, 4, 8, 70))  AS kinni_6,
                              sum(summa7) FILTER (WHERE liik IN (2, 3, 4, 8, 70))  AS kinni_7,
                              sum(summa8) FILTER (WHERE liik IN (2, 3, 4, 8, 70))  AS kinni_8,
                              sum(summa9) FILTER (WHERE liik IN (2, 3, 4, 8, 70))  AS kinni_9,
                              sum(summa10) FILTER (WHERE liik IN (2, 3, 4, 8, 70)) AS kinni_10,
                              sum(summa11) FILTER (WHERE liik IN (2, 3, 4, 8, 70)) AS kinni_11,
                              sum(summa12) FILTER (WHERE liik IN (2, 3, 4, 8, 70)) AS kinni_12
                          FROM
                              preArv
                          GROUP BY lepingid
                      )
        SELECT
            preArv.lepingid,
            nimetus,
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
            sum(qryKokku.arv1)     AS arv_1,
            sum(qryKokku.arv2)     AS arv_2,
            sum(qryKokku.arv3)     AS arv_3,
            sum(qryKokku.arv4)     AS arv_4,
            sum(qryKokku.arv5)     AS arv_5,
            sum(qryKokku.arv6)     AS arv_6,
            sum(qryKokku.arv7)     AS arv_7,
            sum(qryKokku.arv8)     AS arv_8,
            sum(qryKokku.arv9)     AS arv_9,
            sum(qryKokku.arv10)    AS arv_10,
            sum(qryKokku.arv11)    AS arv_11,
            sum(qryKokku.arv12)    AS arv_12,
            sum(qryKokku.kinni_1)  AS kinni_1,
            sum(qryKokku.kinni_2)  AS kinni_2,
            sum(qryKokku.kinni_3)  AS kinni_3,
            sum(qryKokku.kinni_4)  AS kinni_4,
            sum(qryKokku.kinni_5)  AS kinni_5,
            sum(qryKokku.kinni_6)  AS kinni_6,
            sum(qryKokku.kinni_7)  AS kinni_7,
            sum(qryKokku.kinni_8)  AS kinni_8,
            sum(qryKokku.kinni_9)  AS kinni_9,
            sum(qryKokku.kinni_10) AS kinni_10,
            sum(qryKokku.kinni_11) AS kinni_11,
            sum(qryKokku.kinni_12) AS kinni_12,
            idx,
            liik
        FROM
            preArv
                LEFT OUTER JOIN qryKokku ON preArv.lepingid = qryKokku.lepingid
        GROUP BY preArv.lepingid, qryKokku.lepingid, nimetus, liik, idx
    )                                  po
        LEFT OUTER JOIN (
                            WITH
                                qryPuudumine AS (
                                                    -- собираем здесь данные о пропусках раб. места, сгруппированные по договорам , по месяцам
                                                    WITH
                                                        puudumised_paevad AS (
                                                                                 WITH
                                                                                     qryKuu AS (
                                                                                                   SELECT
                                                                                                       kuu,
                                                                                                       year(p.kpv_1) AS aasta,
                                                                                                       t.id          AS lepingid
                                                                                                   FROM
                                                                                                       unnest('{1,2,3,4,5,6,7,8,9,10,11,12}' :: INTEGER[]) AS kuu,
                                                                                                       palk.tooleping                                         t,
                                                                                                       params                                                 p
                                                                                                   WHERE
                                                                                                       t.rekvid = p.rekv_id
                                                                                                   ORDER BY lepingid, kuu, aasta
                                                                                               ),
                                                                                     qryKorPuudu AS (
                                                                                                   SELECT
                                                                                                       p.id                    AS p_id,
                                                                                                       q.alg_kpv,
                                                                                                       q.lopp_kpv,
                                                                                                       p.kpv1                  AS kpv_1,
                                                                                                       p.kpv2                  AS kpv_2,
                                                                                                       CASE
                                                                                                           WHEN p.kpv1 >= q.alg_kpv AND month(p.kpv1) = month(q.alg_kpv)
                                                                                                               THEN p.kpv1
                                                                                                           ELSE q.alg_kpv END  AS kpv1,
                                                                                                       CASE
                                                                                                           WHEN p.kpv2 <= q.lopp_kpv AND MONTH(p.kpv2) = MONTH(q.lopp_kpv)
                                                                                                               THEN p.kpv2
                                                                                                           ELSE q.lopp_kpv END AS kpv2,
                                                                                                       CASE
                                                                                                           WHEN month(p.kpv1) = month(p.kpv2)
                                                                                                               THEN p.paevad

                                                                                                           WHEN p.kpv1 >= q.alg_kpv AND MONTH(p.kpv1) = MONTH(q.alg_kpv)
                                                                                                               THEN palk.get_days_of_month_in_period(
                                                                                                                   kuu,
                                                                                                                   aasta,
                                                                                                                   p.kpv1,
                                                                                                                   (q.alg_kpv +
                                                                                                                    INTERVAL
                                                                                                                        '1 month')::DATE,
                                                                                                                   FALSE,
                                                                                                                   puudumiste_liik =
                                                                                                                   'PUHKUS')
                                                                                                           WHEN
                                                                                                               MONTH(p.kpv1) <
                                                                                                               MONTH(q.alg_kpv) AND
                                                                                                               MONTH(p.kpv2) =
                                                                                                               MONTH(q.lopp_kpv)
                                                                                                               THEN palk.get_days_of_month_in_period(
                                                                                                                   kuu,
                                                                                                                   aasta,
                                                                                                                   make_date(YEAR(q.lopp_kpv), MONTH(q.lopp_kpv), 1),
                                                                                                                   p.kpv2,
                                                                                                                   FALSE,
                                                                                                                   puudumiste_liik =
                                                                                                                   'PUHKUS')
                                                                                                           WHEN p.kpv1 > q.alg_kpv
                                                                                                               THEN 0
                                                                                                           ELSE palk.get_days_of_month_in_period(
                                                                                                                   kuu,
                                                                                                                   aasta,
                                                                                                                   make_date(YEAR(q.lopp_kpv), MONTH(q.lopp_kpv), 1),
                                                                                                                   q.lopp_kpv,
                                                                                                                   FALSE,
                                                                                                                   puudumiste_liik =
                                                                                                                   'PUHKUS')
                                                                                                           END                 AS paevad,

                                                                                                       p.puudumiste_liik,
                                                                                                       p.lepingid,
                                                                                                       p.tyyp,
                                                                                                       pt.kas_kehtiv,
                                                                                                       pt.vs_kooded,
                                                                                                       q.kuu,
                                                                                                       q.aasta
                                                                                                   FROM
                                                                                                       (
                                                                                                           SELECT
                                                                                                               kuu,
                                                                                                               aasta,
                                                                                                               make_date(aasta, qryKuu.kuu, 1) alg_kpv,
                                                                                                               ((make_date(aasta, qryKuu.kuu, 1) + INTERVAL '1 month')::DATE -
                                                                                                                1)::DATE AS                    lopp_kpv,
                                                                                                               lepingid
                                                                                                           FROM
                                                                                                               qryKuu
                                                                                                       )                                       q,
                                                                                                       palk.puudumine                          p
                                                                                                           inner join palk.com_puudumiste_tyyp pt
                                                                                                                      on pt.liik = p.puudumiste_liik and pt.id = p.tyyp,
                                                                                                       params                                  ps
                                                                                                   WHERE
                                                                                                         p.status <> 'deleted'
                                                                                                     AND q.alg_kpv >= ps.kpv_1
                                                                                                     AND q.lopp_kpv <= ps.kpv_2
                                                                                                     AND p.kpv1 >= ps.kpv_1
                                                                                                     AND p.kpv2 <= ps.kpv_2
                                                                                                     AND q.lepingid = p.lepingid
                                                                                                     AND q.kuu >= MONTH(p.kpv1)
                                                                                                     AND q.kuu <= MONTH(p.kpv2)
                                                                                               )
                                                                                 SELECT *
                                                                                 FROM
                                                                                     qryKorPuudu q
                                                        )
                                                    -- разбиваем дни по периодам
                                                    SELECT
                                                        lepingid,
                                                        CASE
                                                            WHEN kuu = 1
                                                                THEN paevad
                                                            ELSE 0 END AS paevad1,
                                                        CASE
                                                            WHEN kuu = 2
                                                                THEN paevad
                                                            ELSE 0 END AS paevad2,
                                                        CASE
                                                            WHEN kuu = 3
                                                                THEN paevad
                                                            ELSE 0 END AS paevad3,
                                                        CASE
                                                            WHEN kuu = 4
                                                                THEN paevad
                                                            ELSE 0 END AS paevad4,
                                                        CASE
                                                            WHEN kuu = 5
                                                                THEN paevad
                                                            ELSE 0 END AS paevad5,
                                                        CASE
                                                            WHEN kuu = 6
                                                                THEN paevad
                                                            ELSE 0 END AS paevad6,
                                                        CASE
                                                            WHEN kuu = 7
                                                                THEN paevad
                                                            ELSE 0 END AS paevad7,
                                                        CASE
                                                            WHEN kuu = 8
                                                                THEN paevad
                                                            ELSE 0 END AS paevad8,
                                                        CASE
                                                            WHEN kuu = 9
                                                                THEN paevad
                                                            ELSE 0 END AS paevad9,
                                                        CASE
                                                            WHEN kuu = 10
                                                                THEN paevad
                                                            ELSE 0 END AS paevad10,
                                                        CASE
                                                            WHEN kuu = 11
                                                                THEN paevad
                                                            ELSE 0 END AS paevad11,
                                                        CASE
                                                            WHEN kuu = 12
                                                                THEN paevad
                                                            ELSE 0 END AS paevad12,
                                                        puudumiste_liik,
                                                        tyyp,
                                                        qry.vs_kooded,
                                                        qry.kas_kehtiv
                                                    FROM
                                                        (
                                                            SELECT
                                                                p.kuu,
                                                                p.aasta,
                                                                p.paevad,
                                                                p.puudumiste_liik,
                                                                p.tyyp,
                                                                p.vs_kooded,
                                                                p.kas_kehtiv,
                                                                p.lepingid
                                                            FROM
                                                                puudumised_paevad             p
                                                                    INNER JOIN palk.tooleping t ON t.id = p.lepingid
                                                                    AND p.paevad > 0
--                     AND p.puudumiste_liik = 'PUHKUS'
                                                            WHERE
                                                                t.rekvid = l_rekvid
                                                        ) qry
                                                    WHERE
                                                          kuu >= month(l_kpv1)
                                                      AND kuu <= month(l_kpv2)
                                                      AND aasta = year(l_kpv1)
                                                    ORDER BY lepingid, kuu, aasta
                                )
                            -- выбираем больничные
                            SELECT
                                lepingid,
                                sum(paevad1)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] && qryPuudumine.vs_kooded) AS haig_1,
                                sum(paevad2)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_2,
                                sum(paevad3)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_3,
                                sum(paevad4)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_4,
                                sum(paevad5)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_5,
                                sum(paevad6)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_6,
                                sum(paevad7)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS' and
                                              array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                              qryPuudumine.vs_kooded)                                        AS haig_7,
                                sum(paevad8)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_8,
                                sum(paevad9)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_9,
                                sum(paevad10)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_10,
                                sum(paevad11)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_11,
                                sum(paevad12)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'HAIGUS'
                                    and array ['AH', 'H', 'HD', 'HL', 'HP', 'PH'] &&
                                        qryPuudumine.vs_kooded)                                              AS haig_12,
                                sum(paevad1)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
--                                                  AND tyyp = 1
                                    and array ['P'] && qryPuudumine.vs_kooded
                                    )                                                                        AS puhk1_1,
                                -- pohipuhkus
                                sum(paevad2)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    --AND tyyp = 1
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_2,
                                sum(paevad3)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_3,
                                sum(paevad4)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_4,
                                sum(paevad5)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_5,
                                sum(paevad6)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_6,
                                sum(paevad7)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_7,
                                sum(paevad8)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_8,
                                sum(paevad9)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_9,
                                sum(paevad10)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_10,
                                sum(paevad11)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_11,
                                sum(paevad12)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['P'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk1_12,
                                sum(paevad1)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    --AND tyyp = 2
                                    and array ['ÕP'] && qryPuudumine.vs_kooded
                                    )                                                                        AS puhk2_1,
                                -- Õppepuhkus
                                sum(paevad2)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_2,
                                sum(paevad3)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_3,
                                sum(paevad4)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_4,
                                sum(paevad5)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_5,
                                sum(paevad6)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_6,
                                sum(paevad7)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_7,
                                sum(paevad8)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_8,
                                sum(paevad9)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_9,
                                sum(paevad10)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_10,
                                sum(paevad11)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_11,
                                sum(paevad12)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['ÕP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk2_12,
                                -- Tasustamata puhkus
                                sum(paevad1)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    --AND tyyp = 3
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_1,
                                sum(paevad2)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_2,
                                sum(paevad3)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_3,
                                sum(paevad4)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_4,
                                sum(paevad5)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_5,
                                sum(paevad6)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_6,
                                sum(paevad7)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_7,
                                sum(paevad8)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_8,
                                sum(paevad9)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_9,
                                sum(paevad10)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_10,
                                sum(paevad11)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_11,
                                sum(paevad12)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['A','TP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk3_12,
                                -- Muud puhkused
                                sum(paevad1)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_1,
                                sum(paevad2)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_2,
                                -- oma arvelt
                                sum(paevad3)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_3,
                                sum(paevad4)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_4,
                                sum(paevad5)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_5,
                                sum(paevad6)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_6,
                                sum(paevad7)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_7,
                                sum(paevad8)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_8,
                                sum(paevad9)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_9,
                                sum(paevad10)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_10,
                                sum(paevad11)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_11,
                                sum(paevad12)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['AP', 'AT', 'IP', 'MTV', 'PIH', 'PL', 'S', 'TE', 'V', 'VK'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk4_12,
                                -- Sotsiaalsed puhkused
                                sum(paevad1)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_1,
                                sum(paevad2)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_2,
                                sum(paevad3)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_3,
                                sum(paevad4)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_4,
                                sum(paevad5)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_5,
                                sum(paevad6)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_6,
                                sum(paevad7)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_7,
                                sum(paevad8)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_8,
                                sum(paevad9)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_9,
                                sum(paevad10)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_10,
                                sum(paevad11)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_11,
                                sum(paevad12)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'PUHKUS'
                                    and array ['EMP', 'LHP', 'LP', 'PLP', 'VP', 'TLP'] &&
                                        qryPuudumine.vs_kooded)                                              AS puhk5_12,

                                -- Koolitus
                                sum(paevad1)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_1,
                                sum(paevad2)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_2,
                                sum(paevad3)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_3,
                                sum(paevad4)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_4,
                                sum(paevad5)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_5,
                                sum(paevad6)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_6,
                                sum(paevad7)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_7,
                                sum(paevad8)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_8,
                                sum(paevad9)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_9,
                                sum(paevad10)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_10,
                                sum(paevad11)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_11,
                                sum(paevad12)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'KOOLITUS'
                                    and array ['K'] && qryPuudumine.vs_kooded)                               AS kom_12,
                                -- Muud
                                sum(paevad1)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_1,
                                sum(paevad2)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_2,
                                sum(paevad3)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_3,
                                sum(paevad4)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_4,
                                sum(paevad5)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_5,
                                sum(paevad6)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_6,
                                sum(paevad7)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_7,
                                sum(paevad8)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_8,
                                sum(paevad9)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_9,
                                sum(paevad10)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_10,
                                sum(paevad11)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_11,
                                sum(paevad12)
                                FILTER (WHERE qryPuudumine.puudumiste_liik = 'MUU'
                                    and array ['STR', 'L', 'EKK', 'M'] && qryPuudumine.vs_kooded)            AS muu_12
                            FROM
                                qryPuudumine
                            GROUP BY lepingid
                        )              qryPuudu ON qryPuudu.lepingid = po.lepingid
        INNER JOIN      palk.tooleping t ON t.id = po.lepingid
        INNER JOIN      libs.asutus    a ON a.id = t.parentid
        INNER JOIN      libs.library   o ON t.osakondid = o.id
        INNER JOIN      libs.library   amet ON t.ametid = amet.id

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.palk_kaart_2025( DATE, DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.palk_kaart_2025( DATE, DATE, INTEGER, INTEGER ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.palk_kaart_2025( DATE, DATE, INTEGER, INTEGER ) TO dbkasutaja;


/*

SELECT *
FROM palk.palk_kaart_2025('2025-01-01', '2025-03-31',63, 0 :: INTEGER)
--where isik ilike '%Sepp Christi%'
*/