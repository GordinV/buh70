--DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);
DROP FUNCTION IF EXISTS lapsed.kaive_aruanne_maksja(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.kaive_aruanne_maksja(l_rekvid INTEGER,
                                                       kpv_start DATE DEFAULT make_date(date_part('year', current_date)::INTEGER, 1, 1),
                                                       kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        id               BIGINT,
        lapse_isikukood  TEXT,
        maksja_isikukood TEXT,
        viitenumber      TEXT,
        alg_saldo        NUMERIC(14, 2),
        arvestatud       NUMERIC(14, 2),
        umberarvestus    NUMERIC(14, 2),
        soodustus        NUMERIC(14, 2),
        laekumised       NUMERIC(14, 2),
        mahakantud       NUMERIC(14, 2),
        tagastused       NUMERIC(14, 2),
        jaak             NUMERIC(14, 2),
        rekvid           INTEGER
    )
AS
$BODY$
WITH rekv_ids AS (
    SELECT rekv_id
    FROM public.get_asutuse_struktuur(l_rekvid)),
     docs_types AS (
         SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('SMK', 'VMK', 'ARV')
     )

SELECT count(*) OVER (PARTITION BY report.laps_id)                  AS id,
       l.isikukood::TEXT                                            AS lapse_isikukood,
       a.regkood::TEXT                                              AS maksja_isikukood,
       lapsed.get_viitenumber(report.rekv_id, report.laps_id)::TEXT AS viitenumber,
       alg_saldo::NUMERIC(14, 2),
       arvestatud::NUMERIC(14, 2),
       umberarvestus::NUMERIC(14, 2),
       soodustus::NUMERIC(14, 2),
       laekumised::NUMERIC(14, 2),
       mahakantud::NUMERIC(14, 2),
       tagastused::NUMERIC(14, 2),
       COALESCE(alg_saldo, 0) +
       COALESCE(arvestatud, 0) +
       COALESCE(umberarvestus, 0) -
       COALESCE(soodustus, 0) -
       COALESCE(laekumised, 0) -
       COALESCE(mahakantud, 0) +
       COALESCE(tagastused, 0)::NUMERIC(14, 2)                      AS jaak,
       report.rekv_id
FROM (
         WITH alg_saldo AS (
             SELECT laps_id, rekv_id, sum(summa) AS jaak, maksja_id
             FROM (
                      -- laekumised
                      SELECT -1 * (CASE WHEN mk.opt = 2 THEN 1 ELSE -1 END) * mk1.summa AS summa,
                             l.id                                                       AS laps_id,
                             D.rekvid                                                   AS rekv_id,
                             j.asutusid                                               AS maksja_id
                      FROM docs.doc D
                               INNER JOIN docs.Mk mk ON mk.parentid = D.id
                               INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                               INNER JOIN lapsed.laps l ON l.id = ld.parentid
                               inner join docs.journal j on j.parentid = mk1.journalid

                      WHERE D.status <> 3
                        AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                        AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood <> 'ARV')
                        AND mk.maksepaev < kpv_start
                          UNION ALL
                          SELECT a1.summa AS summa,
                          ld.parentid AS laps_id,
                          D.rekvid AS rekv_id,
                          a.asutusid
                          FROM docs.doc D
                          INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                          INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                          INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                          WHERE COALESCE((a.properties ->> 'tyyp')::TEXT,
                                         '') <>
                                'ETTEMAKS'
                        AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                        AND d.status < 3
                        AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                        AND a.liik = 0          -- только счета исходящие
                        AND a.kpv < kpv_start
-- mahakandmine
                          UNION ALL
                          SELECT -1 * a.summa AS summa
                          ,
                          l.parentid AS laps_id
                          ,
                          a.rekvid AS rekv_id
                          ,
                          arv.asutusid
                          FROM docs.arvtasu a
                          INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                          INNER JOIN docs.arv arv ON a.doc_arv_id = arv.parentid
                          WHERE a.pankkassa = 3 -- только проводки
                        AND a.rekvid IN (SELECT rekv_id FROM rekv_ids)
                        AND a.kpv < kpv_start
                        AND a.status <> 3
                        AND (arv.properties ->>
                             'tyyp' IS NULL OR
                             arv.properties ->>
                             'tyyp' <>
                             'ETTEMAKS') -- уберем предоплаты

                  ) alg_saldo
             GROUP BY laps_id, rekv_id, maksja_id
         ),
              mahakandmine AS (
                  SELECT sum(a.summa) AS summa,
                         l.parentid   AS laps_id,
                         a.rekvid     AS rekv_id,
                         arv.asutusid
                  FROM docs.arvtasu a
                           INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                           INNER JOIN docs.arv arv ON a.doc_arv_id = arv.parentid
                  WHERE a.status <> 3
                    AND a.pankkassa = 3
                    AND a.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
                    AND (arv.properties ->>
                         'tyyp' IS NULL OR
                         arv.properties ->>
                         'tyyp' <>
                         'ETTEMAKS') -- уберем предоплаты
                      GROUP BY l.parentid
                      , a.rekvid
                      , arv.asutusid
              ),
              laekumised AS (
                  SELECT sum(mk1.summa) AS summa,
                         l.id           AS laps_id,
                         D.rekvid       AS rekv_id,
                         j.asutusid
                  FROM docs.doc D
                           INNER JOIN docs.Mk mk ON mk.parentid = D.id
                           INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                           INNER JOIN lapsed.laps l ON l.id = ld.parentid
                           inner join docs.journal j on j.parentid = mk1.journalid
                  WHERE D.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood <> 'ARV')
                    AND mk.opt = 2
                    AND mk1.summa > 0
                    AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND mk.maksepaev >= kpv_start
                    AND mk.maksepaev <= kpv_end
                      GROUP BY l.id
                      , D.rekvid
                      , j.asutusid
              ),
              tagastused AS (
                  SELECT sum(CASE WHEN mk.opt = 2 THEN -1 ELSE 1 END * mk1.summa) AS summa,
                         l.id                                                     AS laps_id,
                         D.rekvid                                                 AS rekv_id,
                         j.asutusid
                  FROM docs.doc D
                           INNER JOIN docs.Mk mk ON mk.parentid = D.id
                           INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                           INNER JOIN lapsed.laps l ON l.id = ld.parentid
                           inner join docs.journal j on j.parentid = mk1.journalid

                  WHERE D.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood <> 'ARV')
                    AND (mk.opt = 1 OR (mk.opt = 2 AND mk1.summa < 0))
                    AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND mk.maksepaev >= kpv_start
                    AND mk.maksepaev <= kpv_end
                      GROUP BY l.id
                      , D.rekvid
                      , j.asutusid
              ),
              arvestatud AS (
                  SELECT ld.parentid                                                                            AS laps_id,
                         sum(a1.umberarvestus::NUMERIC(14, 2))                                                  AS umberarvestus,
                         sum(CASE
                                 WHEN kas_umberarvestus THEN 0
                                 ELSE (a1.summa + (COALESCE(a1.soodustus, 0) * a1.kogus)) END ::NUMERIC(14, 2)) AS arvestatud,
                         sum((COALESCE(a1.soodustus, 0) * a1.kogus)::NUMERIC(14, 2))                            AS soodustus,
                         D.rekvid::INTEGER                                                                      AS rekv_id,
                         a.asutusid
                  FROM docs.doc D
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                           INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                           INNER JOIN (SELECT a1.parentid                                                               AS arv_id,
                                              (
                                                  (COALESCE((a1.properties ->>
                                                             'soodustus')::NUMERIC(14, 4),
                                                            0)))                                                        AS soodustus,
                                              a1.summa                                                                  AS summa,
                                              ((CASE
                                                    WHEN (coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN)
                                                        THEN 1
                                                    ELSE 0 END) *
                                               (COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) +
                                                a1.summa))                                                              AS umberarvestus,
                                              coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN AS kas_umberarvestus,
                                              a1.kogus                                                                  AS kogus
                                       FROM docs.arv1 a1
                                                INNER JOIN docs.arv a ON a.id = a1.parentid
                                                INNER JOIN docs.doc D ON D.id = a.parentid
                                                INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                                       WHERE coalesce(n.properties ->> 'tyyp', '') <> 'SOODUSTUS' -- только простые операции, без льготных
                                         AND n.dok = 'ARV'
                                         AND n.rekvid = d.rekvid
                                         AND D.status <> 3
                                         AND (a.properties ->> 'tyyp' IS NULL
                                           OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                                         AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                                         AND a.liik = 0 -- только счета исходящие
                  ) a1
                                      ON a1.arv_id = a.id
                  WHERE COALESCE((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                    AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.status < 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND a.liik = 0 -- только счета исходящие
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
                      GROUP BY ld.parentid
                      , D.rekvid
                      , a.asutusid
                      UNION ALL
                      SELECT ld.parentid AS laps_id
                      ,
                      sum(a1.umberarvestus) ::NUMERIC(14, 4) AS umberarvestus
                      ,
                      sum(CASE
                              WHEN kas_umberarvestus THEN 0
                              ELSE (a1.summa + (COALESCE(a1.soodustus, 0) * a1.kogus)) END) ::NUMERIC(14, 4) AS arvestatud
                      ,
                      sum(a1.soodustus) AS soodustus
                      ,
                      D.rekvid::INTEGER AS rekv_id
                      ,
                      a.asutusid
                      FROM docs.doc D
                      INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                      INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                      INNER JOIN (SELECT a1.parentid                                                               AS arv_id,
                                         -1 * a1.summa                                                             AS soodustus, -- переворачиваем сумму как льготу
                                         a1.summa                                                                  AS summa,
                                         ((CASE
                                               WHEN (coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN)
                                                   THEN 1
                                               ELSE 0 END) *
                                          (COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) +
                                           a1.summa))                                                              AS umberarvestus,
                                         coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN AS kas_umberarvestus,
                                         a1.kogus                                                                  AS kogus
                                  FROM docs.arv1 a1
                                           INNER JOIN docs.arv a ON a.id = a1.parentid
                                           INNER JOIN docs.doc D ON D.id = a.parentid AND D.status <> 3
                                           INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                                  WHERE coalesce(n.properties ->> 'tyyp', '') = 'SOODUSTUS' -- только операции льготы
                                    AND n.dok = 'ARV'
                                    AND n.rekvid = d.rekvid

                                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                                    AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                                    AND a.liik = 0 -- только счета исходящие
                      ) a1
                      ON a1.arv_id = a.id
                      WHERE COALESCE((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                    AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.status < 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND a.liik = 0 -- только счета исходящие
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
                      GROUP BY ld.parentid
                      , D.rekvid
                      , a.asutusid
              )
         SELECT sum(alg_saldo)     AS alg_saldo,
                sum(arvestatud)    AS arvestatud,
                sum(umberarvestus) AS umberarvestus,
                sum(soodustus)     AS soodustus,
                sum(laekumised)    AS laekumised,
                sum(mahakantud)    AS mahakantud,
                sum(tagastused)    AS tagastused,
                qry.rekv_id,
                qry.laps_id,
                qry.maksja_id
         FROM (
                  -- alg.saldo
                  SELECT a.jaak    AS alg_saldo,
                         0         AS arvestatud,
                         0         AS umberarvestus,
                         0         AS soodustus,
                         0         AS laekumised,
                         0         AS mahakantud,
                         0         AS tagastused,
                         a.rekv_id AS rekv_id,
                         a.laps_id,
                         a.maksja_id
                  FROM alg_saldo a
                  UNION ALL
                  -- laekumised
                  SELECT 0         AS alg_saldo,
                         0         AS arvestatud,
                         0         AS umberarvestus,
                         0         AS soodustus,
                         l.summa   AS laekumised,
                         0         AS mahakantud,
                         0         AS tagastused,
                         l.rekv_id AS rekv_id,
                         l.laps_id,
                         l.asutusid
                  FROM laekumised l
                  UNION ALL
                  -- mahakandmine
                  SELECT 0         AS alg_saldo,
                         0         AS arvestatud,
                         0         AS umberarvestus,
                         0         AS soodustus,
                         0         AS laekumised,
                         l.summa   AS mahakantud,
                         0         AS tagastused,
                         l.rekv_id AS rekv_id,
                         l.laps_id,
                         l.asutusid
                  FROM mahakandmine l
                  UNION ALL
                  -- tagastused
                  SELECT 0                    AS alg_saldo,
                         0                    AS arvestatud,
                         0                    AS umberarvestus,
                         0                    AS soodustus,
                         0                    AS laekumised,
                         0                    AS mahakantud,
                         COALESCE(t.summa, 0) AS tagastused,
                         t.rekv_id            AS rekv_id,
                         t.laps_id,
                         t.asutusid
                  FROM tagastused t
                  UNION ALL
                  -- arvestused
                  SELECT 0               AS alg_saldo,
                         k.arvestatud    AS arvestatud,
                         k.umberarvestus AS umberarvestus,
                         k.soodustus     AS soodustus,
                         0               AS laekumised,
                         0               AS mahakantud,
                         0               AS tagastused,
                         k.rekv_id       AS rekv_id,
                         k.laps_id,
                         k.asutusid
                  FROM arvestatud k
              ) qry
         GROUP BY laps_id, rekv_id, maksja_id
     ) report
         INNER JOIN lapsed.laps l
                    ON report.laps_id = l.id
         INNER JOIN libs.asutus a ON a.id = report.maksja_id

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.kaive_aruanne_maksja(INTEGER, DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kaive_aruanne_maksja(INTEGER, DATE, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.kaive_aruanne_maksja(INTEGER, DATE, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.kaive_aruanne_maksja(INTEGER, DATE, DATE) TO dbvaatleja;


/*
select *
FROM lapsed.kaive_aruanne_maksja(119, '2023-01-01', '2023-01-31') qry
where lapse_isikukood = '33705263715'

select *
FROM lapsed.kaive_aruanne(119, '2023-01-01', '2023-01-31') qry
where lapse_isikukood = '50311103728'


*/
