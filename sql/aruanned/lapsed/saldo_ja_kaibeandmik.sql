--DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);
DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.saldo_ja_kaibeandmik(l_rekvid INTEGER,
                                                       kpv_start DATE DEFAULT make_date(date_part('year', current_date)::INTEGER, 1, 1),
                                                       kpv_end DATE DEFAULT current_date,
                                                       l_isik_id INTEGER DEFAULT NULL)
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
        rekvid     INTEGER,
        isik_id    INTEGER
    )
AS
$BODY$
WITH rekv_ids AS (
    SELECT rekv_id
    FROM public.get_asutuse_struktuur(l_rekvid)
),
     docs_types AS (
         SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('SMK', 'VMK', 'ARV')
     )
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
       report.rekv_id,
       report.isik_id
FROM (
         WITH alg_saldo AS (
             SELECT rekv_id, sum(db) AS alg_db, sum(kr) AS alg_kr, isik_id
             FROM (
                      -- laekumised
                      SELECT 0          AS db,
                             mk1.summa  AS kr,
                             mk.rekvid  AS rekv_id,
                             l.parentid AS isik_id
                      FROM docs.doc d
                               INNER JOIN docs.mk mk ON d.id = mk.parentid
                               INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
                               INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                      WHERE d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                        AND d.status < 3
                        AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood <> 'ARV')
                        AND mk.maksepaev < kpv_start
                        AND mk.opt = 2
                        AND (l_isik_id IS NULL OR l.parentid = l_isik_id)
                      UNION ALL
                      -- tagastused
                      SELECT 0              AS db
                              ,
                             -1 * mk1.summa AS kr
                              ,
                             mk.rekvid      AS rekv_id,
                             l.parentid     AS isik_id
                      FROM docs.doc d
                               INNER JOIN docs.mk mk ON d.id = mk.parentid
                               INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
                               INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                      WHERE d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                        AND d.status < 3
                        AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood <> 'ARV')
                        AND mk.maksepaev < kpv_start
                        AND mk.opt = 1
                        AND (l_isik_id IS NULL OR l.parentid = l_isik_id)
                      UNION ALL
                      SELECT a.summa     AS db,
                             0           AS kr,
                             d.rekvid    AS rekv_id,
                             ld.parentid AS isik_id
                      FROM docs.doc d
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                               INNER JOIN docs.arv a ON a.parentid = d.id AND a.liik = 0 -- только счета исходящие
                      WHERE coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                        AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                        AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                        AND a.liik = 0 -- только счета исходящие
                        AND a.kpv < kpv_start
                        AND d.status < 3
                        AND (l_isik_id IS NULL OR ld.parentid = l_isik_id)

-- mahakandmine
                      UNION ALL
                      SELECT -1 * a.summa AS db,
                             0            AS kr,
                             a.rekvid     AS rekv_id,
                             l.parentid   AS isik_id
                      FROM docs.arvtasu a
                               INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                               INNER JOIN docs.arv arv ON a.doc_arv_id = arv.parentid
                      WHERE a.pankkassa = 3                           -- только проводки
                        AND a.rekvid IN (SELECT rekv_id FROM rekv_ids)
                        AND a.kpv < kpv_start
                        AND arv.liik = 0
                        AND a.status <> 3
                        AND (arv.properties ->> 'tyyp' IS NULL OR
                             arv.properties ->> 'tyyp' <> 'ETTEMAKS') -- уберем предоплаты
                        AND (l_isik_id IS NULL OR l.parentid = l_isik_id)
                  ) alg_saldo
             GROUP BY rekv_id, isik_id
         ),
              mahakandmine AS (
                  SELECT sum(a.summa) AS summa,
                         a.rekvid     AS rekv_id,
                         l.parentid   AS isik_id
                  FROM docs.arvtasu a
                           INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                           INNER JOIN docs.arv arv ON a.doc_arv_id = arv.parentid
                  WHERE a.status <> 3
                    AND a.pankkassa = 3
                    AND a.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
                    AND (arv.properties ->> 'tyyp' IS NULL OR
                         arv.properties ->> 'tyyp' <> 'ETTEMAKS') -- уберем предоплаты
                    AND (l_isik_id IS NULL OR l.parentid = l_isik_id)

                  GROUP BY a.rekvid, l.parentid
              ),

              laekumised AS (
                  SELECT sum(CASE WHEN mk.opt = 2 THEN 1 ELSE -1 END * mk1.summa) AS summa,
                         d.rekvid                                                 AS rekv_id,
                         ld.parentid                                              AS isik_id
                  FROM docs.doc d
                           INNER JOIN docs.Mk mk ON mk.parentid = d.id
                           INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                  WHERE d.status <> 3
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood <> 'ARV')
                    AND mk.maksepaev >= kpv_start
                    AND mk.maksepaev <= kpv_end
                    AND (l_isik_id IS NULL OR ld.parentid = l_isik_id)

                  GROUP BY d.rekvid, ld.parentid
              ),

              arvestatud AS (
                  SELECT sum(a.summa) ::NUMERIC(14, 4) AS arvestatud,
                         D.rekvid::INTEGER             AS rekv_id,
                         ld.parentid                   AS isik_id
                  FROM docs.doc D
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                           INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                           INNER JOIN (SELECT a1.parentid   AS arv_id,
                                              sum(COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) +
                                                  a1.summa) AS summa
                                       FROM docs.arv1 a1
                                                INNER JOIN docs.arv a ON a.id = a1.parentid AND
                                                                         (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                                           AND a.liik = 0 -- только счета исходящие

                                                INNER JOIN docs.doc D ON D.id = a.parentid AND D.status <> 3
                                       GROUP BY a1.parentid) a1
                                      ON a1.arv_id = a.id
                  WHERE COALESCE((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                    AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND a.liik = 0 -- только счета исходящие
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
                    AND (l_isik_id IS NULL OR ld.parentid = l_isik_id)

                  GROUP BY ld.parentid
                          , D.rekvid
              ),
              lopp_saldo AS (
                  SELECT rekv_id, sum(lopp_saldo.summa) AS lopp_saldo, isik_id
                  FROM (
                           -- alg.saldo
                           SELECT a.alg_db - a.alg_kr AS summa,
                                  a.rekv_id           AS rekv_id,
                                  a.isik_id
                           FROM alg_saldo a
                           UNION ALL
                           -- laekumised
                           SELECT -1 * l.summa AS summa,
                                  l.rekv_id    AS rekv_id,
                                  l.isik_id
                           FROM laekumised l
                           UNION ALL
                           -- mahakandmine
                           SELECT -1 * l.summa AS summa,
                                  l.rekv_id    AS rekv_id,
                                  l.isik_id
                           FROM mahakandmine l
                           UNION ALL
                           -- arvestused
                           SELECT k.arvestatud AS summa,
                                  k.rekv_id    AS rekv_id,
                                  k.isik_id
                           FROM arvestatud k
                       ) lopp_saldo
                  GROUP BY rekv_id, isik_id)

         SELECT sum(alg_db)     AS alg_db,
                sum(alg_kr)     AS alg_kr,
                sum(db)         AS db,
                sum(kr)         AS kr,
                sum(mahakantud) AS mahakantud,
                sum(lopp_db)    AS lopp_db,
                sum(lopp_kr)    AS lopp_kr,
                qry.rekv_id,
                qry.isik_id
         FROM (
                  -- alg.saldo
                  SELECT CASE WHEN a.alg_db - a.alg_kr > 0 THEN a.alg_db - a.alg_kr ELSE 0 END AS alg_db,
                         CASE WHEN a.alg_kr - a.alg_db > 0 THEN a.alg_kr - a.alg_db ELSE 0 END AS alg_kr,
                         0                                                                     AS db,
                         0                                                                     AS kr,
                         0                                                                     AS mahakantud,
                         0                                                                     AS lopp_db,
                         0                                                                     AS lopp_kr,
                         a.rekv_id                                                             AS rekv_id,
                         isik_id
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
                         l.rekv_id AS rekv_id,
                         l.isik_id
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
                         l.rekv_id AS rekv_id,
                         l.isik_id
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
                         k.rekv_id    AS rekv_id,
                         k.isik_id
                  FROM arvestatud k
                       -- lopp saldo
                  UNION ALL
                  SELECT 0                                                            AS alg_db,
                         0                                                            AS alg_kr,
                         0                                                            AS db,
                         0                                                            AS kr,
                         0                                                            AS mahakantud,
                         CASE WHEN l.lopp_saldo > 0 THEN l.lopp_saldo ELSE 0 END      AS lopp_db,
                         -1 * CASE WHEN l.lopp_saldo < 0 THEN l.lopp_saldo ELSE 0 END AS lopp_kr,
                         rekv_id                                                      AS rekv_id,
                         isik_id
                  FROM lopp_saldo l
              ) qry
         GROUP BY rekv_id, isik_id
     ) report
         INNER JOIN ou.rekv r ON r.id = report.rekv_id

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE,INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE,INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE,INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik(INTEGER, DATE, DATE,INTEGER) TO dbvaatleja;

/*
explain
select *
FROM lapsed.saldo_ja_kaibeandmik(69, '2023-01-01', '2023-01-31',7128) qry
*/
