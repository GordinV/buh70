DROP VIEW IF EXISTS lapsed.cur_lapse_taabel;

CREATE OR REPLACE VIEW lapsed.cur_lapse_taabel AS

SELECT lt.id,
       lt.parentid,
       lt.rekvid,
       lt.nomid,
       lt.kuu,
       lt.aasta,
       lt.kogus,
       coalesce(lt.hind, lk.hind)::NUMERIC(12, 2) as hind,
       coalesce(n.properties ->> 'tyyp', '')       AS tyyp,
       CASE
           WHEN (n.properties ->> 'tyyp') IS NOT NULL AND (n.properties ->> 'tyyp') = 'SOODUSTUS' THEN lk.hind
           WHEN lk.properties ->> 'soodus' IS NOT NULL THEN coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)
           ELSE 0 END ::NUMERIC                    AS soodustus,
       (lk.properties ->> 'kas_protsent')::BOOLEAN AS kas_protsent,
       CASE
           WHEN (n.properties ->> 'tyyp') IS NOT NULL AND (n.properties ->> 'tyyp') = 'SOODUSTUS' THEN -1
           WHEN (lk.properties ->> 'sooduse_alg')::DATE <= make_date(lt.aasta, lt.kuu, 28)
               AND (lk.properties ->> 'sooduse_lopp')::DATE >=
                   CASE
                       WHEN upper(n.uhik) = ('KUU') THEN make_date(lt.aasta, lt.kuu, 1)
                       WHEN (lk.properties ->> 'sooduse_lopp')::DATE <
                            make_date(lt.aasta, lt.kuu, 1) + INTERVAL '1 month' - INTERVAL '1 day' AND
                            (lk.properties ->> 'lopp_kpv')::DATE = (lk.properties ->> 'sooduse_lopp')::DATE
                           THEN make_date(lt.aasta, lt.kuu, 1)
                       ELSE make_date(lt.aasta, lt.kuu, 1) + INTERVAL '1 month' - INTERVAL '1 day' END
               THEN 1
           ELSE 0 END                              AS sooduse_kehtivus,
       l.isikukood,
       l.nimi,
       n.kood::TEXT,
       n.nimetus::TEXT                             AS teenus,
       n.uhik::TEXT,
       grupp.nimetus::TEXT                         AS yksus,
       lk.properties ->> 'all_yksus'               AS all_yksus,
       lt.lapse_kaart_id,
       (lk.properties ->> 'sooduse_alg')::DATE     AS sooduse_alg,
       (lk.properties ->> 'sooduse_lopp')::DATE    AS sooduse_lopp

FROM lapsed.lapse_taabel lt
         INNER JOIN lapsed.laps l ON l.id = lt.parentid
         INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
         INNER JOIN lapsed.lapse_kaart lk ON lk.id = lt.lapse_kaart_id
         INNER JOIN libs.library grupp
                    ON grupp.library::TEXT = 'LAPSE_GRUPP'::TEXT AND grupp.rekvid = lk.rekvid AND grupp.status <> 3
                        AND grupp.kood::TEXT = (lk.properties ->> 'yksus')::TEXT
WHERE lt.staatus <> 3
  AND lt.kogus <> 0
  AND n.status <> 3
ORDER BY aasta, kuu, nimi, kood;

GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO dbpeakasutaja;

/*

select * from lapsed.cur_lapsed
select * from lapsed.laps
 */