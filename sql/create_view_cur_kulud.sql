DROP VIEW IF EXISTS cur_eelarve;
DROP VIEW IF EXISTS cur_kulud;

CREATE OR REPLACE VIEW cur_kulud AS
  SELECT
    e.id,
    e.rekvid,
    e.aasta,
    e.summa,
    coalesce(e.kood1,'')::varchar(20) as kood1,
    coalesce(e.kood2,'')::varchar(20) as kood2,
    coalesce(e.kood3,'')::varchar(20) as kood3,
    coalesce(e.kood4,'')::varchar(20) as kood4,
    coalesce(e.kood5,'')::varchar(20) as kood5,
    coalesce(e.tunnus,'')::varchar(20) as tunnus,
    r.nimetus                                                                AS asutus,
    r.regkood,
    r.parentid,
    coalesce(parent.nimetus, '')::varchar(254)                                          AS parasutus,
    coalesce(parent.regkood, '')::varchar(20)                                           AS parregkood,
    e.kuu,
    e.kpv,
    e.muud,
    e.is_parandus,
    coalesce(v.valuuta, 'EUR') :: CHARACTER VARYING AS valuuta,
    coalesce(v.kuurs, 1 :: NUMERIC)                                     AS kuurs,
    e.is_parandus as tun
  FROM eelarve.kulud e
    JOIN ou.rekv r ON e.rekvid = r.id
    LEFT outer JOIN ou.rekv parent ON parent.id = r.parentid
    LEFT outer JOIN docs.dokvaluuta1 v ON v.dokid = e.id AND v.dokliik = array_position((enum_range(NULL :: DOK_VALUUTA)), 'eelarve')
  where e.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');

GRANT SELECT ON TABLE cur_kulud TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_kulud TO dbkasutaja;
GRANT ALL ON TABLE cur_kulud TO dbadmin;
GRANT SELECT ON TABLE cur_kulud TO dbvaatleja;
GRANT SELECT ON TABLE cur_kulud TO eelaktsepterja;
GRANT SELECT ON TABLE cur_kulud TO eelallkirjastaja;
GRANT SELECT ON TABLE cur_kulud TO eelesitaja;
GRANT SELECT ON TABLE cur_kulud TO eelkoostaja;


/*

select * from cur_eelarve
 */

