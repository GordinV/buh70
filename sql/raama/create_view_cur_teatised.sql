DROP VIEW IF EXISTS cur_teatised;

CREATE VIEW cur_teatised AS
WITH
    doc_types AS (
                     SELECT id
                     FROM libs.library l
                     WHERE l.kood = 'TEATIS' AND l.library = 'DOK' AND l.status < 3
                     LIMIT 1
                 ),
    docs_ids AS (
                     SELECT
                         qry.id                              AS id,
                         qry.rekvid,
                         max(ajalugu ->> 'print')::TIMESTAMP AS print,
                         max(ajalugu ->> 'email')::TIMESTAMP AS email,
                         max(ajalugu ->> 'aadress')::TEXT    AS email_aadress

                     FROM
                         (
                             SELECT
                                 jsonb_array_elements(history) AS ajalugu,
                                 d.id,
                                 d.rekvid
                             FROM
                                 docs.doc  d,
                                 doc_types dt
                             WHERE
                                   d.status < 3
                               AND d.doc_type_id = dt.id
                         ) qry
                     GROUP BY qry.id, qry.rekvid
                 )
SELECT
    d.id,
    d.rekvid,
    t.kpv,
    t.asutusid,
    a.nimetus AS asutus,
    a.regkood AS regkood,
    a.email   AS email,
    a.aadress as aadress,
    t.number,
    t.sisu,
    d.email   AS saadetud,
    d.email_aadress,
    d.print,
    t.docs
FROM
    docs_ids                   d
        INNER JOIN docs.teatis t ON d.id = t.parentid
        INNER JOIN libs.asutus a ON a.id = t.asutusId;


GRANT SELECT ON TABLE cur_teatised TO arvestaja;
GRANT SELECT ON TABLE cur_teatised TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_teatised TO dbkasutaja;
GRANT SELECT ON TABLE cur_teatised TO dbvaatleja;
GRANT ALL ON TABLE cur_teatised TO dbadmin;

/*
select * from cur_teatised
where format_date(to_char(print, 'DD.MM.YYYY HH24:MI:SS')::text) >= '2019-12-14'
and format_date(print::text) <= '2019-12-15'
*/
/*
SELECT format_date('14.12.2019 12:00')

SELECT '14.12.2019 12:00' SIMILAR TO '__.__.____ __:__*'*/