DROP VIEW IF EXISTS hooldekodu.cur_hooTehingud;

CREATE VIEW hooldekodu.cur_hooTehingud AS
SELECT ht.id,
       ht.isikid,
       ht.dokid,
       ht.journalid,
       ht.kpv,
       ht.summa,
       ht.allikas,
       coalesce(ht.doktyyp, '')::VARCHAR(20)          AS doktyyp,
       coalesce(ht.tyyp, '')::VARCHAR(20)             AS tyyp,
       ht.jaak,
       left(coalesce(ht.muud, ''), 254)::VARCHAR(254) AS selg,
       coalesce(ht.muud, '')                          AS muud,
       coalesce(jid.number, 0)::INTEGER               AS lausend,
       ht.rekvid,
       a.regkood                                      AS isikukood,
       a.nimetus                                      AS nimi
FROM hooldekodu.hootehingud ht
         INNER JOIN libs.asutus a ON a.id = ht.isikid
         LEFT OUTER JOIN docs.doc d ON ht.journalid = d.id
         LEFT OUTER JOIN docs.journal j ON d.id = j.parentid
         LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
WHERE ht.status < 3
ORDER BY a.nimetus;

GRANT SELECT ON TABLE hooldekodu.cur_hooTehingud TO hkametnik;
GRANT SELECT ON TABLE hooldekodu.cur_hooTehingud TO soametnik;


/*SELECT *
FROM hooldekodu.cur_hooTehingud
WHERE id = 27
*/