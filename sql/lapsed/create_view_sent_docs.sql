DROP VIEW IF EXISTS docs.cur_doc_sent;

CREATE OR REPLACE VIEW docs.cur_doc_sent AS
WITH
    docs AS (
                SELECT
                    qry.id                              AS doc_id,
                    max(ajalugu ->> 'print')::TIMESTAMP AS print,
                    max(ajalugu ->> 'email')::TIMESTAMP AS email,
                    max(ajalugu ->> 'earve')::TIMESTAMP AS earve

                FROM
                    (
                        SELECT
                            jsonb_array_elements(history) AS ajalugu,
                            d.id,
                            d.rekvid
                        FROM
                            docs.doc d
                        WHERE
                              d.doc_type_id IN (
                                                   SELECT
                                                       id
                                                   FROM
                                                       libs.library
                                                   WHERE
                                                         library.library = 'DOK'
                                                     AND kood IN ('ARV')
                                               )
                          AND d.status < 3
                    ) qry
                WHERE
                    (ajalugu ->> 'print' IS NOT NULL OR ajalugu ->> 'email' IS NOT NULL OR
                     ajalugu ->> 'earve' IS NOT NULL)
                GROUP BY qry.id
            ),
    logs as (
                select
                    l.doc_id                          as doc_id,
                    jsonb_agg(l.changes ->> 'status') as status
                from
                    ou.logs l
                where
                      l.propertis ->> 'table' = 'arv'
                  and doc_id in (
                                    select
                                        doc_id
                                    from
                                        docs d
                                    where
                                        email is not null
                                )
                  and changes ->> 'status' is not null
                group by l.doc_id
            )

SELECT
    d.*,
    ea.email_aadress                                                                           AS email_aadress,

    case
        when status is null then ''
        else array_to_string(ARRAY(SELECT jsonb_array_elements_text(status::jsonb)), ', ') end as status

FROM
    docs                  d
        LEFT OUTER JOIN (
                            SELECT
                                event ->> 'aadress'            AS email_aadress,
                                (event ->> 'email')::TIMESTAMP AS email,
                                id                             AS doc_id,
                                status
                            FROM
                                (
                                    SELECT
                                        d.id,
                                        jsonb_array_elements(history) AS event,
                                        logs.status
                                    FROM
                                        docs.doc d
                                            left outer join logs on logs.doc_id = d.id
                                    WHERE
                                          id IN (
                                                    SELECT
                                                        doc_id
                                                    FROM
                                                        docs
                                                )
                                      AND d.history::TEXT LIKE '%email%'
                                      AND d.history::TEXT LIKE '%aadress%'
                                ) qry
                        ) ea ON ea.doc_id = d.doc_id AND ea.email = d.email;

GRANT SELECT ON TABLE docs.cur_doc_sent TO arvestaja;
GRANT SELECT ON TABLE docs.cur_doc_sent TO dbvaatleja;
GRANT SELECT ON TABLE docs.cur_doc_sent TO dbpeakasutaja;
GRANT SELECT ON TABLE docs.cur_doc_sent TO dbkasutaja;
