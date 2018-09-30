DROP VIEW IF EXISTS cur_doklausend;

CREATE VIEW cur_doklausend AS
  SELECT
    D.id,
    D.rekvid,
    D.dok,
    D.selg::varchar(254),
    d1.deebet,
    d1.kreedit,
    d1.summa,
    d1.kood1 AS tegev,
    d1.kood2 AS allikas,
    d1.kood3 AS rahavoog,
    d1.kood5 AS artikkel,
    d1.lisa_d,
    d1.lisa_k,
    d1.deebet || d1.kreedit as lausend
  FROM docs.doklausheader d
    INNER JOIN docs.doklausend d1 ON D.id = d1.parentid
  WHERE D.status <> 3;

GRANT SELECT ON TABLE cur_doklausend TO dbpeakasutaja;
GRANT SELECT ON TABLE cur_doklausend TO dbkasutaja;
GRANT SELECT ON TABLE cur_doklausend TO dbvaatleja;
GRANT ALL ON TABLE cur_doklausend TO dbadmin;

