DROP VIEW IF EXISTS lapsed.cur_teenused;
DROP VIEW IF EXISTS lapsed.cur_lapse_kaart;

CREATE OR REPLACE VIEW lapsed.cur_lapse_kaart AS

SELECT l.id                                                                          AS lapsid,
       lk.id,
       l.isikukood,
       l.nimi,
       lk.rekvid,
       lk.hind,
       lk.properties ->> 'yksus'                                                     AS yksus,
       lk.properties ->> 'all_yksus'                                                 AS all_yksus,
       n.kood::TEXT,
       n.nimetus::TEXT,
       n.uhik::TEXT,
       coalesce((lk.properties ->> 'alg_kpv')::DATE, date(year(), 1, 1))             AS alg_kpv,
       coalesce((lk.properties ->> 'lopp_kpv')::DATE, date(year(), 12, 31))          AS lopp_kpv,
       coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)::NUMERIC                   AS soodustus,
       CASE WHEN (lk.properties ->> 'kas_protsent')::BOOLEAN THEN '%' ELSE 'EUR' END AS kas_protsent,
       CASE
           WHEN ((lk.properties ->> 'sooduse_alg')::DATE > current_date OR
                 (lk.properties ->> 'sooduse_lopp')::DATE < current_date) THEN 'ei kehti'
           ELSE 'kehtiv' END                                                         AS sooduse_kehtivus,
       CASE WHEN (lk.properties ->> 'kas_inf3')::BOOLEAN THEN 'INF3' ELSE '' END     AS inf3

FROM lapsed.laps l
         INNER JOIN lapsed.lapse_kaart lk ON lk.parentid = l.id
         INNER JOIN libs.nomenklatuur n ON lk.nomid = n.id
WHERE lk.staatus <> 3;

GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO dbpeakasutaja;


SELECT *
FROM lapsed.cur_lapse_kaart;
/*

select * from lapsed.cur_lapsed
select * from lapsed.laps

    doc_soodus           NUMERIC = doc_data ->> 'soodus';
    doc_kas_protsent     BOOLEAN = doc_data ->> 'kas_protsent';

 */