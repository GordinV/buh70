DROP VIEW IF EXISTS cur_taotlused;

CREATE VIEW cur_taotlused
AS
SELECT d.id,
       t.rekvid,
       t.koostajaid,
       t.aktseptid,
       t.kpv,
       t.number,
       t.aasta,
       t.kuu,
       t.status                             AS status,
       t.allkiri,
       coalesce(t1.kood1, '')::VARCHAR(20)  AS kood1,
       coalesce(t1.kood2, '')::VARCHAR(20)  AS kood2,
       coalesce(t1.kood3, '')::VARCHAR(20)  AS kood3,
       coalesce(t1.kood4, '')::VARCHAR(20)  AS kood4,
       coalesce(t1.kood5, '')::VARCHAR(20)  AS kood5,
       coalesce(t1.tunnus, '')::VARCHAR(20) AS tunnus,
       coalesce(t1.proj, '')::VARCHAR(20)   AS proj,
       coalesce(t1.objekt, '')::VARCHAR(20) AS objekt,
       t1.summa,
       t1.summa_kassa,
       t1.oodatav_taitmine,
       Rekv.parentid,
       Rekv.regkood,
       Rekv.nimetus,
       Userid.ametnik,
       t1.selg                              AS rea_selg,
       t.muud                               AS dok_mark,
       t1.eelarveid                         AS eelarveid
FROM docs.doc d
         INNER JOIN eelarve.taotlus t ON d.id = t.parentid
         INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
         INNER JOIN ou.rekv rekv ON t.rekvid = Rekv.id
         LEFT OUTER JOIN ou.userid userid ON t.koostajaid = Userid.id
WHERE d.status <> 3
  AND d.doc_type_id IN (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood = 'TAOTLUS')
;

GRANT SELECT ON TABLE cur_taotlused TO dbpeakasutaja;
GRANT ALL ON TABLE cur_taotlused TO dbadmin;
GRANT SELECT ON TABLE cur_taotlused TO dbvaatleja;
GRANT SELECT ON TABLE cur_taotlused TO eelaktsepterja;
GRANT SELECT ON TABLE cur_taotlused TO eelallkirjastaja;
GRANT SELECT ON TABLE cur_taotlused TO eelesitaja;
GRANT SELECT ON TABLE cur_taotlused TO eelkoostaja;

/*

 select * from cur_taotlused order by id desc limit 10
 */