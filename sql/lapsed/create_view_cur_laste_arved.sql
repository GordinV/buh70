DROP VIEW IF EXISTS lapsed.cur_laste_arved;

CREATE OR REPLACE VIEW lapsed.cur_laste_arved AS
SELECT d.id                                         AS id,
       d.docs_ids,
       trim(a.number)                               AS number,
       a.rekvid,
       a.kpv                                        AS kpv,
       a.summa,
       a.tahtaeg                                    AS tahtaeg,
       a.jaak,
       a.tasud :: DATE                              AS tasud,
       a.tasudok,
       a.userid,
       a.asutusid,
       a.journalid,
       a.lisa,
       trim(asutus.nimetus)                         AS asutus,
       trim(asutus.regkood)                         AS vanem_isikukood,
       jid.number                                   AS lausnr,
       a.muud                                       AS markused,
       (a.properties ->> 'aa') :: VARCHAR(120)      AS arve,
       (a.properties ->> 'viitenr') :: VARCHAR(120) AS viitenr,
       l.isikukood                                  AS isikukood,
       l.nimi                                       AS nimi
FROM docs.doc d
         INNER JOIN docs.arv a ON a.parentId = d.id
         INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
         INNER JOIN lapsed.laps l ON l.id = ld.parentid
         INNER JOIN libs.asutus asutus ON a.asutusid = asutus.id
         LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
         LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
ORDER BY d.lastupdate DESC;

GRANT SELECT ON TABLE lapsed.cur_laste_arved TO dbpeakasutaja;
GRANT SELECT ON TABLE lapsed.cur_laste_arved TO dbkasutaja;
GRANT SELECT ON TABLE lapsed.cur_laste_arved TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_laste_arved TO arvestaja;

GRANT ALL ON TABLE lapsed.cur_laste_arved TO dbadmin;

/*
select * from lapsed.cur_laste_arved
 */


