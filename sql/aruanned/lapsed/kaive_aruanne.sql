--DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);
DROP FUNCTION IF EXISTS lapsed.kaive_aruanne(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.kaive_aruanne(l_rekvid INTEGER,
                                                kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                                kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        id              BIGINT,
        period          DATE,
        kulastatavus    TEXT,
        lapse_nimi      TEXT,
        lapse_isikukood TEXT,
        viitenumber     TEXT,
        alg_saldo       NUMERIC(14, 4),
        arvestatud      NUMERIC(14, 4),
        soodustus       NUMERIC(14, 4),
        laekumised      NUMERIC(14, 4),
        mahakantud      NUMERIC(14, 4),
        tagastused      NUMERIC(14, 4),
        jaak            NUMERIC(14, 4),
        rekvid          INTEGER
    )
AS
$BODY$
WITH kulastavus AS (
    SELECT laps_id,
           rekv_id,
           min(alg_kpv)            AS alg_kpv,
           max(lopp_kpv)           AS lopp_kpv,
           CASE
               WHEN max(lopp_kpv) >= kpv_end OR min(alg_kpv) < kpv_start THEN 'Jah'
               ELSE 'Ei' END::TEXT AS kulastavus
    FROM (
             SELECT parentid                                        AS laps_id,
                    rekvid                                          AS rekv_id,
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

    GROUP BY laps_id,
             rekv_id
)

SELECT count(*) OVER (PARTITION BY report.laps_id)                  AS id,
       kpv_start::DATE                                              AS period,
       CASE
           WHEN k.lopp_kpv >= kpv_end THEN 'Jah'
           ELSE 'Ei' END::TEXT                                      AS kulastatavus,
       l.nimi::TEXT                                                 AS lapse_nimi,
       l.isikukood::TEXT                                            AS lapse_isikukood,
       lapsed.get_viitenumber(report.rekv_id, report.laps_id)::TEXT AS viitenumber,
       alg_saldo::NUMERIC(14, 4),
       arvestatud::NUMERIC(14, 4),
       soodustus::NUMERIC(14, 4),
       laekumised::NUMERIC(14, 4),
       mahakantud::NUMERIC(14, 4),
       tagastused::NUMERIC(14, 4),
       (alg_saldo + arvestatud - soodustus - laekumised - mahakantud + tagastused)::NUMERIC(14, 4),
       report.rekv_id
FROM (
         WITH alg_saldo AS (
             SELECT laps_id, rekv_id, sum(summa) AS jaak
             FROM (
                      -- laekumised
                      SELECT -1 * (CASE WHEN mk.opt = 2 THEN 1 ELSE -1 END) * mk1.summa AS summa,
                             l.id                                                       AS laps_id,
                             d.rekvid                                                   AS rekv_id
                      FROM docs.doc d
                               INNER JOIN docs.Mk mk ON mk.parentid = d.id
                               INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                               INNER JOIN lapsed.laps l ON l.id = ld.parentid

                      WHERE d.status <> 3
                        AND d.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
                        AND mk.maksepaev < kpv_start
                      UNION ALL
                      SELECT a.summa     AS summa,
                             ld.parentid AS laps_id,
                             d.rekvid    AS rekv_id
                      FROM docs.doc d
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                               INNER JOIN docs.arv a ON a.parentid = d.id AND a.liik = 0 -- только счета исходящие
                      WHERE coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                        AND d.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
                        AND a.liik = 0 -- только счета исходящие
                        AND a.kpv < kpv_start
-- mahakandmine
                      UNION ALL
                      SELECT -1 * a.summa AS summa,
                             l.parentid   AS laps_id,
                             a.rekvid     AS rekv_id
                      FROM docs.arvtasu a
                               INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                               INNER JOIN docs.arv arv ON a.doc_arv_id = arv.parentid

                      WHERE a.pankkassa = 3 -- только проводки
                        AND a.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
                        AND a.kpv < kpv_start
                        AND a.status <> 3
                        AND (arv.properties ->> 'tyyp' IS NULL OR
                             arv.properties ->> 'tyyp' <> 'ETTEMAKS') -- уберем предоплаты

                  ) alg_saldo
             GROUP BY laps_id, rekv_id
         ),
              mahakandmine AS (
                  SELECT sum(a.summa) AS summa,
                         l.parentid   AS laps_id,
                         a.rekvid     AS rekv_id
                  FROM docs.arvtasu a
                           INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                           INNER JOIN docs.arv arv ON a.doc_arv_id = arv.parentid
                  WHERE a.status <> 3
                    AND a.pankkassa = 3
                    AND a.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
                    AND (arv.properties ->> 'tyyp' IS NULL OR
                         arv.properties ->> 'tyyp' <> 'ETTEMAKS') -- уберем предоплаты
                  GROUP BY l.parentid, a.rekvid
              ),

              laekumised AS (
                  SELECT sum(mk1.summa) AS summa,
                         l.id           AS laps_id,
                         d.rekvid       AS rekv_id
                  FROM docs.doc d
                           INNER JOIN docs.Mk mk ON mk.parentid = d.id
                           INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                           INNER JOIN lapsed.laps l ON l.id = ld.parentid
                  WHERE d.status <> 3
                    AND mk.opt = 2
                    AND mk1.summa > 0
                    AND d.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND mk.maksepaev >= kpv_start
                    AND mk.maksepaev <= kpv_end
                  GROUP BY l.id, d.rekvid
              ),
              tagastused AS (
                  SELECT sum(CASE WHEN mk.opt = 2 THEN -1 ELSE 1 END * mk1.summa) AS summa,
                         l.id                                                     AS laps_id,
                         d.rekvid                                                 AS rekv_id
                  FROM docs.doc d
                           INNER JOIN docs.Mk mk ON mk.parentid = d.id
                           INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                           INNER JOIN lapsed.laps l ON l.id = ld.parentid
                  WHERE d.status <> 3
                    AND (mk.opt = 1 OR (mk.opt = 2 AND mk1.summa < 0))
                    AND d.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND mk.maksepaev >= kpv_start
                    AND mk.maksepaev <= kpv_end
                  GROUP BY l.id, d.rekvid
              ),

              arvestatud AS (
                  SELECT ld.parentid                                    AS laps_id,
                         sum(a1.summa) ::NUMERIC(14, 4)                 AS arvestatud,
                         sum(COALESCE(a1.soodustus, 0))::NUMERIC(14, 2) AS soodustus,
                         D.rekvid::INTEGER                              AS rekv_id
                  FROM docs.doc D
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                           INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                           INNER JOIN (SELECT a1.parentid                           AS arv_id,
                                              sum(
                                                          (COALESCE((a1.properties ->> 'soodustus')::NUMERIC(14, 2), 0)) *
                                                          a1.kogus::NUMERIC(14, 2)) AS soodustus,
                                              sum(
                                                          (CASE
                                                               WHEN a1.summa > 0 AND
                                                                    COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) > 0
                                                                   THEN COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0)
                                                               ELSE COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) END::NUMERIC +
                                                           CASE WHEN a1.summa = 0 THEN 0 ELSE a1.hind END) *
                                                          a1.kogus)                 AS summa
                                       FROM docs.arv1 a1
                                                INNER JOIN docs.arv a ON a.id = a1.parentid AND
                                                                         (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                                           AND a.liik = 0 -- только счета исходящие

                                                INNER JOIN docs.doc D ON D.id = a.parentid AND D.status <> 3
                                       GROUP BY a1.parentid) a1
                                      ON a1.arv_id = a.id
                  WHERE COALESCE((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                    AND D.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND a.liik = 0 -- только счета исходящие
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
                  GROUP BY ld.parentid, D.rekvid
              )
         SELECT sum(alg_saldo)  AS alg_saldo,
                sum(arvestatud) AS arvestatud,
                sum(soodustus)  AS soodustus,
                sum(laekumised) AS laekumised,
                sum(mahakantud) AS mahakantud,
                sum(tagastused) AS tagastused,
                qry.rekv_id,
                qry.laps_id
         FROM (
                  -- alg.saldo
                  SELECT a.jaak    AS alg_saldo,
                         0         AS arvestatud,
                         0         AS soodustus,
                         0         AS laekumised,
                         0         AS mahakantud,
                         0         AS tagastused,
                         a.rekv_id AS rekv_id,
                         a.laps_id
                  FROM alg_saldo a
                  UNION ALL
                  -- laekumised
                  SELECT 0         AS alg_saldo,
                         0         AS arvestatud,
                         0         AS soodustus,
                         l.summa   AS laekumised,
                         0         AS mahakantud,
                         0         AS tagastused,
                         l.rekv_id AS rekv_id,
                         l.laps_id
                  FROM laekumised l
                  UNION ALL
                  -- mahakandmine
                  SELECT 0         AS alg_saldo,
                         0         AS arvestatud,
                         0         AS soodustus,
                         0         AS laekumised,
                         l.summa   AS mahakantud,
                         0         AS tagastused,
                         l.rekv_id AS rekv_id,
                         l.laps_id
                  FROM mahakandmine l
                  UNION ALL
                  -- tagastused
                  SELECT 0                    AS alg_saldo,
                         0                    AS arvestatud,
                         0                    AS soodustus,
                         0                    AS laekumised,
                         0                    AS mahakantud,
                         coalesce(t.summa, 0) AS tagastused,
                         t.rekv_id            AS rekv_id,
                         t.laps_id
                  FROM tagastused t
                  UNION ALL
                  -- arvestused
                  SELECT 0            AS alg_saldo,
                         k.arvestatud AS arvestatud,
                         k.soodustus  AS soodustus,
                         0            AS laekumised,
                         0            AS mahakantud,
                         0            AS tagastused,
                         k.rekv_id    AS rekv_id,
                         k.laps_id
                  FROM arvestatud k
              ) qry
         GROUP BY laps_id, rekv_id
     ) report
         INNER JOIN lapsed.laps l ON report.laps_id = l.id
         LEFT OUTER JOIN kulastavus k ON k.laps_id = report.laps_id AND k.rekv_id = report.rekv_id

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.kaive_aruanne(INTEGER, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kaive_aruanne(INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kaive_aruanne(INTEGER, DATE, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.kaive_aruanne(INTEGER, DATE, DATE) TO dbvaatleja;


/*
explain
select *
FROM lapsed.kaive_aruanne(96, '2021-01-01', '2021-12-30') qry
where lapse_nimi ilike 'Gruntova Arina%'
*/
