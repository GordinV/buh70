DROP VIEW IF EXISTS lapsed.cur_teenused;
DROP VIEW IF EXISTS lapsed.cur_lapse_kaart;

CREATE OR REPLACE VIEW lapsed.cur_lapse_kaart AS

SELECT l.id                                                                      AS lapsid,
       lk.id,
       l.isikukood,
       l.nimi,
       lk.rekvid,
       lk.hind,
       grupp.kood::TEXT                                                          AS yksuse_kood,
       grupp.nimetus::TEXT                                                       AS yksus,
       lk.properties ->> 'all_yksus'                                             AS all_yksus,
       n.kood::TEXT,
       n.nimetus::TEXT,
       n.uhik::TEXT,
       coalesce((lk.properties ->> 'alg_kpv')::DATE, date(year(), 1, 1))         AS alg_kpv,
       coalesce((lk.properties ->> 'lopp_kpv')::DATE, date(year(), 12, 31))      AS lopp_kpv,
       coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)::NUMERIC               AS soodustus,
       CASE
           WHEN (lk.properties ->> 'kas_protsent')::BOOLEAN THEN '%'
           ELSE 'EUR' END                                                        AS kas_protsent,
       CASE
           WHEN ((lk.properties ->> 'sooduse_alg')::DATE > current_date OR
                 (lk.properties ->> 'sooduse_lopp')::DATE < current_date) THEN 'ei kehti'
           ELSE 'kehtiv' END                                                     AS sooduse_kehtivus,
       CASE WHEN (lk.properties ->> 'kas_inf3')::BOOLEAN THEN 'INF3' ELSE '' END AS inf3,
       (lk.properties ->> 'kas_ettemaks')::BOOLEAN                               AS kas_ettemaks,
       coalesce((lk.properties ->> 'kogus')::NUMERIC, 0)::NUMERIC                AS kogus,
       coalesce(lk.tunnus, '')::TEXT                                             AS tunnus,
       lk.properties ->> 'ettemaksu_period'                                      AS ettemaksu_period,
       (lk.properties ->> 'kas_eraldi')::BOOLEAN                                 AS kas_eraldi,
       (lk.properties ->> 'sooduse_alg')::DATE                                   AS sooduse_alg,
       (lk.properties ->> 'sooduse_lopp')::DATE                                  AS sooduse_lopp,
       r.nimetus::TEXT                                                           AS asutus,
       v.viitenumber                                                             AS vana_viitenumber

FROM lapsed.laps l
         INNER JOIN lapsed.lapse_kaart lk ON lk.parentid = l.id
         INNER JOIN libs.nomenklatuur n ON lk.nomid = n.id
         INNER JOIN libs.library grupp ON grupp.library::TEXT = 'LAPSE_GRUPP'::TEXT
    AND grupp.rekvid = lk.rekvid
    AND grupp.status <> 3
    AND grupp.kood::TEXT = (lk.properties ->> 'yksus')::TEXT
         INNER JOIN ou.rekv r ON r.id = lk.rekvid
         LEFT OUTER JOIN lapsed.viitenr v ON v.rekv_id = r.id AND v.isikukood = l.isikukood
WHERE lk.staatus <> 3;

GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO dbpeakasutaja;


SELECT *
FROM lapsed.cur_lapse_kaart
WHERE kas_ettemaks
LIMIT 10;

/*

select * from lapsed.cur_lapsed
select * from lapsed.laps

    doc_soodus           NUMERIC = doc_data ->> 'soodus';
    doc_kas_protsent     BOOLEAN = doc_data ->> 'kas_protsent';

select * from ou.rekv where id = 77
 */