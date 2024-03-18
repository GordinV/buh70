DROP VIEW IF EXISTS cur_pv_oper;

CREATE OR REPLACE VIEW cur_pv_oper AS

SELECT dd.id,
       dd.rekvid,
       po.summa,
       po.liik,
       po.kpv,
       po.pv_kaart_id,
       coalesce(po.konto, '')::VARCHAR(20)  AS konto,
       coalesce(po.kood1, '')::VARCHAR(20)  AS kood1,
       coalesce(po.kood2, '')::VARCHAR(20)  AS kood2,
       coalesce(po.kood3, '')::VARCHAR(20)  AS kood3,
       coalesce(po.kood5, '')::VARCHAR(20)  AS kood5,
       coalesce(po.tunnus, '')::VARCHAR(20) AS tunnus,
       coalesce(po.proj, '')::VARCHAR(20)   AS proj,
       coalesce(po.tp, '')::VARCHAR(20)     AS tp,
       po.journalid,
       n.kood,
       n.nimetus,
       coalesce(jid.number, 0)              AS number,
       'EUR' :: VARCHAR                     AS valuuta,
       1 :: NUMERIC                         AS kuurs
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
