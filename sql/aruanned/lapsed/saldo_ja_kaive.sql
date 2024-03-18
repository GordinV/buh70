--DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);
DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.saldo_ja_kaive(l_rekvid INTEGER,
                                                 kpv_start DATE DEFAULT make_date(date_part('year', current_date)::INTEGER, 1, 1),
                                                 kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        id              BIGINT,
        period          DATE,
        kulastatavus    TEXT,
        lapse_nimi      TEXT,
        lapse_isikukood TEXT,
        yksus           TEXT,
        viitenumber     TEXT,
        alg_saldo       NUMERIC(14, 2),
        arvestatud      NUMERIC(14, 2),
        umberarvestus   NUMERIC(14, 2),
        soodustus       NUMERIC(14, 2),
        laekumised      NUMERIC(14, 4),
        mahakantud      NUMERIC(14, 2),
        tagastused      NUMERIC(14, 2),
        jaak            NUMERIC(14, 4),
        rekvid          INTEGER
    )
AS
$BODY$
WITH rekv_ids AS (
    SELECT rekv_id
    FROM public.get_asutuse_struktuur(l_rekvid)
),
     docs_types AS (
         SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('SMK', 'VMK', 'ARV')
     ),
     range_parameters AS (
         SELECT ('[' || format_date(coalesce(kpv_start::TEXT, make_date(year(current_date), 01, 01)::TEXT))::TEXT ||
                 ',' ||
                 (format_date((kpv_end::DATE + CASE
                                                   WHEN kpv_start::DATE = kpv_end::DATE
                                                       THEN INTERVAL '1 day'
                                                   ELSE INTERVAL '0 day' END)::TEXT)::TEXT) ||
                 ')') ::DATERANGE AS range,
                kpv_start::DATE   AS period_start,
                kpv_end::DATE     AS period_finish
--           case when $5::text is not null and $5::text = '' then null::date else $5::DATE end::date as kehtiv_kpv
     ),

     kulastavus AS (
         SELECT parentid,
                rekvid,
                yksus,
                min(alg_kpv)            AS alg_kpv,
                max(lopp_kpv)           AS lopp_kpv,
                CASE
                    WHEN
                            (('[' || format_date(min(qry.alg_kpv)::TEXT)::TEXT || ',' ||
                              format_date((max(qry.lopp_kpv)::DATE +
                                           CASE
                                               WHEN min(qry.alg_kpv) = max(qry.lopp_kpv) THEN INTERVAL '1 day'
                                               ELSE INTERVAL '0 day' END)::TEXT)::TEXT ||
                              ')'))::DATERANGE @> range_parameters.range THEN 'Jah'
                    ELSE 'Ei' END::TEXT AS kulastavus_,
                CASE
                    WHEN max(lopp_kpv) >= kpv_end OR min(alg_kpv) < kpv_start THEN 'Jah'
                    ELSE 'Ei' END::TEXT AS kulastavus
         FROM (
                  SELECT parentid,
                         rekvid,
                         lk.properties ->> 'yksus'                                                  AS yksus,
                         coalesce(
                                 (lk.properties ->> 'alg_kpv')::DATE,
                                 make_date(date_part('year', current_date)::INTEGER, 1, 1))::DATE   AS alg_kpv,
                         coalesce(
                                 (lk.properties ->> 'lopp_kpv')::DATE,
                                 make_date(date_part('year', current_date)::INTEGER, 12, 31))::DATE AS lopp_kpv,
                         ('[' || format_date(coalesce((lk.properties ->> 'alg_kpv')::TEXT,
                                                      make_date(year(current_date), 01, 01)::TEXT))::TEXT || ',' ||
                          (format_date(((lk.properties ->> 'lopp_kpv')::DATE::DATE + CASE
                                                                                         WHEN (lk.properties ->> 'alg_kpv')::DATE =
                                                                                              (lk.properties ->> 'lopp_kpv')::DATE
                                                                                             THEN INTERVAL '1 day'
                                                                                         ELSE INTERVAL '0 day' END)::TEXT)::TEXT) ||
                          ')') ::DATERANGE                                                          AS lk_range

                  FROM lapsed.lapse_kaart lk
                  WHERE lk.staatus <> 3
                    AND lk.rekvid IN (SELECT rekv_id FROM rekv_ids)
              ) qry,
              range_parameters

         GROUP BY parentid,
                  rekvid,
                  yksus,
                  range_parameters.range
     )

