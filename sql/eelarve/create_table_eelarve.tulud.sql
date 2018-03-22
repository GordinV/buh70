DROP TABLE IF EXISTS eelarve.tulud;

CREATE TABLE eelarve.tulud (
)
  INHERITS (eelarve.eelarve);

DROP INDEX IF EXISTS tulud_klassif;

CREATE INDEX tulud_klassif
  ON eelarve.tulud
  USING BTREE
  (kood1, kood2, kood3, kood4, kood5);

DROP INDEX IF EXISTS tulud_klassif;

CREATE INDEX tulud_rekvid
  ON eelarve.tulud
  USING BTREE
  (rekvid);

ALTER TABLE eelarve.tulud
  CLUSTER ON tulud_rekvid;

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE eelarve.tulud TO dbpeakasutaja;
GRANT SELECT ON TABLE eelarve.tulud TO dbvaatleja;
GRANT SELECT ON TABLE eelarve.tulud TO dbadmin;
GRANT SELECT ON TABLE eelarve.tulud TO dbkasutaja;
GRANT SELECT ON TABLE eelarve.tulud TO eelkoostaja;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE eelarve.tulud TO eelallkirjastaja;
GRANT SELECT, REFERENCES, TRIGGER ON TABLE eelarve.tulud TO eelesitaja;
GRANT SELECT, UPDATE, INSERT, REFERENCES, TRIGGER ON TABLE eelarve.tulud TO eelaktsepterja;


/*
select * from  eelarve.tulud

 */