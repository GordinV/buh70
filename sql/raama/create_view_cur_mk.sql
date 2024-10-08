/*DROP VIEW IF EXISTS cur_mk;
DROP VIEW IF EXISTS cur_pank;
*/
/*ALTER TABLE ou.aa
    ALTER COLUMN arve TYPE character (24) COLLATE pg_catalog."default";
*/
CREATE OR REPLACE VIEW cur_pank AS
SELECT d.id,
       Mk.rekvid,
       Mk1.journalid,
       Mk.kpv,
       mk.maksepaev,
       Mk.number,
       Mk.selg,
       MK.OPT,
       CASE
           WHEN mk.opt = 2
               THEN Mk1.summa
           ELSE 0 :: NUMERIC(14, 2) END      AS deebet,
       CASE
           WHEN mk.opt = 1 OR coalesce(mk.opt, 0) = 0
               THEN Mk1.summa
           ELSE 0 :: NUMERIC(14, 2) END      AS kreedit,
       coalesce(A.regkood, '')::VARCHAR(20)  AS regkood,
       coalesce(A.nimetus, '')::VARCHAR(254) AS nimetus,
       coalesce(N.kood, '')::VARCHAR(20)     AS kood,
       coalesce(Aa.arve, '') :: VARCHAR(20)  AS aa,
       coalesce(jid.number, 0) :: INTEGER    AS journalnr,
       'EUR' :: VARCHAR                      AS valuuta,
       1 :: NUMERIC                          AS kuurs
FROM docs.doc d
         INNER JOIN docs.Mk mk ON mk.parentid = d.id
         INNER JOIN docs.Mk1 mk1 ON mk.id = mk1.parentid
         LEFT OUTER JOIN libs.Asutus a ON mk1.asutusId = a.ID
         LEFT OUTER JOIN libs.Nomenklatuur n ON mk1.nomid = n.id
         LEFT OUTER JOIN ou.Aa aa ON Mk.aaid = Aa.id
         LEFT OUTER JOIN docs.Journalid jid ON Mk1.journalid = Jid.journalid
WHERE d.status <> 3
    AND d.doc_type_id IN (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN ('SMK', 'VMK'));

GRANT SELECT ON TABLE cur_pank TO dbkasutaja;
GRANT SELECT ON TABLE cur_pank TO dbvaatleja;
GRANT SELECT ON TABLE cur_pank TO dbpeakasutaja;

/*
select * from cur_pank
limit 10
 */