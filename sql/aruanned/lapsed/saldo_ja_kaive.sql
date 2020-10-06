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
       kulastatavus,
       lapse_nimi,
       lapse_isikukood,
       maksja_nimi,
       maksja_isikukood,
       yksus,
       viitenumber,
       alg_saldo,
       arvestatud,
       soodustus,
       laekumised,
       tagastused,
       jaak,
       rekvid
FROM (
         WITH alg_saldo AS (
             -- alg_saldo
             SELECT coalesce(alg_saldo.yksus, '')::TEXT                         AS yksus,
                    coalesce(alg_saldo.jaak::NUMERIC(14, 2), 0)::NUMERIC(14, 2) AS alg_saldo,
                    alg_saldo.rekv_id::INTEGER                                  AS rekvid,
                    l.id                                                        AS laps_id,
                    l.isikukood                                                 AS lapse_isikukood,
                    l.nimi                                                      AS lapse_nimi,
                    lapsed.get_viitenumber(alg_saldo.rekv_id, l.id)::TEXT       AS viitenumber
             FROM lapsed.laps l
                      LEFT OUTER JOIN (SELECT jaak, laps_id, rekv_id, yksus
                                       FROM lapsed.lapse_saldod(kpv_start::DATE)) alg_saldo
                                      ON alg_saldo.laps_id = l.id
             WHERE alg_saldo.rekv_id IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
         ),
              kaibed AS (
                  SELECT l.id                                               AS laps_id,
                         kpv_start                                          AS period,
                         CASE
                             WHEN kulastavus.lopp_kpv >= kpv_end THEN 'Jah'
                             ELSE 'Ei' END::TEXT                            AS kulastatavus,
                         l.nimi::TEXT                                       AS lapse_nimi,
                         l.isikukood::TEXT                                  AS lapse_isikukood,
                         i.nimetus::TEXT                                    AS maksja_nimi,
                         i.regkood::TEXT                                    AS maksja_isikukood,
                         coalesce(a1.yksus, '')::TEXT                       AS yksus,
                         lapsed.get_viitenumber(d.rekvid, l.id)::TEXT       AS viitenumber,
                         CASE
                             WHEN ((a.properties ->> 'tyyp') IS NULL OR empty(a.properties ->> 'tyyp'))
                                 AND a.kpv >= kpv_start
                                 AND a.kpv <= kpv_end
                                 THEN a1.summa::NUMERIC(14, 2)
                             ELSE 0 END                                     AS arvestatud,
                         coalesce(a1.soodustus, 0)::NUMERIC(14, 2)          AS soodustus,
                         coalesce(laekumised.laekumised, 0)::NUMERIC(14, 2) AS laekumised,
                         coalesce(laekumised.tagastus, 0)::NUMERIC(14, 2)   AS tagastused,
                         d.rekvid::INTEGER                                  AS rekvid
                  FROM docs.doc d
                           INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                           INNER JOIN lapsed.laps l ON l.id = ld.parentid
                           INNER JOIN docs.arv a ON a.parentid = d.id
                           INNER JOIN libs.asutus i ON i.id = a.asutusid
                           INNER JOIN (SELECT parentid                    AS arv_id,
                                              sum(soodus)                 AS soodustus,
--                                     array_agg(a1.properties ->> 'yksus') AS yksus
                                              (a1.properties ->> 'yksus') AS yksus,
                                              sum(summa)                  AS summa
                                       FROM docs.arv1 a1
                                       GROUP BY parentid, a1.properties ->> 'yksus') a1
                                      ON a1.arv_id = a.id
                           LEFT OUTER JOIN (SELECT jaak, laps_id, rekv_id, yksus
                                            FROM lapsed.lapse_saldod(kpv_start::DATE)) alg_saldo
                                           ON alg_saldo.laps_id = l.id
                                               AND alg_saldo.rekv_id = d.rekvid
                                               AND alg_saldo.yksus = a1.yksus
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
                      GROUP BY at.doc_arv_id, (a1.properties ->> 'yksus')) laekumised
                                           ON laekumised.arv_id = d.id
                                               AND laekumised.yksus = a1.yksus
                           LEFT OUTER JOIN (SELECT parentid,
                                                   rekvid,
                                                   min(alg_kpv)  AS alg_kpv,
                                                   max(lopp_kpv) AS lopp_kpv
                                            FROM (
                                                     SELECT parentid,
                                                            rekvid,
                                                            coalesce((lk.properties ->> 'alg_kpv')::DATE,
                                                                     date(year(current_date), 1, 1))::DATE   AS alg_kpv,
                                                            coalesce((lk.properties ->> 'lopp_kpv')::DATE,
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
                    AND (a.kpv >= kpv_start AND a.kpv <= kpv_end OR a.jaak <> 0 OR a.tasud IS NULL OR
                         a.tasud >= kpv_end)
              )

         SELECT period,
                kulastatavus,
                lapse_nimi,
                lapse_isikukood,
                maksja_nimi,
                maksja_isikukood,
                yksus,
                viitenumber,
                sum(alg_saldo)  AS alg_saldo,
                sum(arvestatud) AS arvestatud,
                sum(soodustus)  AS soodustus,
                sum(laekumised) AS laekumised,
                sum(tagastused) AS tagastused,
                sum(jaak)       AS jaak,
                rekvid
         FROM (
                  SELECT k.period,
                         k.kulastatavus,
                         coalesce(k.lapse_nimi, a.lapse_nimi)           AS lapse_nimi,
                         coalesce(k.lapse_isikukood, a.lapse_isikukood) AS lapse_isikukood,
                         k.maksja_nimi,
                         k.maksja_isikukood,
                         coalesce(k.yksus, a.yksus)                     AS yksus,
                         coalesce(k.viitenumber, a.viitenumber)         AS viitenumber,
                         coalesce(a.alg_saldo, 0)                       AS alg_saldo,
                         coalesce(k.arvestatud, 0)                      AS arvestatud,
                         coalesce(k.soodustus, 0)                       AS soodustus,
                         coalesce(k.laekumised, 0)                      AS laekumised,
                         coalesce(k.tagastused, 0)                      AS tagastused,
                         coalesce(a.alg_saldo, 0) + coalesce(k.arvestatud, 0) - coalesce(k.laekumised, 0) +
                         coalesce(k.tagastused, 0)                      AS jaak,
                         coalesce(k.rekvid, a.rekvid)                   AS rekvid
                  FROM kaibed k
                           FULL JOIN alg_saldo a
                                     ON a.laps_id = k.laps_id AND k.rekvid = a.rekvid AND k.yksus = a.yksus
              ) qry
         GROUP BY period,
                  kulastatavus,
                  lapse_nimi,
                  lapse_isikukood,
                  maksja_nimi,
                  maksja_isikukood,
                  yksus,
                  viitenumber, rekvid
     ) report
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
where  viitenumber  = '0690068313'

*/
