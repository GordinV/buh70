DROP VIEW IF EXISTS lapsed.cur_laste_arved;

CREATE OR REPLACE VIEW lapsed.cur_laste_arved AS
SELECT d.id                                                                                   AS id,
       d.docs_ids,
       trim(a.number)                                                                         AS number,
       a.rekvid,
       a.kpv                                                                                  AS kpv,
       round(a.summa, 2)                                                                      AS summa,
       a.tahtaeg                                                                              AS tahtaeg,
       round(a.jaak, 2)                                                                       AS jaak,
       a.tasud :: DATE                                                                        AS tasud,
       a.tasudok,
       a.userid,
       a.asutusid,
       a.journalid,
       a.lisa,
       trim(asutus.nimetus)                                                                   AS asutus,
       trim(asutus.regkood)                                                                   AS vanem_isikukood,
       jid.number                                                                             AS lausnr,
       a.muud                                                                                 AS markused,
       (a.properties ->> 'aa') :: VARCHAR(120)                                                AS arve,
       coalesce((a.properties ->> 'viitenr'), lapsed.get_viitenumber(d.rekvid, l.id)) :: TEXT AS viitenr,
       coalesce((a.properties ->> 'tyyp'), '') :: TEXT                                        AS tyyp,
       l.isikukood                                                                            AS isikukood,
       l.nimi                                                                                 AS nimi,
       coalesce((v.properties ->> 'kas_earve')::BOOLEAN, FALSE)::BOOLEAN
           AND NOT ((a.properties ->> 'ettemaksu_period') IS NOT NULL
           AND
                    a.properties ->> 'tyyp' IS NULL)                                          AS kas_earved,
       coalesce((v.properties ->> 'kas_email')::BOOLEAN, FALSE)::BOOLEAN                      AS kas_email,
       coalesce((v.properties ->> 'kas_paberil')::BOOLEAN, FALSE)::BOOLEAN                    AS kas_paberil,
       (v.properties ->> 'pank'):: TEXT                                                       AS pank,
       CASE
           WHEN coalesce((a.properties ->> 'ebatoenaolised_2_id')::INTEGER, 0) > 0 THEN '100'
           WHEN coalesce((a.properties ->> 'ebatoenaolised_1_id')::INTEGER, 0) > 0 THEN '50'
           ELSE '0' END::VARCHAR(3)                                                           AS ebatoenaolised,
       l.id                                                                                   AS laps_id
FROM docs.doc d
         INNER JOIN docs.arv a ON a.parentId = d.id
         INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
         INNER JOIN lapsed.laps l ON l.id = ld.parentid
         INNER JOIN libs.asutus asutus ON a.asutusid = asutus.id
         INNER JOIN lapsed.vanemad v ON l.id = v.parentid AND v.asutusid = asutus.id
         LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
         LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
WHERE d.status <> 3
  AND d.doc_type_id IN (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood = 'ARV')

ORDER BY d.lastupdate DESC;

GRANT SELECT ON TABLE lapsed.cur_laste_arved TO dbpeakasutaja;
GRANT SELECT ON TABLE lapsed.cur_laste_arved TO dbkasutaja;
GRANT SELECT ON TABLE lapsed.cur_laste_arved TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_laste_arved TO arvestaja;

GRANT ALL ON TABLE lapsed.cur_laste_arved TO dbadmin;

/*
select * from lapsed.cur_laste_arved where rekvid = 95
-- 262

--limit 10
where asutus like 'KREEK%'
 */



