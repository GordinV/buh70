DROP VIEW IF EXISTS palk.com_palk_kaart;

CREATE VIEW palk.com_palk_kaart AS
  SELECT
    pk.id,
    pk.libid,
    pk.lepingid,
    l.kood,
    l.nimetus,
    l.rekvid
  FROM libs.library l
    INNER JOIN palk.palk_kaart pk ON pk.libId = l.id
  WHERE pk.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');
