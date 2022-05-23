DROP VIEW IF EXISTS lapsed.cur_lapse_virtuaal_taabel;


CREATE VIEW lapsed.cur_lapse_virtuaal_taabel(id, parentid, rekvid, nomid, kuu, aasta, kogus, hind, umberarvestus,
                                             soodustus, kas_protsent, sooduse_kehtivus, isikukood, nimi, kood, teenus,
                                             uhik, yksus, all_yksus, lapse_kaart_id, sooduse_alg, sooduse_lopp,
                                             kas_inf3) AS
    WITH min_max AS (
        SELECT min(
                       CASE
                           WHEN (((lk.properties ->> 'alg_kpv'::TEXT))::DATE < '2020-09-01'::DATE) THEN '2020-09-01'::DATE
                           ELSE COALESCE(((lk.properties ->> 'alg_kpv'::TEXT))::DATE, CURRENT_DATE)
                           END) AS alg_kpv,
               max(
                       CASE
                           WHEN (((lk.properties ->> 'lopp_kpv'::TEXT))::DATE > (CURRENT_DATE + '1 mon'::INTERVAL))
                               THEN (CURRENT_DATE + '1 mon'::INTERVAL)
                           ELSE (COALESCE(((lk.properties ->> 'lopp_kpv'::TEXT))::DATE,
                                          CURRENT_DATE))::TIMESTAMP WITHOUT TIME ZONE
                           END) AS lopp_kpv,
               lk.rekvid
        FROM lapsed.lapse_kaart lk
        WHERE ((lk.staatus <> 3) AND ((lk.properties ->> 'kas_ettemaks'::TEXT))::BOOLEAN)
        GROUP BY lk.rekvid
    ),
         periods AS (
             SELECT period.kuu,
                    period.aasta,
                    min_max.rekvid
             FROM min_max,
                  LATERAL get_month_year_between_dates(min_max.alg_kpv, (min_max.lopp_kpv)::DATE) period(kuu, aasta)
         ),
         prev_lk AS (
             SELECT (1000000 + row_number() OVER ())                    AS id,
                    lk.parentid,
                    lk.rekvid,
                    lk.nomid,
                    p.kuu,
                    p.aasta,
                    1                                                   AS kogus,
                    lk.hind,
                    'Ei'::TEXT                                          AS umberarvestus,
                    CASE
                        WHEN (((n.properties ->> 'tyyp'::TEXT) IS NOT NULL) AND
                              ((n.properties ->> 'tyyp'::TEXT) = 'SOODUSTUS'::TEXT)) THEN lk.hind
                        WHEN ((lk.properties ->> 'soodus'::TEXT) IS NOT NULL) THEN COALESCE(
                                ((lk.properties ->> 'soodus'::TEXT))::NUMERIC, (0)::NUMERIC)
                        ELSE (0)::NUMERIC
                        END                                             AS soodustus,
                    ((lk.properties ->> 'kas_protsent'::TEXT))::BOOLEAN AS kas_protsent,
                    CASE
                        WHEN (((n.properties ->> 'tyyp'::TEXT) IS NOT NULL) AND
                              ((n.properties ->> 'tyyp'::TEXT) = 'SOODUSTUS'::TEXT)) THEN '-1'::INTEGER
                        WHEN ((((lk.properties ->> 'sooduse_alg'::TEXT))::DATE <
                               (make_date(p.aasta, p.kuu, 1) + '1 mon'::INTERVAL)) AND
                              (((lk.properties ->> 'sooduse_lopp'::TEXT))::DATE >=
                               CASE
                                   WHEN (upper((n.uhik)::TEXT) = 'KUU'::TEXT)
                                       THEN (make_date(p.aasta, p.kuu, 1))::TIMESTAMP WITHOUT TIME ZONE
                                   WHEN ((((lk.properties ->> 'sooduse_lopp'::TEXT))::DATE <
                                          ((make_date(p.aasta, p.kuu, 1) + '1 mon'::INTERVAL) - '1 day'::INTERVAL)) AND
                                         (((lk.properties ->> 'lopp_kpv'::TEXT))::DATE =
                                          ((lk.properties ->> 'sooduse_lopp'::TEXT))::DATE))
                                       THEN (make_date(p.aasta, p.kuu, 1))::TIMESTAMP WITHOUT TIME ZONE
                                   ELSE ((make_date(p.aasta, p.kuu, 1) + '1 mon'::INTERVAL) - '1 day'::INTERVAL)
                                   END)) THEN 1
                        ELSE 0
                        END                                             AS sooduse_kehtivus,
                    l.isikukood,
                    l.nimi,
                    (n.kood)::TEXT                                      AS kood,
                    (n.nimetus)::TEXT                                   AS teenus,
                    (n.uhik)::TEXT                                      AS uhik,
                    (grupp.nimetus)::TEXT                               AS yksus,
                    (lk.properties ->> 'all_yksus'::TEXT)               AS all_yksus,
                    lk.id                                               AS lapse_kaart_id,
                    ((lk.properties ->> 'sooduse_alg'::TEXT))::DATE     AS sooduse_alg,
                    ((lk.properties ->> 'sooduse_lopp'::TEXT))::DATE    AS sooduse_lopp,
                    ((n.properties ->> 'kas_inf3'::TEXT))::BOOLEAN      AS kas_inf3,
                    (lk.properties ->> 'viitenr')::TEXT                 AS viitenr
             FROM ((((lapsed.lapse_kaart lk
                 JOIN periods p ON ((p.rekvid = lk.rekvid)))
                 JOIN libs.nomenklatuur n ON (((n.id = lk.nomid) AND (n.status <> 3))))
                 JOIN libs.library grupp ON ((((grupp.library)::TEXT = 'LAPSE_GRUPP'::TEXT) AND
                                              (grupp.rekvid = lk.rekvid) AND (grupp.status <> 3) AND
                                              ((grupp.kood)::TEXT = (lk.properties ->> 'yksus'::TEXT)))))
                      JOIN lapsed.laps l ON ((l.id = lk.parentid)))
             WHERE ((lk.staatus <> 3) AND ((lk.properties -> 'kas_ettemaks'::TEXT) = 'true'::JSONB) AND
                    ((make_date(p.aasta, p.kuu, 1) >=
                      CASE
                          WHEN (((lk.properties ->> 'alg_kpv'::TEXT))::DATE < '2020-09-01'::DATE) THEN '2020-09-01'::DATE
                          ELSE ((lk.properties ->> 'alg_kpv'::TEXT))::DATE
                          END) AND (make_date(p.aasta, p.kuu, 1) <= ((lk.properties ->> 'lopp_kpv'::TEXT))::DATE)))
         )
    SELECT prev_lk.id,
           prev_lk.parentid,
           prev_lk.rekvid,
           prev_lk.nomid,
           prev_lk.kuu,
           prev_lk.aasta,
           prev_lk.kogus,
           prev_lk.hind,
           prev_lk.umberarvestus,
           prev_lk.soodustus,
           prev_lk.kas_protsent,
           prev_lk.sooduse_kehtivus,
           prev_lk.isikukood,
           prev_lk.nimi,
           prev_lk.kood,
           prev_lk.teenus,
           prev_lk.uhik,
           prev_lk.yksus,
           prev_lk.all_yksus,
           prev_lk.lapse_kaart_id,
           prev_lk.sooduse_alg,
           prev_lk.sooduse_lopp,
           prev_lk.kas_inf3,
           prev_lk.viitenr
    FROM prev_lk
    ORDER BY prev_lk.aasta, prev_lk.kuu, prev_lk.nimi, prev_lk.kood;

GRANT SELECT ON TABLE lapsed.cur_lapse_virtuaal_taabel TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_virtuaal_taabel TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_virtuaal_taabel TO dbpeakasutaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_virtuaal_taabel TO dbkasutaja;

