DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);

CREATE OR REPLACE FUNCTION lapsed.saldo_ja_kaive(l_rekvid INTEGER,
                                                 kpv_start DATE DEFAULT date(year(current_date), 1, 1),
                                                 kpv_end DATE DEFAULT current_date)
    RETURNS TABLE (
        period           DATE,
        kulastatavus     TEXT,
        lapse_nimi       TEXT,
        lapse_isikukood  TEXT,
        maksja_nimi      TEXT,
        maksja_isikukood TEXT,
        yksus            TEXT,
        viitenumber      TEXT,
        alg_saldo        NUMERIC(14, 2),
        arvestatud       NUMERIC(14, 2),
        soodustus        NUMERIC(14, 2),
        laekumised       NUMERIC(14, 2),
        tagastused       NUMERIC(14, 2),
        jaak             NUMERIC(14, 2),
        rekvid           INTEGER
    ) AS
$BODY$
SELECT coalesce(period, kpv_start)::DATE AS period,
       kulastatavus::TEXT,
       lapse_nimi::TEXT,
       lapse_isikukood::TEXT,
       maksja_nimi::TEXT,
       maksja_isikukood::TEXT,
       yksus::TEXT,
       viitenumber::TEXT,
       alg_saldo::NUMERIC(14, 2),
       arvestatud::NUMERIC(14, 2),
       soodustus::NUMERIC(14, 2),
       laekumised::NUMERIC(14, 2),
       tagastused::NUMERIC(14, 2),
       jaak::NUMERIC(14, 2),
       rekvid
