DROP VIEW IF EXISTS cur_ladu_jaak;

CREATE OR REPLACE VIEW cur_ladu_jaak AS
  SELECT
    n.id,
    n.kood,
    sum(j.jaak) AS jaak,
    j.hind,
    j.rekvid,
    j.laduid,
    l.kood      AS ladu
  FROM libs.ladu_jaak j
    INNER JOIN libs.nomenklatuur n ON n.id = j.nomid
    LEFT OUTER JOIN libs.library l ON l.id = j.laduid
  WHERE n.status <> 3
  GROUP BY n.id, n.kood, j.rekvid, j.laduid, j.hind, l.kood;

GRANT ALL ON TABLE cur_ladu_jaak TO dbadmin;
GRANT SELECT ON TABLE cur_ladu_jaak TO dbkasutaja;
GRANT SELECT ON TABLE cur_ladu_jaak TO dbvaatleja;
GRANT SELECT ON TABLE cur_ladu_jaak TO dbpeakasutaja;

