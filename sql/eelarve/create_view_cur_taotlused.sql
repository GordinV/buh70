DROP VIEW IF EXISTS cur_taotlused;

CREATE VIEW cur_taotlused
  AS
    SELECT
      d.id,
      t.rekvid,
      t.koostajaid,
      t.aktseptid,
      t.kpv,
      t.number,
      t.aasta,
      t.kuu,
      t.status as status,
      t.allkiri,
      coalesce(t1.kood1,'')::varchar(20) as kood1,
      coalesce(t1.kood2,'')::varchar(20) as kood2,
      coalesce(t1.kood3,'')::varchar(20) as kood3,
      coalesce(t1.kood4,'')::varchar(20) as kood4,
      coalesce(t1.kood5,'')::varchar(20) as kood5,
      coalesce(t1.tunnus,'')::varchar(20) as tunnus,
      t1.summa,
      Rekv.parentid,
      Rekv.regkood,
      Rekv.nimetus,
      Userid.ametnik
    FROM docs.doc d
      INNER JOIN eelarve.taotlus t ON d.id = t.parentid
      INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
      INNER JOIN ou.rekv rekv ON t.rekvid = Rekv.id
      LEFT OUTER JOIN ou.userid userid ON t.koostajaid = Userid.id;

