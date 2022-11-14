DROP VIEW IF EXISTS lapsed.cur_lapsed_mk;
DROP VIEW IF EXISTS lapsed.cur_lapsed_mk_;

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
           ELSE 0 :: NUMERIC(14, 2) END                AS deebet,
       CASE
           WHEN mk.opt = 1 OR coalesce(mk.opt, 0) = 0
               THEN Mk1.summa
           ELSE 0 :: NUMERIC(14, 2) END                AS kreedit,
       a.id                                            AS maksja_id,
       A.regkood::VARCHAR(20)                          AS vanem_isikukood,
       A.nimetus::VARCHAR(254)                         AS asutus,
       coalesce(N.kood, '')::VARCHAR(20)               AS kood,
       coalesce(Aa.arve, '') :: VARCHAR(20)            AS aa,
       coalesce(jid.number, 0) :: INTEGER              AS journalnr,
       l.isikukood                                     AS isikukood,
       l.nimi                                          AS nimi,
       l.id                                            AS laps_id,
       mk.viitenr,
       mk.jaak,
       array_to_string(yksus.yksused, ','::TEXT)::TEXT AS yksused
FROM docs.doc d
         INNER JOIN docs.Mk mk ON mk.parentid = d.id
         INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
         INNER JOIN libs.Asutus a ON mk1.asutusId = a.ID
         INNER JOIN lapsed.liidestamine ld ON ld.docid = d.id
         INNER JOIN lapsed.laps l ON l.id = ld.parentid
         LEFT OUTER JOIN
     (SELECT parentid, rekvid, array_agg(yksused) AS yksused
      FROM (
               SELECT parentid,
                      rekvid,
                      (public.get_unique_value_from_json(json_agg((k.properties ->> 'yksus')::TEXT)::JSONB)) AS yksused
               FROM lapsed.lapse_kaart k
               WHERE k.staatus <> 3
--                 AND (k.properties ->> 'lopp_kpv')::DATE >= '2021-01-01'
               GROUP BY parentid, rekvid
           ) qry
      GROUP BY parentid, rekvid
     ) yksus ON yksus.parentid = l.id AND yksus.rekvid = mk.rekvid
         LEFT OUTER JOIN libs.Nomenklatuur n ON mk1.nomid = n.id
         LEFT OUTER JOIN ou.Aa aa ON Mk.aaid = Aa.id
         LEFT OUTER JOIN docs.Journalid jid ON Mk1.journalid = Jid.journalid
WHERE d.status <> 3
  AND d.doc_type_id IN (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN ('SMK', 'VMK'))
;

GRANT SELECT ON TABLE lapsed.cur_lapsed_mk TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapsed_mk TO dbkasutaja;
GRANT SELECT ON TABLE lapsed.cur_lapsed_mk TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapsed_mk TO dbpeakasutaja;

/*
 select * from lapsed.cur_lapsed_mk
 where rekvid = 95
 */
