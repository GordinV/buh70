DROP VIEW IF EXISTS palk.cur_used_mvt;

CREATE VIEW palk.cur_used_mvt AS

  SELECT
    summa        AS summa,
    a.regkood    AS isikukood,
    a.nimetus    AS isik,
    a.id         AS isikid,
    amet.nimetus AS amet,
    t.alg_kpv,
    t.lopp_kpv,
    l.rekvid     AS rekvid,
    t.lepingid
  FROM PALK.taotlus_mvt t
    INNER JOIN palk.tooleping l ON l.id = t.lepingid
    INNER JOIN libs.asutus a ON a.id = l.parentid
    INNER JOIN libs.library amet ON amet.id = l.ametid
  WHERE t.status <> 'deleted';