FROM (
         WITH alg_saldo AS (
             -- alg_saldo
             SELECT kpv_start                                                   AS period,
                    'Ei'                                                        AS kulastatavus,
                    coalesce(alg_saldo.yksus, '')::TEXT                         AS yksus,
                    coalesce(alg_saldo.jaak::NUMERIC(14, 2), 0)::NUMERIC(14, 2) AS alg_saldo,
                    alg_saldo.rekv_id::INTEGER                                  AS rekvid,
                    l.id                                                        AS laps_id,
                    l.isikukood                                                 AS lapse_isikukood,
                    l.nimi                                                      AS lapse_nimi,
                    a.nimetus ::TEXT                                            AS maksja_nimi,
                    a.regkood::TEXT                                             AS maksja_isikukood,
                    lapsed.get_viitenumber(alg_saldo.rekv_id, l.id)::TEXT       AS viitenumber
             FROM lapsed.laps l
                      LEFT OUTER JOIN (SELECT jaak,
                                              laps_id,
                                              rekv_id,
                                              yksus,
                                              lapsed.get_last_maksja(docs_ids) AS asutus_id
                                       FROM lapsed.lapse_saldod(kpv_start::DATE)) alg_saldo
                                      ON alg_saldo.laps_id = l.id
                      INNER JOIN libs.asutus a ON a.id = alg_saldo.asutus_id
             WHERE alg_saldo.rekv_id IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
         ),
              kaibed AS (
                  SELECT l.id                                             AS laps_id,
                         kpv_start                                        AS period,
                         CASE
                             WHEN kulastavus.lopp_kpv >= kpv_end THEN 'Jah'
                             ELSE 'Ei' END::TEXT                          AS kulastatavus,
                         l.nimi::TEXT                                     AS lapse_nimi,
                         l.isikukood::TEXT                                AS lapse_isikukood,
                         i.nimetus::TEXT                                  AS maksja_nimi,
                         i.regkood::TEXT                                  AS maksja_isikukood,
                         coalesce(a1.yksus, '')::TEXT                     AS yksus,
                         lapsed.get_viitenumber(d.rekvid, l.id)::TEXT     AS viitenumber,
                         coalesce(a1.summa, 0)::NUMERIC(14, 2)            AS arvestatud,
                         coalesce(a1.soodustus, 0)::NUMERIC(14, 2)        AS soodustus,
                         0::NUMERIC(14, 2)                                AS laekumised,
                         coalesce(laekumised.tagastus, 0)::NUMERIC(14, 2) AS tagastused,
                         d.rekvid::INTEGER                                AS rekvid
                  FROM docs.doc d
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                           INNER JOIN lapsed.laps l ON l.id = ld.parentid
                           INNER JOIN docs.arv a ON a.parentid = d.id
                           INNER JOIN libs.asutus i ON i.id = a.asutusid AND i.staatus <> 3
                           INNER JOIN (SELECT parentid                    AS arv_id,
                                              sum(soodus)                 AS soodustus,
                                              (a1.properties ->> 'yksus') AS yksus,
                                              sum(summa)                  AS summa
                                       FROM docs.arv1 a1
                                       GROUP BY parentid, a1.properties ->> 'yksus') a1
                                      ON a1.arv_id = a.id
                           LEFT OUTER JOIN (
                      SELECT at.doc_arv_id                                                                        AS arv_id,
                             a1.properties ->> 'yksus'                                                            AS yksus,
                             sum(((a1.summa / a.summa) * at.summa)) FILTER ( WHERE at.summa < 0 )::NUMERIC(14, 2) AS tagastus,
                             sum(((a1.summa / a.summa) * at.summa)) FILTER ( WHERE at.summa > 0 )::NUMERIC(14, 2) AS laekumised,
                             sum((a1.summa / a.summa) * at.summa)                                                 AS summa
                      FROM docs.arvtasu at
                               INNER JOIN docs.arv a ON at.doc_arv_id = a.parentid
                               INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                      WHERE at.kpv >= kpv_start::DATE
                        AND at.kpv <= kpv_end::DATE
                        AND a.rekvid = l_rekvid
                      GROUP BY at.doc_arv_id, (a1.properties ->> 'yksus')
                  ) laekumised
                                           ON laekumised.arv_id = d.id
                                               AND laekumised.yksus = a1.yksus
                           LEFT OUTER JOIN (SELECT parentid,
                                                   rekvid,
                                                   min(alg_kpv)  AS alg_kpv,
                                                   max(lopp_kpv) AS lopp_kpv
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
                                                 ) qry
                                            GROUP BY parentid,
                                                     rekvid) kulastavus
                                           ON kulastavus.parentid = l.id AND kulastavus.rekvid = d.rekvid
                  WHERE coalesce((a.properties ->> 'tyyp')::TEXT, '') <> 'ETTEMAKS'
                    AND d.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND a.kpv >= kpv_start
                    AND a.kpv <= kpv_end
              ),
              ettemaksud AS (
                  SELECT kpv_start         AS period,
                         0::NUMERIC(14, 2) AS jaak, -- summa не связанных со счетами платежек (нач. сальдо или предоплата)
                         l.parentid        AS laps_id,
                         ymk.yksus         AS yksus,
                         d.rekvid          AS rekv_id,
                         d.id              AS docs_id,
                         ymk.summa         AS laekumised,
                         a.regkood         AS maksja_isikukood,
                         a.nimetus         AS maksja_nimi,
                         laps.isikukood    AS lapse_isikukood,
                         laps.nimi         AS lapse_nimi,
                         mk.viitenr        AS viitenumber
                  FROM docs.doc d
                           INNER JOIN (SELECT mk.id, mk.parentid, mk.viitenr
                                       FROM docs.mk mk
                                       WHERE mk.maksepaev >= kpv_start
                                         AND mk.maksepaev <= kpv_end
                                         AND mk.jaak > 0
                  ) mk ON mk.parentid = D.id
                           INNER JOIN lapsed.liidestamine l
                                      ON l.docid = D.id
                           INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
                           INNER JOIN libs.asutus a ON a.id = mk1.asutusid
                           INNER JOIN lapsed.laps laps ON laps.id = l.parentid
                          ,
                       lapsed.get_group_part_from_mk(D.id, kpv_end) AS ymk
                  WHERE D.status <> 3
                  UNION ALL
                  -- распределенные авансовые платежи
                  SELECT kpv_start                                  AS period,
                         0                                          AS jaak,
                         l.parentid                                 AS laps_id,
                         a1.properties ->> 'yksus'                  AS yksus,
                         at.rekvid                                  AS rekv_id,
                         at.doc_tasu_id                             AS docs_id,
                         ((a1.summa / a.summa) * at.summa)          AS laekumised,
                         maksja.regkood                             AS maksja_isikukood,
                         maksja.nimetus                             AS maksja_nimi,
                         laps.isikukood                             AS lapse_isikukood,
                         laps.nimi                                  AS lapse_nimi,
                         lapsed.get_viitenumber(at.rekvid, laps.id) AS viitenumber

                  FROM docs.arvtasu at
                           INNER JOIN docs.arv a ON at.doc_arv_id = a.parentid
                           INNER JOIN docs.arv1 a1 ON a1.parentid = a.id
                           INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                           INNER JOIN libs.asutus maksja ON maksja.id = a.asutusid
                           INNER JOIN lapsed.laps laps ON laps.id = l.parentid
                  WHERE at.kpv >= kpv_start::DATE
                    AND at.kpv <= kpv_end::DATE
                    AND (a.properties ->> 'tyyp' IS NULL OR a.properties ->> 'tyyp' <> 'ETTEMAKS')
              )

         SELECT period,
                kulastatavus,
                lapse_nimi,
                lapse_isikukood,
                maksja_nimi,
                maksja_isikukood,
                yksus,
                viitenumber,
                (alg_saldo)               AS alg_saldo,
                (arvestatud)              AS arvestatud,
                (soodustus)               AS soodustus,
                (laekumised)              AS laekumised,
                (tagastused)              AS tagastused,
                (coalesce(alg_saldo, 0) + coalesce(arvestatud, 0) - coalesce(laekumised, 0) +
                 coalesce(tagastused, 0)) AS jaak,
                rekvid
         FROM (
                  -- alg.saldo
                  SELECT a.period,
                         'EI'                     AS kulastatavus,
                         a.lapse_nimi             AS lapse_nimi,
                         a.lapse_isikukood        AS lapse_isikukood,
                         a.maksja_nimi,
                         a.maksja_isikukood,
                         a.yksus                  AS yksus,
                         a.viitenumber            AS viitenumber,
                         coalesce(a.alg_saldo, 0) AS alg_saldo,
                         0                        AS arvestatud,
                         0                        AS soodustus,
                         0                        AS laekumised,
                         0                        AS tagastused,
                         0                        AS jaak,
                         a.rekvid                 AS rekvid
                  FROM alg_saldo a
                           INNER JOIN (SELECT laps_id, ltrim(rtrim(yksus)) AS yksus, rekvid
                                       FROM alg_saldo
                                           EXCEPT
                                       SELECT laps_id, ltrim(rtrim(yksus)), rekvid
                                       FROM kaibed) clean_saldo ON
                          a.laps_id = clean_saldo.laps_id AND a.yksus = clean_saldo.yksus AND
                          a.rekvid = clean_saldo.rekvid
                  UNION ALL
                  -- ettemaksud
                  SELECT a.period,
                         'EI'                      AS kulastatavus,
                         a.lapse_nimi              AS lapse_nimi,
                         a.lapse_isikukood         AS lapse_isikukood,
                         a.maksja_nimi,
                         a.maksja_isikukood,
                         a.yksus                   AS yksus,
                         a.viitenumber             AS viitenumber,
                         0                         AS alg_saldo,
                         0                         AS arvestatud,
                         0                         AS soodustus,
                         coalesce(a.laekumised, 0) AS laekumised,
                         0                         AS tagastused,
                         0                         AS jaak,
                         a.rekv_id                 AS rekvid
                  FROM ettemaksud a
                  UNION ALL

                  -- kaibed
                  SELECT k.period,
                         k.kulastatavus,
                         k.lapse_nimi              AS lapse_nimi,
                         k.lapse_isikukood         AS lapse_isikukood,
                         k.maksja_nimi,
                         k.maksja_isikukood,
                         k.yksus                   AS yksus,
                         k.viitenumber             AS viitenumber,
                         (SELECT sum(coalesce(a.alg_saldo, 0))
                          FROM alg_saldo a
                          WHERE a.rekvid = k.rekvid
                            AND a.laps_id = k.laps_id
                            AND a.yksus = k.yksus) AS alg_saldo,
                         COALESCE(k.arvestatud, 0) AS arvestatud,
                         COALESCE(k.soodustus, 0)  AS soodustus,
                         0                         AS laekumised,
                         COALESCE(k.tagastused, 0) AS tagastused,
                         0                         AS jaak,
                         k.rekvid                  AS rekvid
                  FROM kaibed k
              ) qry) report
WHERE alg_saldo <> 0
   OR arvestatud <> 0
   OR soodustus <> 0
   OR laekumised <> 0
   OR tagastused <> 0

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
SELECT *
FROM lapsed.saldo_ja_kaive(69, '2020-09-01', '2020-09-30')
) qry
where  viitenumber   IN ('0690069338', '0690071342','0690066360')

*/
