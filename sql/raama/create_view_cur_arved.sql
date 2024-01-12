DROP VIEW IF EXISTS cur_arved;
DROP VIEW IF EXISTS cur_arved_;

CREATE OR REPLACE VIEW cur_arved AS
/*    WITH docs_types AS (
        SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('ARV')
    )
*/
SELECT d.id                                                AS id,
       d.docs_ids,
       a.id                                                AS arv_id,
       trim(a.number)                                      AS number,
       a.rekvid,
       a.kpv                                               AS kpv,
       a.summa,
       a.tahtaeg                                           AS tahtaeg,
       a.jaak,
       a.tasud :: DATE                                     AS tasud,
       a.tasudok,
       a.userid,
       a.asutusid,
       a.journalid,
       a.liik,
       a.lisa,
       a.operid,
       coalesce(a.objektId, 0)                             AS objektid,
       trim(asutus.nimetus)                                AS asutus,
       trim(asutus.regkood)                                AS regkood,
       trim(asutus.omvorm)                                 AS omvorm,
       trim(asutus.aadress)                                AS aadress,
       trim(asutus.email)                                  AS email,
       'EUR' :: CHARACTER VARYING                          AS valuuta,
       1 :: NUMERIC                                        AS kuurs,
       coalesce(a1.objektid, '') :: VARCHAR(20)            AS objekt,
       to_char(d.created, 'DD.MM.YYYY HH:MM')              AS created,
       to_char(d.lastupdate, 'DD.MM.YYYY HH:MM')           AS lastupdate,
       trim(s.nimetus)                                     AS status,
       coalesce(u.ametnik, '') :: VARCHAR(120)             AS ametnik,
       jid.number                                          AS lausnr,
       coalesce(a.muud, '')                                AS markused,
       (a.properties ->> 'aa') :: VARCHAR(120)             AS arve,
       (a.properties ->> 'viitenr') :: VARCHAR(120)        AS viitenr,
       CASE
           WHEN coalesce((a.properties ->> 'ebatoenaolised_2_id')::INTEGER, 0) > 0 THEN '100'
           WHEN coalesce((a.properties ->> 'ebatoenaolised_1_id')::INTEGER, 0) > 0 THEN '50'
           ELSE '0' END::VARCHAR(3)                        AS ebatoenaolised,
       coalesce((dp.details ->> 'konto'), '')::VARCHAR(20) AS korr_konto
FROM docs.doc d
         INNER JOIN docs.arv a ON a.parentId = d.id
         LEFT OUTER JOIN (SELECT a1.parentid                AS arv_id,
                                 string_agg(a1.objekt, ',') AS objektid
                          FROM docs.arv1 a1
                          WHERE (a1.objekt IS NOT NULL and a1.objekt <> '')
                          GROUP BY a1.parentid) a1 ON a1.arv_id = a.id
         INNER JOIN libs.library s ON s.kood = d.status :: TEXT AND s.library = 'STATUS'
         LEFT OUTER JOIN libs.dokprop dp ON dp.id = a.doklausid
         LEFT OUTER JOIN libs.asutus asutus ON a.asutusid = asutus.id AND d.status < 3
         LEFT OUTER JOIN ou.userid u ON u.id = a.userid AND u.status < 3
         LEFT OUTER JOIN docs.journal j ON j.parentid = a.journalid
         LEFT OUTER JOIN docs.journalid jid ON jid.journalid = j.id
WHERE d.doc_type_id = 53
  AND d.status < 3
;
--                              IN (SELECT id FROM docs_types)

--ORDER BY d.lastupdate DESC;

GRANT SELECT ON TABLE cur_arved TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_arved TO dbkasutaja;
GRANT SELECT ON TABLE cur_arved TO dbvaatleja;
GRANT ALL ON TABLE cur_arved TO dbadmin;



