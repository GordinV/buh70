DROP VIEW IF EXISTS palk.com_toolepingud;

CREATE VIEW palk.com_toolepingud AS
  SELECT
    t.id,
    a.nimetus      AS isik,
    a.regkood      AS isikukood,
    osakonnad.kood AS osakond,
    osakonnad.id   AS osakondid,
    ametid.kood    AS amet,
    ametid.id      AS ametid,
    t.algab,
    t.lopp,
    t.toopaev,
    t.palk,
    t.palgamaar,
    t.pohikoht,
    t.koormus,
    t.ametnik,
    t.pank,
    t.aa,
    t.rekvid,
    t.parentid,
    t.tasuliik
  FROM libs.asutus a
    INNER JOIN palk.tooleping t ON a.id = t.parentid
    INNER JOIN libs.library osakonnad ON t.osakondid = osakonnad.id
    INNER JOIN libs.library ametid ON t.ametid = ametid.id
  WHERE t.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');
