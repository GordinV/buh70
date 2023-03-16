DROP VIEW IF EXISTS docs.cur_doc_sent;

CREATE OR REPLACE VIEW docs.cur_doc_sent AS

SELECT qry.id                              AS doc_id,
       max(ajalugu ->> 'print')::TIMESTAMP AS print,
       max(ajalugu ->> 'email')::TIMESTAMP AS email,
       max(ajalugu ->> 'earve')::TIMESTAMP AS earve

FROM (
         SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
         FROM docs.doc d
         WHERE d.doc_type_id IN (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN ('ARV'))
           AND d.status < 3
     ) qry
WHERE (ajalugu ->> 'print' IS NOT NULL OR ajalugu ->> 'email' IS NOT NULL OR ajalugu ->> 'earve' IS NOT NULL)
GROUP BY qry.id;

GRANT SELECT ON TABLE docs.cur_doc_sent TO arvestaja;
GRANT SELECT ON TABLE docs.cur_doc_sent TO dbvaatleja;
GRANT SELECT ON TABLE docs.cur_doc_sent TO dbpeakasutaja;
GRANT SELECT ON TABLE docs.cur_doc_sent TO dbkasutaja;
