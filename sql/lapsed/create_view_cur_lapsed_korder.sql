DROP VIEW IF EXISTS lapsed.cur_lapse_korder;

CREATE OR REPLACE VIEW lapsed.cur_lapse_korder AS
SELECT d.id,
       d.rekvid                           AS rekvid,
       k.kpv                              AS kpv,
       k.number::TEXT                     AS number,
       a.nimetus::TEXT                    AS asutus,
       k.dokument::TEXT                   AS dokument,
       k.tyyp,
       k2.summa :: NUMERIC(14, 2)         AS summa,
       COALESCE(Jid.number, 0) :: INTEGER AS lausend,
       aa.nimetus                         AS kassa,
       aa.konto :: TEXT                   AS konto,
       k.journalid,
       l.isikukood                        AS isikukood,
       l.nimi                             AS nimi

FROM docs.doc d
         INNER JOIN docs.korder1 k ON d.id = k.parentid
         INNER JOIN docs.korder2 k2 ON k.id = k2.parentid
         INNER JOIN libs.asutus a ON k.asutusId = a.id
         INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
         INNER JOIN lapsed.laps l ON l.id = ld.parentid
         LEFT OUTER JOIN ou.aa aa ON k.kassaid = aa.id AND aa.parentid = k.rekvid
         LEFT OUTER JOIN docs.journal j ON j.parentid = k.journalid
         LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id;

GRANT SELECT ON TABLE lapsed.cur_lapse_korder TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_korder TO dbkasutaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_korder TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_korder TO dbpeakasutaja;


/*
select * from lapsed.cur_lapse_korder
 */