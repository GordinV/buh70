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
         SELECT kpv_start                                          AS period,
                CASE
                    WHEN kulastavus.lopp_kpv >= kpv_end THEN 'Jah'
                    ELSE 'Ei' END::TEXT                            AS kulastatavus,
                l.nimi::TEXT                                       AS lapse_nimi,
                l.isikukood::TEXT                                  AS lapse_isikukood,
                i.nimetus::TEXT                                    AS maksja_nimi,
                i.regkood::TEXT                                    AS maksja_isikukood,
                array_to_string(a1.yksus, ',', '')::TEXT           AS yksus,
                a.number::TEXT                                     AS number,
                lapsed.get_viitenumber(d.rekvid, l.id)::TEXT       AS viitenumber,
                coalesce(alg_saldo.jaak::NUMERIC(14, 2), 0)::NUMERIC(14, 2)
                                                                   AS alg_saldo,
                CASE
                    WHEN (a.properties ->> 'tyyp') IS NULL AND a.kpv >= kpv_start THEN a.summa::NUMERIC(14, 2)
                    ELSE 0 END                                     AS arvestatud,
                coalesce(a1.soodustus, 0)::NUMERIC(14, 2)          AS soodustus,
                coalesce(laekumised.laekumised, 0)::NUMERIC(14, 2) AS laekumised,
                coalesce(laekumised.tagastus, 0)::NUMERIC(14, 2)   AS tagastused,
                a.jaak::NUMERIC(14, 2)                             AS jaak,
                d.rekvid::INTEGER                                  AS rekvid
         FROM docs.doc d
                  INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
                  INNER JOIN lapsed.laps l ON l.id = ld.parentid
                  INNER JOIN docs.arv a ON a.parentid = d.id
                  INNER JOIN libs.asutus i ON i.id = a.asutusid
                  INNER JOIN (SELECT parentid                             AS arv_id,
                                     sum(soodus)                          AS soodustus,
                                     array_agg(a1.properties ->> 'yksus') AS yksus
                              FROM docs.arv1 a1
                              GROUP BY parentid) a1
                             ON a1.arv_id = a.id
                  LEFT OUTER JOIN (SELECT jaak, laps_id, rekv_id
                                   FROM lapsed.lapse_saldod(kpv_start::DATE)) alg_saldo
                                  ON alg_saldo.laps_id = l.id AND alg_saldo.rekv_id = d.rekvid
                  LEFT OUTER JOIN (SELECT at.doc_arv_id                         AS arv_id,
                                          sum(summa) FILTER ( WHERE summa < 0 ) AS tagastus,
                                          sum(summa) FILTER ( WHERE summa > 0 ) AS laekumised,
                                          sum(summa)                            AS summa
                                   FROM docs.arvtasu at
                                   WHERE at.kpv >= kpv_start
                                     AND at.kpv <= kpv_end
                                   GROUP BY at.doc_arv_id) laekumised ON laekumised.arv_id = d.id
                  LEFT OUTER JOIN (SELECT parentid, rekvid, min(alg_kpv) AS alg_kpv, max(lopp_kpv) AS lopp_kpv
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
           AND (a.kpv >= kpv_start AND a.kpv <= kpv_end OR a.jaak > 0 OR a.tasud IS NULL OR a.tasud >= kpv_end)
         UNION ALL
-- Kui arved ei ole (alg.saldo)
         SELECT coalesce(kpv_start, kpv_end)::DATE                    AS period,
                CASE
                    WHEN kulastavus.lopp_kpv >= kpv_end THEN 'Jah'
                    ELSE 'Ei' END::TEXT                               AS kulastatavus,
                l.nimi::TEXT                                          AS lapse_nimi,
                l.isikukood::TEXT                                     AS lapse_isikukood,
                NULL::TEXT                                            AS maksja_nimi,
                NULL::TEXT                                            AS maksja_isikukood,
                kulastavus.yksus::TEXT                                AS yksus,
                NULL::TEXT                                            AS number,
                lapsed.get_viitenumber(alg_saldo.rekv_id, l.id)::TEXT AS viitenumber,
                alg_saldo.jaak::NUMERIC(14, 2)                        AS alg_saldo,
                0                                                     AS arvestatud,
                0::NUMERIC(14, 2)                                     AS soodustus,
                0::NUMERIC(14, 2)                                     AS laekumised,
                0::NUMERIC(14, 2)                                     AS tagastused,
                alg_saldo.jaak::NUMERIC(14, 2)                        AS jaak,
                alg_saldo.rekv_id::INTEGER                            AS rekvid
         FROM lapsed.lapse_saldod(coalesce(kpv_start, kpv_end)::DATE) alg_saldo
                  INNER JOIN lapsed.laps l ON l.id = alg_saldo.laps_id
                  LEFT OUTER JOIN (SELECT parentid,
                                          rekvid,
                                          regexp_replace(array_agg(yksus)::TEXT, '[{}]', '', 'g') AS yksus,
                                          min(alg_kpv)                                            AS alg_kpv,
                                          max(lopp_kpv)                                           AS lopp_kpv
                                   FROM (
                                            SELECT parentid,
                                                   rekvid,
                                                   coalesce((lk.properties ->> 'alg_kpv')::DATE,
                                                            date(year(current_date), 1, 1))::DATE   AS alg_kpv,
                                                   coalesce((lk.properties ->> 'lopp_kpv')::DATE,
                                                            date(year(current_date), 12, 31))::DATE AS lopp_kpv,
                                                   lk.properties ->> 'yksus'::TEXT                  AS yksus
                                            FROM lapsed.lapse_kaart lk
                                            WHERE lk.staatus <> 3
                                        ) qry
                                   GROUP BY parentid,
                                            rekvid) kulastavus
                                  ON kulastavus.parentid = l.id AND kulastavus.rekvid = alg_saldo.rekv_id
         WHERE alg_saldo.rekv_id IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
           AND NOT exists(SELECT a.id
                          FROM docs.arv a
                                   INNER JOIN lapsed.liidestamine l
                                              ON l.docid = a.parentid AND l.parentid = alg_saldo.laps_id AND
                                                 a.rekvid = alg_saldo.rekv_id)
     ) qry
GROUP BY period,
         kulastatavus,
         lapse_nimi,
         lapse_isikukood,
         maksja_nimi,
         maksja_isikukood,
         yksus,
         viitenumber, rekvid
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
FROM lapsed.saldo_ja_kaive(88, null, '2020-04-30')
) qry
where  period  >=  '2019-11-01' and period  <=  '2019-12-31'

*/
