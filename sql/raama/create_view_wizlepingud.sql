DROP VIEW IF EXISTS wizlepingud;

CREATE VIEW wizlepingud AS
  SELECT
    l1.id,
    l1.objektid,
    l1.rekvid,
    l1.number                       AS kood,
    l2.nomid,
    (l1.selgitus) :: CHARACTER(120) AS nimetus,
    a.nimetus                       AS asutus,
    l1.tahtaeg,
    l1.pakettid
  FROM docs.leping1 l1
    JOIN docs.leping2 l2 ON l1.id = l2.parentid
    JOIN libs.asutus a ON a.id = l1.asutusid
  WHERE l2.status = 1;

/*
select * from wizlepingud
*/