DROP VIEW IF EXISTS lapsed.cur_lapsed_mk;

CREATE OR REPLACE VIEW lapsed.cur_lapsed_mk AS
SELECT d.id,
       Mk.rekvid,
       mk.arvid,
       Mk1.journalid,
       Mk.kpv,
       mk.maksepaev,
       Mk.number,
       Mk.selg,
       MK.OPT,
       CASE
           WHEN mk.opt = 2
               THEN Mk1.summa
           ELSE 0 :: NUMERIC(14, 2) END     AS deebet,
       CASE
           WHEN mk.opt = 1 OR coalesce(mk.opt, 0) = 0
               THEN Mk1.summa
           ELSE 0 :: NUMERIC(14, 2) END     AS kreedit,
       a.id as maksja_id,
       A.regkood::VARCHAR(20)               AS vanem_isikukood,
       A.nimetus::VARCHAR(254)              AS asutus,
       coalesce(N.kood, '')::VARCHAR(20)    AS kood,
       coalesce(Aa.arve, '') :: VARCHAR(20) AS aa,
       coalesce(jid.number, 0) :: INTEGER   AS journalnr,
       l.isikukood                          AS isikukood,
       l.nimi                               AS nimi,
       mk.viitenr,
       mk.jaak
FROM docs.doc d
         INNER JOIN docs.Mk mk ON mk.parentid = d.id
         INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
         INNER JOIN libs.Asutus a ON mk1.asutusId = a.ID
         INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
         INNER JOIN lapsed.laps l ON l.id = ld.parentid
         LEFT OUTER JOIN libs.Nomenklatuur n ON mk1.nomid = n.id
         LEFT OUTER JOIN ou.Aa aa ON Mk.aaid = Aa.id
         LEFT OUTER JOIN docs.Journalid jid ON Mk1.journalid = Jid.journalid;

GRANT SELECT ON TABLE lapsed.cur_lapsed_mk TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapsed_mk TO dbkasutaja;
GRANT SELECT ON TABLE lapsed.cur_lapsed_mk TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapsed_mk TO dbpeakasutaja;
