DROP VIEW IF EXISTS lapsed.cur_lapsed;

CREATE OR REPLACE VIEW lapsed.cur_lapsed AS

SELECT l.id,
       l.isikukood,
       l.nimi,
       l.properties,
       btrim(lk.yksused::TEXT, '[]')::TEXT AS yksused,
       lk.rekv_ids
FROM lapsed.laps l
         JOIN (SELECT parentid,
                      regexp_replace(json_agg((k.properties ->> 'yksus')::TEXT || case when (k.properties ->> 'all_yksus') is not null then '-' ||
                                              (k.properties ->> 'all_yksus')::TEXT else '' end )::text, '"', '', 'g') AS yksused,
                      array_agg(rekvid)                                                             AS rekv_ids
               FROM lapsed.lapse_kaart k
               WHERE k.staatus <> 3
               GROUP BY parentid
) lk ON lk.parentid = l.id
WHERE l.staatus <> 3
ORDER BY nimi;

GRANT SELECT ON TABLE lapsed.cur_lapsed TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapsed TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapsed TO dbpeakasutaja;

/*

select * from lapsed.cur_lapsed
select * from lapsed.laps
 */