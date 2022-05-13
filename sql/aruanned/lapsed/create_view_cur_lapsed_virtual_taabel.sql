DROP VIEW IF EXISTS lapsed.cur_lapse_virtuaal_taabel;

CREATE OR REPLACE VIEW lapsed.cur_lapse_virtuaal_taabel AS
    WITH min_max AS (
        SELECT min(CASE
                       WHEN (lk.properties ->> 'alg_kpv')::DATE < '2020-09-01' THEN '2020-09-01'
                       ELSE coalesce((lk.properties ->> 'alg_kpv')::DATE, current_date) END)  AS alg_kpv,
               max(CASE
                       WHEN (lk.properties ->> 'lopp_kpv')::DATE > (current_date + INTERVAL '1 month')
                           THEN (current_date + INTERVAL '1 month')
                       ELSE coalesce((lk.properties ->> 'lopp_kpv')::DATE, current_date) END) AS lopp_kpv,
               lk.rekvid
        FROM lapsed.lapse_kaart lk
        WHERE lk.staatus <> 3
          AND (lk.properties ->> 'kas_ettemaks')::BOOLEAN
        GROUP BY lk.rekvid
    ),
         periods AS (
             SELECT period.kuu, period.aasta, min_max.rekvid
             FROM min_max,
                  get_month_year_between_dates(min_max.alg_kpv::date, min_max.lopp_kpv::date) AS period
         ),

         prev_lk AS (
             SELECT 1000000 + row_number() OVER ()              AS id,
                    lk.parentid,
                    lk.rekvid,
                    lk.nomid,
                    p.kuu,
                    p.aasta,
                    1                                           AS kogus,
                    lk.hind,
                    'Ei'                                        AS umberarvestus,
                    CASE
                        WHEN (n.properties ->> 'tyyp') IS NOT NULL AND (n.properties ->> 'tyyp') = 'SOODUSTUS'
                            THEN lk.hind
                        WHEN lk.properties ->> 'soodus' IS NOT NULL
                            THEN coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)
                        ELSE 0 END ::NUMERIC                    AS soodustus,
                    (lk.properties ->> 'kas_protsent')::BOOLEAN AS kas_protsent,
                    CASE
                        WHEN (n.properties ->> 'tyyp') IS NOT NULL AND (n.properties ->> 'tyyp') = 'SOODUSTUS' THEN -1
                        WHEN (lk.properties ->> 'sooduse_alg')::DATE <
                             (make_date(p.aasta, p.kuu, 1) + INTERVAL '1 month')
                            AND (lk.properties ->> 'sooduse_lopp')::DATE >=
                                CASE
                                    WHEN upper(n.uhik) = ('KUU') THEN make_date(p.aasta, p.kuu, 1)
                                    WHEN (lk.properties ->> 'sooduse_lopp')::DATE <
                                         make_date(p.aasta, p.kuu, 1) + INTERVAL '1 month' - INTERVAL '1 day' AND
                                         (lk.properties ->> 'lopp_kpv')::DATE = (lk.properties ->> 'sooduse_lopp')::DATE
                                        THEN make_date(p.aasta, p.kuu, 1)
                                    ELSE make_date(p.aasta, p.kuu, 1) + INTERVAL '1 month' - INTERVAL '1 day' END
                            THEN 1
                        ELSE 0 END                              AS sooduse_kehtivus,
                    l.isikukood,
                    l.nimi,
                    n.kood::TEXT,
                    n.nimetus::TEXT                             AS teenus,
                    n.uhik::TEXT,
                    grupp.nimetus::TEXT                         AS yksus,
                    lk.properties ->> 'all_yksus'               AS all_yksus,
                    lk.id                                       AS lapse_kaart_id,
                    (lk.properties ->> 'sooduse_alg')::DATE     AS sooduse_alg,
                    (lk.properties ->> 'sooduse_lopp')::DATE    AS sooduse_lopp,
                    (n.properties ->> 'kas_inf3')::BOOLEAN      AS kas_inf3
             FROM lapsed.lapse_kaart lk
                      INNER JOIN periods p ON p.rekvid = lk.rekvid
                      INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid AND n.status <> 3
                      INNER JOIN libs.library grupp
                                 ON grupp.library::TEXT = 'LAPSE_GRUPP'::TEXT AND grupp.rekvid = lk.rekvid AND
                                    grupp.status <> 3
                                     AND grupp.kood::TEXT = (lk.properties ->> 'yksus')::TEXT
                      INNER JOIN lapsed.laps l ON l.id = lk.parentid
             WHERE lk.staatus <> 3
               AND ((lk.properties -> 'kas_ettemaks') = 'true')
               AND make_date(p.aasta, p.kuu, 01) BETWEEN
                 (CASE
                      WHEN (lk.properties ->> 'alg_kpv')::DATE < '2020-09-01' THEN '2020-09-01'::DATE -- не ранее 01.09.2020 года
                      ELSE (lk.properties ->> 'alg_kpv')::DATE END)
                 AND (lk.properties ->> 'lopp_kpv')::DATE
         )
    SELECT *
    FROM prev_lk
    ORDER BY aasta, kuu, nimi, kood;
;
GRANT SELECT ON TABLE lapsed.cur_lapse_virtuaal_taabel TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_virtuaal_taabel TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_virtuaal_taabel TO dbpeakasutaja;


/*
 explain
 select * from lapsed.cur_lapse_virtuaal_taabel
 where rekvid = 69
 -- 98
 limit 10
 */