--DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);
DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.saldo_ja_kaibeandmik(l_rekvid INTEGER,
                                                       kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                                       kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        id         BIGINT,
        period     DATE,
        asutus     TEXT,
        alg_db     NUMERIC(14, 4),
        alg_kr     NUMERIC(14, 4),
        db         NUMERIC(14, 4),
        kr         NUMERIC(14, 4),
        mahakantud NUMERIC(14, 4),
        lopp_db    NUMERIC(14, 4),
        lopp_kr    NUMERIC(14, 4),
        rekvid     INTEGER
    )
AS
$BODY$

SELECT count(*) OVER (PARTITION BY report.rekv_id) AS id,
       kpv_start::DATE                             AS period,
       r.nimetus                                   AS asutus,
       alg_db::NUMERIC(14, 4),
       alg_kr::NUMERIC(14, 4),
       db::NUMERIC(14, 4),
       kr::NUMERIC(14, 4),
       mahakantud::NUMERIC(14, 4),
       lopp_db ::NUMERIC(14, 4)                    AS lopp_db,
       lopp_kr::NUMERIC(14, 4),
       report.rekv_id
FROM (
         WITH alg_saldo AS (
/*             SELECT rekv_id, sum(alg_db)::NUMERIC(14, 4) AS alg_db, sum(alg_kr)::NUMERIC(14, 4) AS alg_kr
             FROM (
                      SELECT sum(a.summa)      AS alg_db,
                             0::NUMERIC(14, 4) AS alg_kr,
                             d.rekvid          AS rekv_id
                      FROM docs.doc d
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                               INNER JOIN docs.arv a ON a.parentid = d.id AND a.liik = 0 -- только счета исходящие
                      WHERE coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                        AND d.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
                        AND a.liik = 0 -- только счета исходящие
                        AND a.kpv < kpv_start
                        AND d.status <> 3
                      GROUP BY d.rekvid, 0::NUMERIC(14, 4)
                      UNION ALL
-- arve tasumine
                      SELECT -1 * sum(at.summa) AS alg_db,
                             0                  AS alg_kr,
                             at.rekvid          AS _rekv_id
                      FROM docs.arvtasu at
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = at.doc_arv_id
                               INNER JOIN docs.arv arv ON arv.parentid = at.doc_arv_id
                               INNER JOIN docs.doc d ON d.id = at.doc_arv_id
                      WHERE at.kpv < kpv_start
                        AND arv.kpv < kpv_start
                        AND at.rekvid IN (SELECT rekv_id
                                          FROM get_asutuse_struktuur(l_rekvid))
                        AND d.status <> 3

                      GROUP BY _rekv_id
                      UNION ALL
-- чистые платежи (без счетов)
                      SELECT 0::NUMERIC(14, 4) AS alg_db,
                             sum(mk1.summa)    AS alg_kr,
                             d.rekvid          AS rekv_id
                      FROM docs.doc d
                               INNER JOIN docs.Mk mk ON mk.parentid = d.id
                               INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                               INNER JOIN lapsed.laps l ON l.id = ld.parentid
                      WHERE d.status <> 3
                        AND d.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
                        AND mk.maksepaev < kpv_start
                        AND mk.opt = 2
                      GROUP BY d.rekvid
                      UNION ALL
-- минусуем оплаты
                      SELECT 0                  AS alg_db,
                             -1 * sum(at.summa) AS alg_kr,
                             at.rekvid          AS _rekv_id
                      FROM docs.arvtasu at
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = at.doc_tasu_id
                               INNER JOIN docs.doc d ON d.id = at.doc_tasu_id
                               INNER JOIN docs.arv arv ON arv.parentid = at.doc_arv_id
                      WHERE at.kpv < kpv_start
                        AND arv.kpv < kpv_start
                        AND at.rekvid IN (SELECT rekv_id
                                          FROM get_asutuse_struktuur(l_rekvid))
                        AND at.pankkassa = 1
                        AND d.status <> 3

                      GROUP BY at.rekvid) alg
             GROUP BY rekv_id
*/
             SELECT rekv_id, sum(db) AS alg_db, sum(kr) AS alg_kr
             FROM (
                      -- laekumised
                      SELECT 0                                     AS db,
                             (mk.deebet - coalesce(laek.summa, 0)) AS kr,
                             mk.rekvid                             AS rekv_id
                      FROM lapsed.cur_lapsed_mk mk
                               LEFT OUTER JOIN (SELECT sum(summa) summa, at.doc_tasu_id
                                                FROM docs.arvtasu at
                                                WHERE at.status < 3
                                                  AND at.kpv < kpv_start
                                                  AND AT.pankkassa <> 3 -- списания отдельно
                                                  AND at.doc_arv_id NOT IN (SELECT a.parentid
                                                                            FROM docs.arv a
                                                                            WHERE a.rekvid IN (SELECT rekv_id
                                                                                               FROM get_asutuse_struktuur(l_rekvid))
                                                                              AND a.properties ->> 'tyyp' IS NOT NULL
                                                                              AND a.properties ->> 'tyyp' = 'ETTEMAKS'
                                                )
                                                GROUP BY doc_tasu_id) laek
                                               ON laek.doc_tasu_id = mk.id
                      WHERE mk.rekvid IN (SELECT rekv_id
                                          FROM get_asutuse_struktuur(l_rekvid))
                        AND mk.maksepaev < kpv_start
                        AND mk.opt = 2
                      UNION ALL
                      -- tagastused
                      SELECT 0                                           AS db,
                             -1 * (mk.kreedit - coalesce(laek.summa, 0)) AS kr,
                             mk.rekvid                                   AS rekv_id
                      FROM lapsed.cur_lapsed_mk mk
                               LEFT OUTER JOIN (SELECT sum(summa) summa, at.doc_tasu_id
                                                FROM docs.arvtasu at
                                                WHERE at.status < 3
                                                  AND at.kpv < kpv_start
                                                  AND AT.pankkassa <> 3 -- списания отдельно
                                                  AND at.doc_arv_id NOT IN (SELECT a.parentid
                                                                            FROM docs.arv a
                                                                            WHERE a.rekvid IN (SELECT rekv_id
                                                                                               FROM get_asutuse_struktuur(l_rekvid))
                                                                              AND a.properties ->> 'tyyp' IS NOT NULL
                                                                              AND a.properties ->> 'tyyp' = 'ETTEMAKS'
                                                )
                                                GROUP BY doc_tasu_id) laek
                                               ON laek.doc_tasu_id = mk.id
                      WHERE mk.rekvid IN (SELECT rekv_id
                                          FROM get_asutuse_struktuur(l_rekvid))
                        AND mk.maksepaev < kpv_start
                        AND mk.opt = 1
                      UNION ALL
                      SELECT (a.summa - coalesce(laek.summa, 0)) AS db,
                             0                                   AS kr,
                             d.rekvid                            AS rekv_id
                      FROM docs.doc d
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                               INNER JOIN docs.arv a ON a.parentid = d.id AND a.liik = 0 -- только счета исходящие
                               LEFT OUTER JOIN (SELECT sum(summa) summa, doc_arv_id
                                                FROM docs.arvtasu at
                                                WHERE at.status < 3
                                                  AND at.kpv < kpv_start
                                                  AND AT.pankkassa <> 3 -- списания отдельно
                                                GROUP BY doc_arv_id) laek
                                               ON laek.doc_arv_id = d.id
                      WHERE coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                        AND d.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
                        AND a.liik = 0 -- только счета исходящие
                        AND a.kpv < kpv_start
                        AND d.status < 3
-- mahakandmine
                      UNION ALL
                      SELECT -1 * a.summa AS db,
                             0            AS kr,
                             a.rekvid     AS rekv_id
                      FROM docs.arvtasu a
                               INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                               INNER JOIN docs.arv arv ON a.doc_arv_id = arv.parentid

                      WHERE a.pankkassa = 3 -- только проводки
                        AND a.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
                        AND a.kpv < kpv_start
                        AND arv.liik = 0
                        AND a.status <> 3
                        AND (arv.properties ->> 'tyyp' IS NULL OR
                             arv.properties ->> 'tyyp' <> 'ETTEMAKS') -- уберем предоплаты

                  ) alg_saldo
             GROUP BY rekv_id
         ),
              lopp_saldo AS (
                  SELECT rekv_id, sum(db) AS lopp_db, sum(kr) AS lopp_kr
                  FROM (
                           -- laekumised
                           SELECT 0                                     AS db,
                                  (mk.deebet - coalesce(laek.summa, 0)) AS kr,
                                  mk.rekvid                             AS rekv_id
                           FROM lapsed.cur_lapsed_mk mk
                                    LEFT OUTER JOIN (SELECT sum(summa) summa, at.doc_tasu_id
                                                     FROM docs.arvtasu at
                                                     WHERE at.status < 3
                                                       AND at.kpv <= kpv_end
                                                       AND AT.pankkassa <> 3 -- списания отдельно
                                                       AND at.doc_arv_id NOT IN (SELECT a.parentid
                                                                                 FROM docs.arv a
                                                                                 WHERE a.rekvid IN (SELECT rekv_id
                                                                                                    FROM get_asutuse_struktuur(l_rekvid))
                                                                                   AND a.properties ->> 'tyyp' IS NOT NULL
                                                                                   AND a.properties ->> 'tyyp' = 'ETTEMAKS'
                                                     )
                                                     GROUP BY doc_tasu_id) laek
                                                    ON laek.doc_tasu_id = mk.id
                           WHERE mk.rekvid IN (SELECT rekv_id
                                               FROM get_asutuse_struktuur(l_rekvid))
                             AND mk.maksepaev <= kpv_end
                             AND mk.opt = 2
                           UNION ALL
                           -- tagastused
                           SELECT 0                                           AS db,
                                  -1 * (mk.kreedit - coalesce(laek.summa, 0)) AS kr,
                                  mk.rekvid                                   AS rekv_id
                           FROM lapsed.cur_lapsed_mk mk
                                    LEFT OUTER JOIN (SELECT sum(summa) summa, at.doc_tasu_id
                                                     FROM docs.arvtasu at
                                                     WHERE at.status < 3
                                                       AND at.kpv <= kpv_end
                                                       AND AT.pankkassa <> 3 -- списания отдельно
                                                       AND at.doc_arv_id NOT IN (SELECT a.parentid
                                                                                 FROM docs.arv a
                                                                                 WHERE a.rekvid IN (SELECT rekv_id
                                                                                                    FROM get_asutuse_struktuur(l_rekvid))
                                                                                   AND a.properties ->> 'tyyp' IS NOT NULL
                                                                                   AND a.properties ->> 'tyyp' = 'ETTEMAKS'
                                                     )
                                                     GROUP BY doc_tasu_id) laek
                                                    ON laek.doc_tasu_id = mk.id
                           WHERE mk.rekvid IN (SELECT rekv_id
                                               FROM get_asutuse_struktuur(l_rekvid))
                             AND mk.maksepaev <= kpv_end
                             AND mk.opt = 1
                           UNION ALL
                           SELECT (a.summa - coalesce(laek.summa, 0)) AS db,
                                  0                                   AS kr,
                                  d.rekvid                            AS rekv_id
                           FROM docs.doc d
                                    INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                                    INNER JOIN docs.arv a ON a.parentid = d.id AND a.liik = 0 -- только счета исходящие
                                    LEFT OUTER JOIN (SELECT sum(summa) summa, doc_arv_id
                                                     FROM docs.arvtasu at
                                                     WHERE at.status < 3
                                                       AND at.kpv <= kpv_end
                                                       AND AT.pankkassa <> 3 -- списания отдельно
                                                     GROUP BY doc_arv_id) laek
                                                    ON laek.doc_arv_id = d.id
                           WHERE coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                             AND d.rekvid IN (SELECT rekv_id
                                              FROM get_asutuse_struktuur(l_rekvid))
                             AND a.liik = 0 -- только счета исходящие
                             AND a.kpv <= kpv_end
                             AND d.status < 3
-- mahakandmine
                           UNION ALL
                           SELECT -1 * a.summa AS db,
                                  0            AS kr,
                                  a.rekvid     AS rekv_id
                           FROM docs.arvtasu a
                                    INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                                    INNER JOIN docs.arv arv ON a.doc_arv_id = arv.parentid

                           WHERE a.pankkassa = 3 -- только проводки
                             AND a.rekvid IN (SELECT rekv_id
                                              FROM get_asutuse_struktuur(l_rekvid))
                             AND a.kpv <= kpv_end
                             AND arv.liik = 0
                             AND a.status <> 3
                             AND (arv.properties ->> 'tyyp' IS NULL OR
                                  arv.properties ->> 'tyyp' <> 'ETTEMAKS') -- уберем предоплаты

                       ) alg_saldo
                  GROUP BY rekv_id
              ),

              mahakandmine AS (
                  SELECT sum(a.summa) AS summa,
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
                  GROUP BY a.rekvid
              ),

              laekumised AS (
                  SELECT sum(CASE WHEN mk.opt = 2 THEN 1 ELSE -1 END * mk1.summa) AS summa,
                         d.rekvid                                                 AS rekv_id
                  FROM docs.doc d
                           INNER JOIN docs.Mk mk ON mk.parentid = d.id
                           INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                  WHERE d.status <> 3
                    AND d.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND mk.maksepaev >= kpv_start
                    AND mk.maksepaev <= kpv_end
                  GROUP BY d.rekvid
              ),

              arvestatud AS (
                  SELECT sum(a.summa) ::NUMERIC(14, 4) AS arvestatud,
                         D.rekvid::INTEGER             AS rekv_id
                  FROM docs.doc D
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                           INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                           INNER JOIN (SELECT a1.parentid                 AS arv_id,
                                              sum(
                                                      round((CASE
                                                                 WHEN a1.summa > 0 AND
                                                                      COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) > 0
                                                                     THEN COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0)
                                                                 ELSE COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) END::NUMERIC +
                                                             CASE WHEN a1.summa = 0 THEN 0 ELSE a1.hind END) *
                                                            a1.kogus, 2)) +
                                              lapsed.get_differ_from_algoritm(a1.hind, (CASE
                                                                                   WHEN a1.summa > 0 AND
                                                                                        COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) > 0
                                                                                       THEN COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0)
                                                                                   ELSE COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) END::NUMERIC +
                                                                               CASE WHEN a1.summa = 0 THEN 0 ELSE a1.hind END),  a1.kogus)

                                                  AS summa
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
         SELECT sum(alg_db)     AS alg_db,
                sum(alg_kr)     AS alg_kr,
                sum(db)         AS db,
                sum(kr)         AS kr,
                sum(mahakantud) AS mahakantud,
                sum(lopp_db)    AS lopp_db,
                sum(lopp_kr)    AS lopp_kr,
                qry.rekv_id
         FROM (
                  -- alg.saldo
                  SELECT a.alg_db  AS alg_db,
                         a.alg_kr  AS alg_kr,
                         0         AS db,
                         0         AS kr,
                         0         AS mahakantud,
                         0         AS lopp_db,
                         0         AS lopp_kr,
                         a.rekv_id AS rekv_id
                  FROM alg_saldo a
                  UNION ALL
                  -- laekumised
                  SELECT 0         AS alg_db,
                         0         AS alg_kr,
                         0         AS db,
                         l.summa   AS kr,
                         0         AS mahakantud,
                         0         AS lopp_db,
                         0         AS lopp_kr,
                         l.rekv_id AS rekv_id
                  FROM laekumised l
                  UNION ALL
                  -- mahakandmine
                  SELECT 0         AS alg_db,
                         0         AS alg_kr,
                         0         AS db,
                         0         AS kr,
                         l.summa   AS mahakantud,
                         0         AS lopp_db,
                         0         AS lopp_kr,
                         l.rekv_id AS rekv_id
                  FROM mahakandmine l
                  UNION ALL
                  -- arvestused
                  SELECT 0            AS alg_db,
                         0            AS alg_kr,
                         k.arvestatud AS db,
                         0            AS kr,
                         0            AS mahakantud,
                         0            AS lopp_db,
                         0            AS lopp_kr,
                         k.rekv_id    AS rekv_id
                  FROM arvestatud k
                       -- lopp saldo
                  UNION ALL
                  SELECT 0       AS alg_db,
                         0       AS alg_kr,
                         0       AS db,
                         0       AS kr,
                         0       AS mahakantud,
                         lopp_db AS lopp_db,
                         lopp_kr AS lopp_kr,
                         rekv_id AS rekv_id
                  FROM lopp_saldo
              ) qry
         GROUP BY rekv_id
     ) report
         INNER JOIN ou.rekv r ON r.id = report.rekv_id

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE) TO dbvaatleja;

/*
explain
select *
FROM lapsed.saldo_ja_kaibeandmik(119, '2021-01-01', '2021-01-31') qry
*/
