DROP VIEW IF EXISTS palk.cur_palk_jaak;
DROP VIEW IF EXISTS palk.cur_palk_jaak_;

CREATE VIEW palk.cur_palk_jaak
  AS
    SELECT
      rekv.id AS rekvid,
      rekv.parentid,
      a.regkood,
      a.nimetus,
      a.aadress,
      a.tel,
      p.kuu,
      p.aasta,
      p.id,
      p.jaak,
      p.arvestatud,
      p.kinni,
      p.tka,
      p.tki,
      p.pm,
      p.tulumaks,
      p.sotsmaks,
      p.muud,
      l.kood  AS osakond,
      p.g31   AS mvt,
      t.osakondid,
      t.status
    FROM palk.palk_jaak p
      INNER JOIN palk.tooleping t ON p.lepingid = t.id
      JOIN ou.rekv rekv ON rekv.id = t.rekvid
      JOIN libs.asutus a ON t.parentid = a.id
      JOIN libs.library l ON t.osakondid = l.id;



GRANT SELECT ON TABLE palk.cur_palk_jaak TO dbkasutaja;
GRANT SELECT ON TABLE palk.cur_palk_jaak TO dbvaatleja;
GRANT SELECT ON TABLE palk.cur_palk_jaak TO dbpeakasutaja;
