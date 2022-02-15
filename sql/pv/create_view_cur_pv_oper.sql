DROP VIEW IF EXISTS cur_pv_oper;

CREATE OR REPLACE VIEW cur_pv_oper AS

SELECT dd.id,
       dd.rekvid,
       po.summa,
       po.liik,
       po.kpv,
       po.pv_kaart_id,
       po.konto,
       po.kood1,
       po.kood2,
       po.kood3,
       po.kood5,
       po.tunnus,
       po.proj,
       po.tp,
       po.journalid,
       n.kood,
       n.nimetus,
       coalesce(jid.number, 0) AS number,
       'EUR' :: VARCHAR        AS valuuta,
       1 :: NUMERIC            AS kuurs
FROM docs.Pv_oper po
         INNER JOIN docs.doc dd ON dd.id = po.parentid
         LEFT OUTER JOIN libs.nomenklatuur n ON n.id = po.nomid
         LEFT OUTER JOIN docs.doc d ON d.id = po.journalid
         LEFT OUTER JOIN docs.journal j ON j.parentid = d.id
         LEFT OUTER JOIN docs.journalid jid ON j.id = jid.journalid;



GRANT SELECT ON TABLE cur_pv_oper TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_pv_oper TO dbkasutaja;
GRANT SELECT ON TABLE cur_pv_oper TO dbvaatleja;
GRANT ALL ON TABLE cur_pv_oper TO dbadmin;
