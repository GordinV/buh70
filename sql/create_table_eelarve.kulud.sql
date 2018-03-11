DROP TABLE IF EXISTS eelarve.kulud;

CREATE TABLE eelarve.kulud (
)
  INHERITS (eelarve.eelarve);

DROP INDEX IF EXISTS kulud_klassif;

CREATE INDEX kulud_klassif
  ON eelarve.kulud
  USING BTREE
  (kood1, kood2, kood3, kood4, kood5);

DROP INDEX IF EXISTS kulud_klassif;

CREATE INDEX kulud_rekvid
  ON eelarve.kulud
  USING BTREE
  (rekvid);

ALTER TABLE eelarve.kulud
  CLUSTER ON kulud_rekvid;

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE eelarve.kulud TO dbpeakasutaja;
GRANT SELECT ON TABLE eelarve.kulud TO dbvaatleja;
GRANT SELECT ON TABLE eelarve.kulud TO dbadmin;
GRANT SELECT ON TABLE eelarve.kulud TO dbkasutaja;
GRANT SELECT ON TABLE eelarve.kulud TO eelkoostaja;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE eelarve.kulud TO eelallkirjastaja;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE eelarve.kulud TO eelesitaja;
GRANT SELECT, UPDATE, INSERT, REFERENCES, TRIGGER ON TABLE eelarve.kulud TO eelaktsepterja;


/*
select * from  eelarve.tulud

 */