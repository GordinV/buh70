DROP VIEW IF EXISTS lapsed.cur_vanemad;

CREATE OR REPLACE VIEW lapsed.cur_vanemad AS

SELECT a.id                                      AS vanem_id,
       v.id                                      AS id,
       a.regkood::TEXT                           AS isikukood,
       a.nimetus::TEXT                           AS nimi,
       a.aadress::TEXT,
       a.email::TEXT,
       a.tel::TEXT,
       regexp_replace(btrim(json_agg(l.nimi)::TEXT, '[]'),'["]', '' , 'g')::TEXT AS lapsed,
       array_agg(lk.rekvid)                      AS rekv_ids
FROM lapsed.vanemad v
         INNER JOIN libs.asutus a ON a.id = v.asutusid
         INNER JOIN (
    SELECT l.id, l.nimi
    FROM lapsed.laps l
    WHERE l.staatus <> 3

    GROUP BY l.id, l.nimi
) l ON l.id = v.parentid
         INNER JOIN (SELECT DISTINCT lk.parentid, lk.rekvid FROM lapsed.lapse_kaart lk WHERE lk.staatus <> 3) lk
                    ON lk.parentid = v.parentid
WHERE v.staatus <> 3
GROUP BY a.id, v.id, a.regkood, a.nimetus
ORDER BY a.nimetus;

GRANT SELECT ON TABLE lapsed.cur_vanemad TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_vanemad TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_vanemad TO dbpeakasutaja;


/*

select * from lapsed.cur_vanemad
where rekv_ids @>ARRAY[63]
 */