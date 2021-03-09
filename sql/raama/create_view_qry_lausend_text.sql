DROP VIEW IF EXISTS qry_lausend_text;

CREATE OR REPLACE VIEW qry_lausend_text AS
SELECT id,
       number,
       kpv,
       rekvid,
       trim(array_agg(lausend)::TEXT, '{}"') AS lausend
FROM (
         SELECT j.id,
                j.number,
                j.kpv,
                j.rekvid,
                ('D ' || ltrim(rtrim(j.deebet)) || ' ' ||
                 'K ' || ltrim(rtrim(j.kreedit)) || ' ' ||
                 ltrim(rtrim(round(j.summa, 2)::TEXT)) || ' ' ||
                 'TA ' || ltrim(rtrim(j.kood1::TEXT)) || ' ' ||
                 'Allikas ' || ltrim(rtrim(j.kood2::TEXT)) || ' ' ||
                 'RV ' || ltrim(rtrim(j.kood3::TEXT)) || ' ' ||
                 'Art ' || ltrim(rtrim(j.kood5::TEXT)))::TEXT AS lausend
         FROM cur_journal j
     ) qry
GROUP BY id, number, kpv, rekvid;

GRANT SELECT ON TABLE qry_lausend_text TO dbkasutaja;
GRANT SELECT ON TABLE qry_lausend_text TO dbvaatleja;
GRANT SELECT ON TABLE qry_lausend_text TO dbpeakasutaja;


SELECT *
FROM qry_lausend_text
ORDER BY id DESC
LIMIT 100
