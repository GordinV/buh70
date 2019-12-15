DROP VIEW IF EXISTS cur_teatised;

CREATE VIEW cur_teatised AS
SELECT d.id,
       d.rekvid,
       t.kpv,
       t.asutusid,
       a.nimetus AS asutus,
       a.regkood AS regkood,
       a.email   AS email,
       t.number,
       t.sisu,
       qry.email AS saadetud,
       qry.print
FROM docs.doc d
         INNER JOIN docs.teatis t ON d.id = t.parentid
         INNER JOIN libs.asutus a ON a.id = t.asutusId
         INNER JOIN (SELECT qry.id                              AS doc_id,
                            max(ajalugu ->> 'print')::TIMESTAMP AS print,
                            max(ajalugu ->> 'email')::TIMESTAMP AS email

                     FROM (
                              SELECT jsonb_array_elements(history) AS ajalugu, d.id, d.rekvid
                              FROM docs.doc d
                          ) qry
                     GROUP BY qry.id
) qry ON qry.doc_id = d.id
WHERE d.status <> 3;


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

select format_date('14.12.2019 12:00')

SELECT '14.12.2019 12:00' SIMILAR TO '__.__.____ __:__*'