SELECT count(*) OVER (PARTITION BY laps_id)                        AS id,
       kpv_start::DATE                                             AS period,
       CASE
           WHEN k.lopp_kpv >= kpv_end THEN 'Jah'
           ELSE 'Ei' END::TEXT                                     AS kulastatavus,
       ltrim(rtrim(l.nimi))::TEXT                                  AS lapse_nimi,
       l.isikukood::TEXT                                           AS lapse_isikukood,
       coalesce(report.yksus, '')::TEXT,
       lapsed.get_viitenumber(report.rekvid, report.laps_id)::TEXT AS viitenumber,
       sum(coalesce(alg_saldo, 0))::NUMERIC(14, 2),
       sum(coalesce(arvestatud, 0))::NUMERIC(14, 2),
       sum(coalesce(umberarvestus, 0))::NUMERIC(14, 2),
       sum(coalesce(soodustus, 0))::NUMERIC(14, 2),
       sum(coalesce(laekumised, 0))::NUMERIC(14, 4),
       sum(coalesce(mahakantud, 0))::NUMERIC(14, 2),
       sum(coalesce(-1 * tagastused, 0))::NUMERIC(14, 2),
       sum(COALESCE(alg_saldo, 0) +
           COALESCE(arvestatud, 0) +
           COALESCE(umberarvestus, 0) -
           COALESCE(laekumised, 0) -
           COALESCE(mahakantud, 0) -
           COALESCE(soodustus, 0) +
           COALESCE(tagastused, 0))::NUMERIC(14, 4)                AS jaak,
       report.rekvid
