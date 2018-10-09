DROP VIEW IF EXISTS ou.cur_userid;

CREATE VIEW ou.cur_userid AS
  SELECT
    u.id,
    r.nimetus as asutus,
    u.kasutaja,
    u.ametnik,
    u.properties ->> 'email' AS email,
    (u.roles->>'is_admin')::BOOLEAN as is_admin,
    (u.roles->>'is_kasutaja')::BOOLEAN as is_kasutaja,
    (u.roles->>'is_peakasutaja')::BOOLEAN as is_peakasutaja,
    u.rekvid
  FROM ou.userid u
    inner join ou.rekv r on r.id = u.rekvid
  WHERE u.status <> 3;


GRANT ALL ON TABLE curlepingud TO dbadmin;
GRANT SELECT ON TABLE ou.cur_userid TO dbpeakasutaja;
GRANT SELECT ON TABLE ou.cur_userid TO dbkasutaja;
GRANT SELECT ON TABLE ou.cur_userid TO dbvaatleja;
GRANT SELECT ON TABLE ou.cur_userid TO eelaktsepterja;
GRANT SELECT ON TABLE ou.cur_userid TO eelallkirjastaja;
GRANT SELECT ON TABLE ou.cur_userid TO eelallkirjastaja;

/*
eelesitajaselect * from ou.cur_userid
 */