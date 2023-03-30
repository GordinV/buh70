DROP VIEW IF EXISTS lapsed.cur_vanemad;

CREATE OR REPLACE VIEW lapsed.cur_vanemad AS

SELECT a.id                                                                AS vanem_id,
       v.id                                                                AS id,
       a.regkood::TEXT                                                     AS isikukood,
       a.nimetus::TEXT                                                     AS nimi,
       a.aadress::TEXT,
       a.email::TEXT,
       a.tel::TEXT,
       array_to_string(get_unique_value_from_array(array_agg(l.nimi)), '') AS lapsed,
       lk.rekvid                                                           AS rekv_id,
       array_to_string(get_unique_value_from_array(
                               array_agg(
                                       CASE
                                           WHEN NOT coalesce(va.arveldus::BOOLEAN, FALSE) THEN ''
                                           ELSE (
                                                               CASE
                                                                   WHEN (v.properties ->> 'kas_email')::BOOLEAN
                                                                       THEN 'email;'
                                                                   ELSE '' END ||
                                                               CASE
                                                                   WHEN (v.properties ->> 'kas_paberil')::BOOLEAN
                                                                       THEN 'paber;'
                                                                   ELSE '' END ||
                                                               CASE
                                                                   WHEN (va.properties ->> 'kas_earve')::BOOLEAN AND
                                                                        empty(va.properties ->> 'pank')
                                                                       THEN 'e-arve;'
                                                                   ELSE '' END ||
                                                               CASE
                                                                   WHEN (va.properties ->> 'kas_earve')::BOOLEAN AND
                                                                        NOT empty(va.properties ->> 'pank') AND
                                                                        (va.properties ->> 'pank') = 'SEB' THEN 'SEB;'
                                                                   ELSE '' END ||
                                                               CASE
                                                                   WHEN (va.properties ->> 'kas_earve')::BOOLEAN AND
                                                                        NOT empty(va.properties ->> 'pank') AND
                                                                        (va.properties ->> 'pank') = 'SWED' THEN 'SWED;'
                                                                   ELSE '' END) END)
                           ), '')::TEXT
                                                                           AS printimine
FROM lapsed.vanemad v
         INNER JOIN libs.asutus a ON a.id = v.asutusid
         INNER JOIN (
    SELECT l.id, l.nimi
    FROM lapsed.laps l
    WHERE l.staatus <> 3
    GROUP BY l.id, l.nimi
) l ON l.id = v.parentid
         INNER JOIN (SELECT DISTINCT lk.parentid, lk.rekvid
                     FROM lapsed.lapse_kaart lk
                     WHERE lk.staatus <> 3
                       AND date_part('year', (lk.properties ->> 'lopp_kpv')::DATE) >= date_part('year', current_date)
) lk
                    ON lk.parentid = v.parentid
         LEFT OUTER JOIN lapsed.vanem_arveldus va ON va.parentid = l.id
    AND va.asutusid = v.asutusid
    AND va.rekvid = lk.rekvid

WHERE v.staatus <> 3
GROUP BY a.id, v.id, a.regkood, a.nimetus, lk.rekvid
ORDER BY a.nimetus;

GRANT SELECT ON TABLE lapsed.cur_vanemad TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_vanemad TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_vanemad TO dbpeakasutaja;

SELECT *
FROM lapsed.cur_vanemad
WHERE isikukood = '39010040086'
ORDER BY id DESC
LIMIT 100
/*

select * from lapsed.cur_vanemad
where isikukood like '3830411%'
rekv_ids @>ARRAY[63]

select * from lapsed.vanemad where id = 2894

select * from ou.rekv where id = 97
 */