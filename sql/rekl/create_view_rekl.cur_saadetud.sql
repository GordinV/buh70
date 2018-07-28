DROP VIEW IF EXISTS cur_saadetud;

CREATE VIEW cur_saadetud
  AS
    SELECT
      d.id,
      d.rekvid,
      LTRIM(RTRIM(l.number)) + '-' + ltrim(rtrim(t.number :: VARCHAR)) :: VARCHAR AS number,
      t.asutusid,
      t.lubaid,
      t.kpv,
      t.tahtaeg,
      t.summa,
      t.tyyp,
      coalesce(rekl.fnc_dekl_jaak(d.ID), 0)                                       AS jaak,
      a.nimetus                                                                   AS nimetus,
      a.regkood
    FROM docs.doc d
      INNER JOIN rekl.toiming t ON t.parentid = d.id
      INNER JOIN rekl.luba l ON t.lubaid = l.parentid
      INNER JOIN libs.asutus a ON a.id = t.asutusid
    WHERE coalesce(t.staatus :: TEXT, '') <> 'deleted'
          AND t.tyyp = 'DEKL'
          AND t.saadetud IS NULL;