FROM (
         WITH alg_saldo AS (
             SELECT laps_id, rekv_id AS rekvid, sum(summa) AS alg_saldo, yksus
             FROM (
                      -- laekumised (ettemaksed)
                      SELECT -1 * (CASE WHEN mk.opt = 2 THEN 1 ELSE -1 END) * mk.jaak AS summa,
                             l.id                                                     AS laps_id,
                             CASE
                                 WHEN mk.properties ->> 'yksus' IS NULL THEN ''
                                 ELSE mk.properties ->> 'yksus' END                   AS yksus,
                             D.rekvid                                                 AS rekv_id
                      FROM docs.doc D
                               INNER JOIN docs.Mk mk ON mk.parentid = D.id
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                               INNER JOIN lapsed.laps l ON l.id = ld.parentid
                      WHERE D.status <> 3
                        AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                        AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood <> 'ARV')
                        AND mk.maksepaev < kpv_start
                        AND mk.jaak <> 0
                      UNION ALL
                      -- возвраты
                      SELECT sum(-1 * at.summa)                      AS summa,
                             l.parentid                              AS laps_id,
                             coalesce(mk.properties ->> 'yksus', '') AS yksus,
                             at.rekvid
                      FROM docs.arvtasu at
                               INNER JOIN lapsed.liidestamine l ON l.docid = at.doc_arv_id
                               INNER JOIN docs.mk mk ON mk.parentid = at.doc_arv_id
                      WHERE mk.maksepaev < kpv_start
                        AND at.status <> 3
                        AND at.pankkassa = 4 -- только возвраты
                        AND at.summa > 0     -- выплаты
                        AND at.rekvid IN (SELECT rekv_id FROM rekv_ids)
                      GROUP BY l.parentid, at.rekvid, coalesce(mk.properties ->> 'yksus', '')

                      UNION ALL
                      -- laekumised
                      -- распределенные авансовые платежи
                      SELECT -1 * ((a1.summa / a.summa) * at.summa) AS summa,
                             l.parentid                             AS laps_id,
                             a1.properties ->> 'yksus'              AS yksus,
                             at.rekvid                              AS rekv_id
                      FROM docs.arvtasu at
                               INNER JOIN docs.arv a ON at.doc_arv_id = a.parentid
                               INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                               INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                               INNER JOIN docs.doc d ON d.id = a.parentid
                      WHERE at.kpv < kpv_start::DATE
                        AND at.status <> 3
                        AND d.status < 3
                        AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                        AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                        AND a.rekvid IN (SELECT rekv_id FROM rekv_ids)
                      UNION ALL
                      SELECT a1.summa    AS summa,
                             ld.parentid AS laps_id,
                             a1.properties ->> 'yksus',
                             D.rekvid    AS rekv_id
                      FROM docs.doc D
                               INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                               INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                               INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                      WHERE COALESCE((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                        AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                        AND d.status < 3
                        AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                        AND a.liik = 0 -- только счета исходящие
                        AND a.kpv < kpv_start
-- mahakandmine
                      UNION ALL
                      SELECT -1 * a.summa AS summa,
                             l.parentid   AS laps_id,
                             arv1.properties ->> 'yksus',
                             a.rekvid     AS rekv_id
                      FROM docs.arvtasu a
                               INNER JOIN lapsed.liidestamine l ON l.docid = a.doc_arv_id
                               INNER JOIN docs.arv arv ON a.doc_arv_id = arv.parentid
                               INNER JOIN docs.arv1 arv1 ON arv.id = arv1.parentid
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
             GROUP BY laps_id, rekv_id, yksus
         ),

              laekumised AS (
                  SELECT a.rekvid,
                         a1.properties ->>
                         'yksus'                                     AS yksus,
                         sum(((a1.summa / a.summa) * AT.tagastus))   AS tagastus,
                         sum(((a1.summa / a.summa) * AT.laekumised)) AS laekumised,
                         l.parentid                                  AS laps_id
                  FROM (SELECT doc_arv_id,
                               sum(summa) FILTER (WHERE summa > 0) laekumised,
                               sum(summa) FILTER (WHERE summa < 0) tagastus
                        FROM docs.arvtasu
                        WHERE kpv >= kpv_start::DATE
                          AND kpv <= kpv_end::DATE
                          AND status <> 3
                          AND pankkassa < 3 -- только платежные документы
                          AND rekvid IN (SELECT rekv_id FROM rekv_ids)
                        GROUP BY doc_arv_id
                       ) AT
                           INNER JOIN docs.arv a ON AT.doc_arv_id = a.parentid
                           INNER JOIN docs.doc D ON D.id = a.parentid
                           INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                           INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                  WHERE a.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND D.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND (a.properties ->> 'tyyp' IS NULL
                      OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                    AND a.liik = 0 -- только счета исходящие
                  GROUP BY AT.doc_arv_id, (a1.properties ->> 'yksus'), l.parentid, a.rekvid
                  UNION ALL
                  -- возвраты
                  SELECT at.rekvid,
                         coalesce(mk.properties ->> 'yksus', '') AS yksus,
                         sum(-1 * at.summa)                      AS tagastus,
                         0                                       AS laekumised,
                         l.parentid                              AS laps_id
                  FROM docs.arvtasu at
                           INNER JOIN lapsed.liidestamine l ON l.docid = at.doc_tasu_id
                           INNER JOIN docs.mk mk ON mk.parentid = at.doc_arv_id
                  WHERE at.kpv >= kpv_start::DATE
                    AND at.kpv <= kpv_end::DATE
                    AND status <> 3
                    AND pankkassa = 4 -- только возвраты
                    AND at.summa > 0  -- выплаты
                    AND at.rekvid IN (SELECT rekv_id FROM rekv_ids)
                  GROUP BY l.parentid, at.rekvid, coalesce(mk.properties ->> 'yksus', '')
                  UNION ALL
                  -- поступления , компенсированные возвратами
                  SELECT at.rekvid,
                         coalesce(mk.properties ->> 'yksus', '') AS yksus,
                         0                                       AS tagastus,
                         sum(at.summa)                           AS laekumised,
                         l.parentid                              AS laps_id
                  FROM docs.arvtasu at
                           INNER JOIN lapsed.liidestamine l ON l.docid = at.doc_tasu_id
                           INNER JOIN docs.mk mk ON mk.parentid = at.doc_arv_id
                  WHERE mk.maksepaev >= kpv_start::DATE
                    AND mk.maksepaev <= kpv_end::DATE
                    AND status <> 3
                    AND pankkassa = 4 -- только возвраты
                    AND at.summa > 0  -- выплаты
                    AND at.rekvid IN (SELECT rekv_id FROM rekv_ids)
                  GROUP BY l.parentid, at.rekvid, coalesce(mk.properties ->> 'yksus', '')
              ),
              mahandmine AS (
                  SELECT a.rekvid,
                         a1.properties ->> 'yksus'                             AS yksus,
                         sum((a1.summa / a.summa) * AT.summa) ::NUMERIC(14, 2) AS summa,
                         l.parentid                                            AS laps_id
                  FROM (SELECT doc_arv_id, sum(summa) summa
                        FROM docs.arvtasu
                        WHERE kpv >= kpv_start::DATE
                          AND kpv <= kpv_end::DATE
                          AND status <> 3
                          AND pankkassa = 3 -- только проводки (списания)
                          AND rekvid IN (SELECT rekv_id FROM rekv_ids)
                        GROUP BY doc_arv_id
                       ) AT
                           INNER JOIN docs.arv a ON AT.doc_arv_id = a.parentid
                           INNER JOIN docs.doc D ON D.id = a.parentid
                           INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                           INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                  WHERE a.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND D.status <> 3
                    AND a.liik = 0 -- только счета исходящие
                    AND (a.properties ->>
                         'tyyp' IS NULL
                      OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                  GROUP BY AT.doc_arv_id, (a1.properties ->>
                                           'yksus'), AT.summa, l.parentid, a.rekvid
              ),
              arvestatud AS (
                  -- без усдуг - льгот
                  SELECT ld.parentid                                                                                           AS laps_id,
                         (a1.properties ->> 'yksus')                                                                           AS yksus,
                         (CASE
                              WHEN coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN THEN 0
                              ELSE (a1.summa +
                                    ((COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0)) * a1.kogus)) END::NUMERIC(14, 2)) AS arvestatud,
                         ((CASE
                               WHEN (coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN)
                                   THEN 1
                               ELSE 0 END) *
                          (COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) * a1.kogus +
                           a1.summa)) ::NUMERIC(14, 2)                                                                         AS umberarvestus,
                         (COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) * a1.kogus)::NUMERIC(14, 2)                    AS soodustus,
                         D.rekvid::INTEGER                                                                                     AS rekvid
                  FROM docs.doc D
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                           INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                           INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                           INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                  WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND a.liik = 0 -- только счета исходящие
                    AND coalesce(n.properties ->> 'tyyp', '') <> 'SOODUSTUS'
                    AND n.dok = 'ARV'
                    AND n.rekvid = d.rekvid
                    AND (a.properties ->> 'tyyp' IS NULL
                      OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                    AND D.status <> 3
                  UNION ALL
                  -- добавим счета с услугами - льготами
                  SELECT ld.parentid                                                 AS laps_id,
                         (a1.properties ->> 'yksus')                                 AS yksus,
                         (CASE
                              WHEN coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN THEN 0
                              ELSE (a1.summa +
                                    (-1 * a1.summa * a1.kogus)) END::NUMERIC(14, 2)) AS arvestatud,
                         (CASE
                              WHEN (coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN)
                                  THEN a1.summa + (-1 * a1.summa * a1.kogus)
                              ELSE 0 END)::NUMERIC(14, 2)                            AS umberarvestus,
                         -1 * a1.summa::NUMERIC(14, 2)                               AS soodustus,
                         D.rekvid::INTEGER                                           AS rekvid
                  FROM docs.doc D
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                           INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                           INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                           INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                  WHERE D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND a.liik = 0 -- только счета исходящие
                    AND coalesce(n.properties ->> 'tyyp', '') = 'SOODUSTUS'
                    AND n.dok = 'ARV'
                    AND n.rekvid = d.rekvid
                    AND (a.properties ->> 'tyyp' IS NULL
                      OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                    AND D.status <> 3
              ),
              ettemaksud AS (
                  SELECT DISTINCT mk.id                                                                            AS doc_tasu_id,
                                  (CASE WHEN mk.opt = 2 AND mk1.summa > 0 THEN mk.jaak ELSE 0 END)::NUMERIC(14, 4) AS laekumised,
                                  (CASE
                                       WHEN mk.opt = 2 AND mk1.summa < 0 THEN mk.jaak
                                       WHEN mk.opt = 1 THEN -1 * mk.jaak
                                       ELSE 0 END)::NUMERIC(14, 4)                                                 AS tagastused,
                                  CASE
                                      WHEN mk.properties ->> 'yksus' IS NOT NULL AND mk.properties ->> 'yksus' <> ''
                                          THEN mk.properties ->> 'yksus'
                                      WHEN mk.properties ->> 'yksus' IS NULL THEN ''
                                      ELSE 'EM' END                                                                AS yksus,
                                  l.parentid                                                                       AS laps_id,
                                  d.rekvid
                  FROM docs.doc d
                           INNER JOIN docs.mk mk ON mk.parentid = d.id
                           INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
                           INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                  WHERE d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood <> 'ARV')
                    AND mk.maksepaev >= kpv_start
                    AND mk.maksepaev <= kpv_end
                    AND mk.jaak <> 0
              )
         SELECT COALESCE(yksus, '')  AS yksus,
                sum(alg_saldo)       AS alg_saldo,
                sum(arvestatud)      AS arvestatud,
                sum(umberarvestus)   AS umberarvestus,
                sum(soodustus)       AS soodustus,
                sum(laekumised)      AS laekumised,
                sum(mahakantud)      AS mahakantud,
                sum(-1 * tagastused) AS tagastused,
                0                    AS jaak,
                qry.rekvid,
                qry.laps_id
         FROM (
                  -- alg.saldo
                  SELECT a.yksus                  AS yksus,
                         COALESCE(a.alg_saldo, 0) AS alg_saldo,
                         0                        AS arvestatud,
                         0                        AS umberarvestus,
                         0                        AS soodustus,
                         0                        AS laekumised,
                         0                        AS mahakantud,
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
                         0                         AS umberarvestus,
                         0                         AS soodustus,
                         COALESCE(a.laekumised, 0) AS laekumised,
                         0                         AS mahakantud,
                         COALESCE(a.tagastused, 0) AS tagastused,
                         0                         AS jaak,
                         a.rekvid                  AS rekvid,
                         a.laps_id
                  FROM ettemaksud a
                  UNION ALL
                  -- laekumised
                  SELECT a.yksus                   AS yksus,
                         0                         AS alg_saldo,
                         0                         AS arvestatud,
                         0                         AS umberarvestus,
                         0                         AS soodustus,
                         COALESCE(a.laekumised, 0) AS laekumised,
                         0                         AS mahakantud,
                         COALESCE(a.tagastus, 0)   AS tagastused,
                         0                         AS jaak,
                         a.rekvid                  AS rekvid,
                         a.laps_id
                  FROM laekumised a
                  UNION ALL
                  -- mahakandmine
                  SELECT a.yksus  AS yksus,
                         0        AS alg_saldo,
                         0        AS arvestatud,
                         0        AS umberarvestus,
                         0        AS soodustus,
                         0        AS laekumised,
                         a.summa  AS mahakantud,
                         0        AS tagastused,
                         0        AS jaak,
                         a.rekvid AS rekvid,
                         a.laps_id
                  FROM mahandmine a
                  UNION ALL
                  -- kaibed
                  SELECT k.yksus                      AS yksus,
                         0                            AS alg_saldo,
                         COALESCE(k.arvestatud, 0)    AS arvestatud,
                         COALESCE(k.umberarvestus, 0) AS umberarvestus,
                         COALESCE(k.soodustus, 0)     AS soodustus,
                         0                            AS laekumised,
                         0                            AS mahakantud,
                         0                            AS tagastused,
                         0                            AS jaak,
                         k.rekvid                     AS rekvid,
                         k.laps_id
                  FROM arvestatud k
              ) qry
         GROUP BY COALESCE(yksus, ''), rekvid, laps_id
     ) report
         LEFT OUTER JOIN kulastavus k
                         ON k.parentid = report.laps_id AND k.rekvid = report.rekvid AND
                            report.yksus LIKE '%' || k.yksus
         INNER JOIN lapsed.laps l ON l.id = report.laps_id
GROUP BY (CASE
              WHEN k.lopp_kpv >= kpv_end THEN 'Jah'
              ELSE 'Ei' END),
         l.nimi,
         l.isikukood,
         COALESCE(report.yksus, ''),
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

select
1, *
FROM lapsed.saldo_ja_kaive_(72, '2023-01-01', '2023-12-31') qry
where 1=1
and      viitenumber = '0720075001'
union all
select
2, *
FROM lapsed.saldo_ja_kaive(72, '2023-01-01', '2023-12-31') qry
where 1=1
and      viitenumber = '0720075001'



and   (kulastatavus = 'Jah'  or (alg_saldo <> 0 OR arvestatud <> 0 OR umberarvestus <> 0 OR soodustus <> 0 OR laekumised <> 0 OR mahakantud <> 0 OR
           jaak <> 0
              )
)

    union all
    SELECT 1
                         FROM lapsed.laps l
                                  INNER JOIN lapsed.lapse_kaart lk ON l.id = lk.parentid
                         WHERE l.isikukood = qry.lapse_isikukood
                           AND lk.rekvid = qry.rekvid
                           AND lk.properties ->> 'yksus' = qry.yksus
                           AND (lk.properties ->> 'lopp_kpv')::date >= qry.period::date
        )
unuon all
select *
FROM lapsed.kaive_aruanne(72, '2023-01-31', '2023-12-31') qry
where viitenumber= '0720075001'


*/