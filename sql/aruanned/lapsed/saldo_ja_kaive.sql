--DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);
DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.saldo_ja_kaive(l_rekvid INTEGER,
                                                 kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                                 kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        id              BIGINT,
        period          DATE,
        kulastatavus    TEXT,
        lapse_nimi      TEXT,
        lapse_isikukood TEXT,
        yksus           TEXT,
        viitenumber     TEXT,
        alg_saldo       NUMERIC(14, 4),
        arvestatud      NUMERIC(14, 4),
        soodustus       NUMERIC(14, 4),
        laekumised      NUMERIC(14, 4),
        tagastused      NUMERIC(14, 4),
        jaak            NUMERIC(14, 4),
        rekvid          INTEGER
    ) AS
$BODY$
WITH kulastavus AS (
    SELECT parentid,
           rekvid,
           min(alg_kpv)            AS alg_kpv,
           max(lopp_kpv)           AS lopp_kpv,
           CASE
               WHEN max(lopp_kpv) >= kpv_end OR min(alg_kpv) < kpv_start THEN 'Jah'
               ELSE 'Ei' END::TEXT AS kulastavus
    FROM (
             SELECT parentid,
                    rekvid,
                    coalesce(
                            (lk.properties ->> 'alg_kpv')::DATE,
                            date(year(current_date), 1, 1))::DATE   AS alg_kpv,
                    coalesce(
                            (lk.properties ->> 'lopp_kpv')::DATE,
                            date(year(current_date), 12, 31))::DATE AS lopp_kpv
             FROM lapsed.lapse_kaart lk
             WHERE lk.staatus <> 3
               AND lk.rekvid IN (SELECT rekv_id FROM get_asutuse_struktuur(l_rekvid))
         ) qry

    GROUP BY parentid,
             rekvid
)

SELECT count(*) OVER (PARTITION BY laps_id)                        AS id,
       kpv_start::DATE                                             AS period,
       CASE
           WHEN k.lopp_kpv >= kpv_end THEN 'Jah'
           ELSE 'Ei' END::TEXT                                     AS kulastatavus,
       l.nimi::TEXT                                                AS lapse_nimi,
       l.isikukood::TEXT                                           AS lapse_isikukood,
       yksus::TEXT,
       lapsed.get_viitenumber(report.rekvid, report.laps_id)::TEXT AS viitenumber,
       sum(coalesce(alg_saldo, 0))::NUMERIC(14, 4),
       sum(coalesce(arvestatud, 0))::NUMERIC(14, 4),
       sum(coalesce(soodustus, 0))::NUMERIC(14, 4),
       sum(coalesce(laekumised, 0))::NUMERIC(14, 4),
       sum(coalesce(-1 * tagastused, 0))::NUMERIC(14, 4),
       sum(coalesce(jaak, 0))::NUMERIC(14, 4),
       report.rekvid
