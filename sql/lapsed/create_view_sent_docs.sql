DROP VIEW IF EXISTS docs.cur_doc_sent;

CREATE OR REPLACE VIEW docs.cur_doc_sent AS

SELECT qry.id                                AS doc_id,
       max(ajalugu ->> 'print')::TIMESTAMP   AS print,
       max(ajalugu ->> 'email')::TIMESTAMP   AS email,
       max(ajalugu ->> 'earve')::TIMESTAMP   AS earve

FROM (
         SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
         FROM docs.doc d
     ) qry
where (ajalugu ->> 'print' is not null  or ajalugu ->> 'email' is not null or ajalugu ->> 'earve' is not null)
GROUP BY qry.id;

GRANT SELECT ON TABLE docs.cur_doc_sent  TO arvestaja;
GRANT SELECT ON TABLE docs.cur_doc_sent  TO dbvaatleja;
GRANT SELECT ON TABLE docs.cur_doc_sent  TO dbpeakasutaja;
GRANT SELECT ON TABLE docs.cur_doc_sent  TO dbkasutaja;
