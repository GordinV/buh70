DROP VIEW IF EXISTS rekl.cur_ettemaksud;
DROP VIEW IF EXISTS cur_ettemaksud;

CREATE VIEW cur_ettemaksud AS
  SELECT
    e.id,
    e.rekvid,
    e.asutusid,
    e.number,
    e.summa,
    e.kpv,
    e.dokid,
    e.doktyyp,
    CASE WHEN e.doktyyp = 'DEEBET'
      THEN 'LAUSEND'
    ELSE 'TASU' END :: VARCHAR(40) AS dokument,
    e.selg :: VARCHAR(254)         AS selg,
    a.nimetus                      AS asutus,
    a.regkood                      AS regkood,
    e.staatus
  FROM rekl.ettemaksud e
    INNER JOIN libs.asutus a ON e.asutusid = a.id
  WHERE e.staatus <> 'deleted';


GRANT SELECT ON TABLE cur_ettemaksud TO dbvaatleja;
