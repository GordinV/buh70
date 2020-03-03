DROP VIEW IF EXISTS palk.cur_toografik;

CREATE VIEW palk.cur_toografik AS
  SELECT
    a.regkood       AS isikukood,
    a.nimetus       AS isik,
    osakond.nimetus AS osakond,
    amet.nimetus    AS amet,
    p.id,
    p.lepingid,
    p.kuu,
    p.aasta,
    p.tund,
    t.rekvid,
    t.parentid      AS asutusid
  FROM palk.toograf p
    INNER JOIN palk.tooleping t ON t.id = p.lepingid
    INNER JOIN libs.library osakond ON osakond.id = t.osakondid
    INNER JOIN libs.library amet ON amet.id = t.ametid
    INNER JOIN libs.asutus a ON a.id = t.parentid
  WHERE p.status <> 'deleted';

GRANT SELECT ON TABLE palk.cur_toografik TO dbkasutaja;
GRANT SELECT ON TABLE palk.cur_toografik TO dbvaatleja;
GRANT SELECT ON TABLE palk.cur_toografik TO dbpeakasutaja;

