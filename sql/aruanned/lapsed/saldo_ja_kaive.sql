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
        laekumised      NUMERIC(14, 2),
        mahakantud      NUMERIC(14, 2),
        tagastused      NUMERIC(14, 2),
        jaak            NUMERIC(14, 2),
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
     kulastavus AS (
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
                                 make_date(date_part('year', current_date)::INTEGER, 1, 1))::DATE   AS alg_kpv,
                         coalesce(
                                 (lk.properties ->> 'lopp_kpv')::DATE,
                                 make_date(date_part('year', current_date)::INTEGER, 12, 31))::DATE AS lopp_kpv
                  FROM lapsed.lapse_kaart lk
                  WHERE lk.staatus <> 3
                    AND lk.rekvid IN (SELECT rekv_id FROM rekv_ids)
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
       coalesce(yksus, '')::TEXT,
       lapsed.get_viitenumber(report.rekvid, report.laps_id)::TEXT AS viitenumber,
       sum(coalesce(alg_saldo, 0))::NUMERIC(14, 4),
       sum(coalesce(arvestatud, 0))::NUMERIC(14, 4),
       sum(coalesce(umberarvestus, 0))::NUMERIC(14, 4),
       sum(coalesce(soodustus, 0))::NUMERIC(14, 4),
       sum(coalesce(laekumised, 0))::NUMERIC(14, 4),
       sum(coalesce(mahakantud, 0))::NUMERIC(14, 4),
       sum(coalesce(-1 * tagastused, 0))::NUMERIC(14, 4),
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
             -- alg_saldo
             SELECT kpv_start                                                     AS period,
                    COALESCE(alg_saldo.yksus, '')::TEXT                           AS yksus,
                    COALESCE(alg_saldo.jaak::NUMERIC(14, 4), 0) :: NUMERIC(14, 4) AS alg_saldo,
                    alg_saldo.rekv_id::INTEGER                                    AS rekvid,
                    l.id                                                          AS laps_id
             FROM lapsed.laps l
                      LEFT OUTER JOIN (SELECT COALESCE(jaak, 0)                AS jaak,
                                              laps_id,
                                              rekv_id,
                                              yksus,
                                              lapsed.get_last_maksja(docs_ids) AS asutus_id
                                       FROM lapsed.lapse_saldod(kpv_start::DATE, NULL::INTEGER, l_rekvid, 1)) alg_saldo
                                      ON alg_saldo.laps_id = l.id
             WHERE alg_saldo.rekv_id IN (SELECT rekv_id FROM rekv_ids)
         ),
              laekumised AS (
                  SELECT a.rekvid,
                         a1.properties ->>
                         'yksus'                                                      AS yksus,
                         sum(((a1.summa / a.summa) * AT.tagastus)) ::NUMERIC(14, 4)   AS tagastus,
                         sum(((a1.summa / a.summa) * AT.laekumised)) ::NUMERIC(14, 4) AS laekumised,
                         l.parentid                                                   AS laps_id
                  FROM (SELECT doc_arv_id,
                               sum(summa) FILTER (WHERE summa > 0) laekumised,
                               sum(summa) FILTER (WHERE summa < 0) tagastus
                        FROM docs.arvtasu
                        WHERE kpv >= kpv_start::DATE
                          AND kpv <= kpv_end::DATE
                          AND status <> 3
                          AND pankkassa <> 3 -- только платежные документы
                          AND rekvid IN (SELECT rekv_id FROM rekv_ids)
                        GROUP BY doc_arv_id
                       ) AT
                           INNER JOIN docs.arv a ON AT.doc_arv_id = a.parentid AND
                                                    (a.properties ->>
                                                     'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
                           INNER JOIN docs.doc D ON D.id = a.parentid
                           INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                           INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                  WHERE a.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND D.status <> 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND a.liik = 0 -- только счета исходящие
                  GROUP BY AT.doc_arv_id, (a1.properties ->> 'yksus'), l.parentid, a.rekvid
              ),
              mahandmine AS (
                  SELECT a.rekvid,
                         a1.properties ->>
                         'yksus'                                               AS yksus,
                         sum((a1.summa / a.summa) * AT.summa) ::NUMERIC(14, 4) AS summa,
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
                           INNER JOIN docs.arv a ON AT.doc_arv_id = a.parentid AND
                                                    (a.properties ->>
                                                     'tyyp' IS NULL OR a.properties ->>
                                                                       'tyyp' <>
                                                                       'ETTEMAKS')
                           INNER JOIN docs.doc D ON D.id = a.parentid
                           INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                           INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                  WHERE a.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND D.status <> 3
                    AND a.liik = 0 -- только счета исходящие
                  GROUP BY AT.doc_arv_id, (a1.properties ->>
                                           'yksus'), AT.summa, l.parentid, a.rekvid
              ),
              arvestatud AS (
                  SELECT ld.parentid                                                                         AS laps_id,
                         COALESCE(a1.yksus,
                                  '')::TEXT                                                                  AS yksus,
                         (CASE
                              WHEN kas_umberarvestus THEN 0
                              ELSE (a1.summa + (COALESCE(a1.soodustus, 0) * a1.kogus)) END) ::NUMERIC(14, 4) AS arvestatud,
                         a1.umberarvestus ::NUMERIC(14, 4)                                                   AS umberarvestus,
                         (COALESCE(a1.soodustus, 0) * a1.kogus)::NUMERIC(14, 2)                              AS soodustus,
                         D.rekvid::INTEGER                                                                   AS rekvid
                  FROM docs.doc D
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = D.id
                           INNER JOIN docs.arv a ON a.parentid = D.id AND a.liik = 0 -- только счета исходящие
                           INNER JOIN (SELECT a1.parentid                                                               AS arv_id,
                                              (COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0))                   AS soodustus,
                                              (a1.properties ->> 'yksus')                                               AS yksus,
                                              a1.summa                                                                  AS summa,
                                              coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN AS kas_umberarvestus,
                                              ((CASE
                                                    WHEN (coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN)
                                                        THEN 1
                                                    ELSE 0 END) *
                                               (COALESCE((a1.properties ->> 'soodustus')::NUMERIC, 0) +
                                                a1.summa))                                                              AS umberarvestus,
                                              a1.kogus
                                       FROM docs.arv1 a1
                                                INNER JOIN docs.arv a ON a.id = a1.parentid AND
                                                                         (a.properties ->>
                                                                          'tyyp' IS NULL OR a.properties ->>
                                                                                            'tyyp' <>
                                                                                            'ETTEMAKS')
                                           AND a.liik = 0 -- только счета исходящие
                                                INNER JOIN libs.nomenklatuur n ON n.id = a1.nomid
                                                INNER JOIN docs.doc D ON D.id = a.parentid AND D.status <> 3
                  ) a1
                                      ON a1.arv_id = a.id AND
                                         (a.properties ->>
                                          'tyyp' IS NULL OR a.properties ->>
                                                            'tyyp' <>
                                                            'ETTEMAKS')
                  WHERE COALESCE((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                    AND D.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'ARV')
                    AND a.liik = 0 -- только счета исходящие
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end),
              ettemaksud AS (
                  SELECT DISTINCT mk.id                                                                            AS doc_tasu_id,
                                  (CASE WHEN mk.opt = 2 AND mk1.summa > 0 THEN mk.jaak ELSE 0 END)::NUMERIC(14, 4) AS laekumised,
                                  (CASE
                                       WHEN mk.opt = 2 AND mk1.summa < 0 THEN mk.jaak
                                       WHEN mk.opt = 1 THEN -1 * mk.jaak
                                       ELSE 0 END)::NUMERIC(14, 4)                                                 AS tagastused,
                                  ''                                                                               AS yksus,
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
                         ON k.parentid = report.laps_id AND k.rekvid = report.rekvid
         INNER JOIN lapsed.laps l ON l.id = report.laps_id
GROUP BY (CASE
              WHEN k.lopp_kpv >= kpv_end THEN 'Jah'
              ELSE 'Ei' END),
         l.nimi,
         l.isikukood,
         COALESCE(yksus, ''),
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

select * from (
SELECT sum(alg_saldo) over() as alg_kokku, sum(arvestatud) over() as arv_kokku, sum(soodustus) over() as soodustus_kokku,
sum(laekumised) over() as laek_kokku, sum(jaak) over() as jaak_kokku, *, 'new' as report
FROM lapsed.saldo_ja_kaive(95, '2022-10-01'::date, '2022-10-30'::date) qry
union all
SELECT sum(alg_saldo) over() as alg_kokku, sum(arvestatud) over() as arv_kokku, sum(soodustus) over() as soodustus_kokku,
sum(laekumised) over() as laek_kokku, sum(jaak) over() as jaak_kokku, * , 'old' as report
FROM lapsed.saldo_ja_kaive(95, '2022-10-01', '2022-10-30') qry
) qry
order by lapse_isikukood, report , yksus

select sum(arvestatud) from (

SELECT * FROM lapsed.saldo_ja_kaive(96, '2021-01-01', '2021-01-31') qry
left outer join  lapsed.saldo_ja_kaive(84, '2021-01-01', '2021-01-31') qry1
on qry1.lapse_isikukood =  qry.lapse_isikukood
where qry.jaak <> qry1.alg_saldo


where lapse_isikukood in ('51608190242')
inner join (select sum()
where qry.laekumised > 0


) qry
where  is   IN ('0850136823')

select *
FROM lapsed.saldo_ja_kaive(69, '2021-01-01', '2021-12-31') qry

*/
