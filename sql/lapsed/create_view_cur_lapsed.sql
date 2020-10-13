DROP VIEW IF EXISTS lapsed.cur_lapsed;

CREATE OR REPLACE VIEW lapsed.cur_lapsed AS

SELECT l.id,
       l.isikukood,
       l.nimi,
       l.properties,
       array_to_string(lk.yksused,','::text)::TEXT AS yksused,
       lk.rekv_ids
FROM lapsed.laps l
         JOIN (SELECT parentid, array_agg(rekvid) AS rekv_ids, array_agg(yksused) AS yksused
               FROM (
                        SELECT parentid,
                               rekvid,
                               (get_unique_value_from_json(json_agg((k.properties ->> 'yksus')::TEXT || CASE
                                                                                                            WHEN (k.properties ->> 'all_yksus') IS NOT NULL
                                                                                                                THEN
                                                                                                                    '-' ||
                                                                                                                    (k.properties ->> 'all_yksus')::TEXT
                                                                                                            ELSE '' END)::JSONB)) AS yksused
                        FROM lapsed.lapse_kaart k
                        WHERE k.staatus <> 3
                        GROUP BY parentid, rekvid
                    ) qry
               GROUP BY parentid) lk ON lk.parentid = l.id
WHERE l.staatus <> 3
ORDER BY nimi;

GRANT SELECT ON TABLE lapsed.cur_lapsed TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapsed TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapsed TO dbpeakasutaja;
GRANT SELECT ON TABLE lapsed.cur_lapsed TO dbkasutaja;

/*

select * from lapsed.cur_lapsed
select * from lapsed.laps
 */