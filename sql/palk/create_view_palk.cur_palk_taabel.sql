DROP VIEW IF EXISTS palk.cur_palk_taabel1;
DROP VIEW IF EXISTS palk.cur_palk_taabel;

CREATE VIEW palk.cur_palk_taabel AS
  SELECT
    pt.id,
    coalesce(pt.kokku, 0) :: NUMERIC    AS kokku,
    pt.lepingid,
    coalesce(pt.ohtu, 0) :: NUMERIC     AS ohtu,
    coalesce(pt.oo, 0) :: NUMERIC       AS oo,
    coalesce(pt.too, 0) :: NUMERIC      AS too,
    coalesce(pt.paev, 0) :: NUMERIC     AS paev,
    coalesce(pt.tahtpaev, 0) :: NUMERIC AS tahtpaev,
    coalesce(pt.puhapaev, 0) :: NUMERIC AS puhapaev,
    pt.kuu,
    pt.aasta,
    amet.kood                           AS ametikood,
    amet.nimetus                        AS amet,
    osakond.kood                        AS osakonnakood,
    osakond.nimetus                     AS osakond,
    a.nimetus                           AS isik,
    a.regkood                           AS isikukood,
    t.rekvid,
    t.status
  FROM palk.palk_taabel1 pt
    INNER JOIN palk.tooleping t ON pt.lepingid = t.id
    INNER JOIN libs.asutus a ON t.parentid = a.id
    INNER JOIN libs.LIBRARY amet ON t.ametid = amet.id
    JOIN libs.LIBRARY osakond ON t.osakondid = osakond.id
  WHERE pt.status <> 'deleted';