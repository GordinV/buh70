DROP VIEW IF EXISTS docs.cur_doc_sent;

CREATE OR REPLACE VIEW docs.cur_doc_sent AS
    WITH docs AS (
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
        GROUP BY qry.id
    )
    SELECT d.*,
           ea.email_aadress AS email_aadress
    FROM docs d
             LEFT OUTER JOIN (
        SELECT event ->> 'aadress' AS email_aadress, (event ->> 'email')::TIMESTAMP AS email, id AS doc_id
        FROM (
                 SELECT d.id, jsonb_array_elements(history) AS event
                 FROM docs.doc d
                 WHERE id IN (SELECT doc_id FROM docs)
                   AND d.history::TEXT LIKE '%email%'
                   AND d.history::TEXT LIKE '%aadress%'
             ) qry
    ) ea ON ea.doc_id = d.doc_id AND ea.email = d.email;

GRANT SELECT ON TABLE docs.cur_doc_sent TO arvestaja;
GRANT SELECT ON TABLE docs.cur_doc_sent TO dbvaatleja;
GRANT SELECT ON TABLE docs.cur_doc_sent TO dbpeakasutaja;
GRANT SELECT ON TABLE docs.cur_doc_sent TO dbkasutaja;
