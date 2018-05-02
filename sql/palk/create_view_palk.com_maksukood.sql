DROP VIEW IF EXISTS palk.com_maksukood;

CREATE VIEW palk.com_maksukood AS
  SELECT
    l.id,
    l.rekvid,
    l.kood,
    l.nimetus,
    l.status
  FROM libs.library l
  WHERE l.library = 'MAKSUKOOD'
        AND l.status <> array_position(enum_range(NULL :: DOK_STATUS), 'deleted');