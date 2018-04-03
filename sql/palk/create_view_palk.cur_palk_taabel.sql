DROP VIEW IF EXISTS palk.cur_palk_taabel1;
DROP VIEW IF EXISTS palk.cur_palk_taabel;

CREATE VIEW palk.cur_palk_taabel AS
  SELECT
    pt.id,
    pt.kokku,
    pt.lepingid,
    pt.ohtu,
    pt.oo,
    pt.too,
    pt.paev,
    pt.tahtpaev,
    pt.puhapaev,
    pt.kuu,
    pt.aasta,
    amet.kood       AS ametikood,
    amet.nimetus    AS amet,
    osakond.kood    AS osakonnakood,
    osakond.nimetus AS osakond,
    a.nimetus       AS isik,
    a.regkood       AS isikukood,
    t.rekvid,
    t.status
  FROM palk.palk_taabel1 pt
    INNER JOIN palk.tooleping t ON pt.lepingid = t.id
    INNER JOIN libs.asutus a ON t.parentid = a.id
    INNER JOIN libs.LIBRARY amet ON t.ametid = amet.id
    JOIN libs.LIBRARY osakond ON t.osakondid = osakond.id
  WHERE pt.status <> 'deleted';
