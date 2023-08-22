DROP VIEW IF EXISTS lapsed.cur_asendus_taabel;

CREATE OR REPLACE VIEW lapsed.cur_asendus_taabel AS

SELECT lt.id,
       lt.parentid,
       lt.rekvid,
       lt.nomid,
       lt.kuu,
       lt.aasta,
       lt.kogus            AS kogus,
       lt.hind             AS hind,
       lt.soodustus        AS soodustus,
       lt.summa            AS summa,
       l.isikukood,
       l.nimi,
       n.kood::TEXT,
       n.nimetus::TEXT     AS teenus,
       n.uhik::TEXT,
       grupp.nimetus::TEXT AS yksus,
       lt.viitenumber      AS viitenumber,
       lt.muud,
       r.nimetus           AS asutus
    FROM
       lapsed.asendus_taabel lt
           INNER JOIN lapsed.laps l ON l.id = lt.parentid
           INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
           INNER JOIN OU.rekv r ON r.id = lt.rekvid
           LEFT OUTER JOIN libs.library grupp
           ON grupp.id = lt.yksusid
    WHERE
       lt.staatus <> 3
           AND n.status <> 3
           AND n.id = lt.nomid
--           AND (lt.hind <> 0 OR lt.soodustus <> 0)
    ORDER BY
       aasta,
       kuu,
       nimi,
       kood;

GRANT SELECT ON TABLE lapsed.cur_asendus_taabel TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_asendus_taabel TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_asendus_taabel TO dbpeakasutaja;

/*

select vahe, * from lapsed.cur_lapse_taabel
where rekvid = 99
and kuu = 1 and aasta = 2022
and parentid = 8021
limit 10
select * from lapsed.laps
 */