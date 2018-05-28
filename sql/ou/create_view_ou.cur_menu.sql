DROP VIEW IF EXISTS ou.cur_menu;

CREATE VIEW ou.cur_menu AS
  SELECT
    id,
    pad,
    bar,
    idx,
    properties ->> 'name'        AS name,
    properties ->> 'eesti'       AS eesti,
    properties ->> 'vene'        AS vene,
    properties ->> 'proc'        AS proc,
    properties ->> 'groups'      AS groups,
    properties ->> 'users'       AS users,
    properties ->> 'modules'     AS modules,
    properties ->> 'level'       AS level,
    properties ->> 'message'     AS message,
    properties ->> 'keyshortcut' AS keyshortcut
  FROM ou.menupohi
  WHERE status = 'active';