FROM (
         WITH alg_saldo AS (
             -- alg_saldo
             SELECT kpv_start                                                     AS period,
                    coalesce(alg_saldo.yksus, '')::TEXT                           AS yksus,
                    coalesce(alg_saldo.jaak::NUMERIC(14, 4), 0) :: NUMERIC(14, 4) AS alg_saldo,
                    alg_saldo.rekv_id::INTEGER                                    AS rekvid,
                    l.id                                                          AS laps_id
             FROM lapsed.laps l
                      LEFT OUTER JOIN (SELECT coalesce(jaak, 0)                AS jaak,

                                              laps_id,
                                              rekv_id,
                                              yksus,
                                              lapsed.get_last_maksja(docs_ids) AS asutus_id
                                       FROM lapsed.lapse_saldod(kpv_start::DATE, NULL::INTEGER, l_rekvid, 1)) alg_saldo
                                      ON alg_saldo.laps_id = l.id
             WHERE alg_saldo.rekv_id IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
         ),
              laekumised AS (
                  SELECT a.rekvid,
                         a1.properties ->> 'yksus'                                                            AS yksus,
                         sum(((a1.summa / a.summa) * at.summa)) FILTER ( WHERE at.summa < 0 )::NUMERIC(14, 4) AS tagastus,
                         sum(((a1.summa / a.summa) * at.summa)) FILTER ( WHERE at.summa > 0 )::NUMERIC(14, 4) AS laekumised,
                         l.parentid                                                                           AS laps_id
                  FROM (SELECT doc_arv_id, sum(summa) summa
                        FROM docs.arvtasu
                        WHERE kpv >= kpv_start::DATE
                          AND kpv <= kpv_end::DATE
                        GROUP BY doc_arv_id
                       ) at
                           INNER JOIN docs.arv a ON at.doc_arv_id = a.parentid AND
                                                    (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                           INNER JOIN docs.doc d ON d.id = a.parentid AND d.status <> 3
                           INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                           INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                  WHERE a.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND a.liik = 0 -- только счета исходящие
                  GROUP BY at.doc_arv_id, (a1.properties ->> 'yksus'), at.summa, l.parentid, a.rekvid
              ),
              arvestatud AS (
                  SELECT ld.parentid                               AS laps_id,
                         coalesce(a1.yksus, '')::TEXT              AS yksus,
                         a1.summa ::NUMERIC(14, 4)                 AS arvestatud,
                         coalesce(a1.soodustus, 0)::NUMERIC(14, 2) AS soodustus,
                         d.rekvid::INTEGER                         AS rekvid
                  FROM docs.doc d
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                           INNER JOIN docs.arv a ON a.parentid = d.id AND a.liik = 0 -- только счета исходящие
                           INNER JOIN (SELECT a1.parentid                           AS arv_id,
                                              sum(
                                                          (coalesce((a1.properties ->> 'soodustus')::NUMERIC(14, 2), 0)) *
                                                          a1.kogus::NUMERIC(14, 2)) AS soodustus,
                                              (a1.properties ->> 'yksus')           AS yksus,
                                              sum(
                                                          (CASE
                                                               WHEN a1.summa > 0 AND
                                                                    coalesce((a1.properties ->> 'soodustus')::NUMERIC, 0) > 0
                                                                   THEN coalesce((a1.properties ->> 'soodustus')::NUMERIC, 0)
                                                               ELSE coalesce((a1.properties ->> 'soodustus')::NUMERIC, 0) END::NUMERIC +
                                                           CASE WHEN a1.summa = 0 THEN 0 ELSE a1.hind END) *
                                                          a1.kogus)                 AS summa
                                       FROM docs.arv1 a1
                                                INNER JOIN docs.arv a ON a.id = a1.parentid AND
                                                                         (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                                           AND a.liik = 0 -- только счета исходящие

                                                INNER JOIN docs.doc d ON d.id = a.parentid AND d.status <> 3
                                       GROUP BY a1.parentid, a1.properties ->> 'yksus') a1
                                      ON a1.arv_id = a.id AND
                                         (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                  WHERE coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                    AND d.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND a.liik = 0 -- только счета исходящие
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end),
              ettemaksud AS (
                  SELECT DISTINCT mk.id                                                                               AS doc_tasu_id,
                                  (CASE WHEN ymk.opt = 2 AND ymk.summa > 0 THEN ymk.summa ELSE 0 END)::NUMERIC(14, 4) AS laekumised,
                                  (CASE
                                       WHEN ymk.opt = 1 OR ymk.summa < 0
                                           THEN (CASE WHEN ymk.opt = 2 THEN -1 ELSE 1 END) * ymk.summa
                                       ELSE 0 END)::NUMERIC(14, 4)                                                    AS tagastused,
                                  ymk.yksus,
                                  ymk.laps_id,
                                  mk.rekvid
                  FROM lapsed.cur_lapsed_mk mk
                           INNER JOIN lapsed.get_group_part_from_mk(mk.id, kpv_start) ymk ON ymk.mk_id = mk.id

                  WHERE mk.rekvid IN (SELECT rekv_id
                                      FROM get_asutuse_struktuur(l_rekvid))
                    AND mk.maksepaev >= kpv_start
                    AND mk.maksepaev <= kpv_end
                    AND mk.jaak <> 0
              )

         SELECT yksus,
                (alg_saldo)               AS alg_saldo,
                (arvestatud)              AS arvestatud,
                (soodustus)               AS soodustus,
                (laekumised)              AS laekumised,
                (-1 * tagastused)         AS tagastused,
                (coalesce(alg_saldo, 0) + coalesce(arvestatud, 0) - coalesce(laekumised, 0) - coalesce(soodustus, 0) +
                 coalesce(tagastused, 0)) AS jaak,
                qry.rekvid,
                qry.laps_id
         FROM (
                  -- alg.saldo
                  SELECT a.yksus                  AS yksus,
                         coalesce(a.alg_saldo, 0) AS alg_saldo,
                         0                        AS arvestatud,
                         0                        AS soodustus,
                         0                        AS laekumised,
                         0                        AS tagastused,
                         0                        AS jaak,
                         a.rekvid                 AS rekvid,
                         a.laps_id
                  FROM alg_saldo a
                  UNION ALL
                  -- ettemaksud
                  SELECT a.yksus                   AS yksus,
                         0                         AS alg_saldo,
                         0                         AS arvestatud,
                         0                         AS soodustus,
                         coalesce(a.laekumised, 0) AS laekumised,
                         coalesce(a.tagastused, 0) AS tagastused,
                         0                         AS jaak,
                         a.rekvid                  AS rekvid,
                         a.laps_id
                  FROM ettemaksud a
                  UNION ALL
                  -- laekumised
                  SELECT a.yksus                   AS yksus,
                         0                         AS alg_saldo,
                         0                         AS arvestatud,
                         0                         AS soodustus,
                         coalesce(a.laekumised, 0) AS laekumised,
                         coalesce(a.tagastus, 0)   AS tagastused,
                         0                         AS jaak,
                         a.rekvid                  AS rekvid,
                         a.laps_id
                  FROM laekumised a
                  UNION ALL
                  -- kaibed
                  SELECT k.yksus                   AS yksus,
                         0                         AS alg_saldo,
                         COALESCE(k.arvestatud, 0) AS arvestatud,
                         COALESCE(k.soodustus, 0)  AS soodustus,
                         0                         AS laekumised,
                         0                         AS tagastused,
                         0                         AS jaak,
                         k.rekvid                  AS rekvid,
                         k.laps_id
                  FROM arvestatud k
              ) qry
     ) report
         LEFT OUTER JOIN kulastavus k ON k.parentid = report.laps_id AND k.rekvid = report.rekvid
         INNER JOIN lapsed.laps l ON l.id = report.laps_id

GROUP BY (CASE
              WHEN k.lopp_kpv >= kpv_end THEN 'Jah'
              ELSE 'Ei' END),
         l.nimi,
         l.isikukood,
         yksus,
         laps_id,
         report.rekvid

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaive(INTEGER, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaive(INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaive(INTEGER, DATE, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaive(INTEGER, DATE, DATE) TO dbvaatleja;


/*
select sum(arvestatud) from (

SELECT qry.jaak, qry1.alg_saldo, qry.lapse_isikukood, qry1.lapse_isikukood
FROM lapsed.saldo_ja_kaive(69, '2020-01-01', '2020-12-31') qry
left outer join  lapsed.saldo_ja_kaive(84, '2021-01-01', '2021-01-31') qry1
on qry1.lapse_isikukood =  qry.lapse_isikukood
where qry.jaak <> qry1.alg_saldo


where lapse_isikukood in ('51608190242')
inner join (select sum()
where qry.laekumised > 0


) qry
where  is   IN ('0850136823')

*/
