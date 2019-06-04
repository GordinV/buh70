drop table if exists eelarve.eelarve CASCADE;

CREATE TABLE eelarve.eelarve
(
  id        SERIAL                        NOT NULL
    CONSTRAINT eelarve_pkey
    PRIMARY KEY,
  rekvid    INTEGER                       NOT NULL,
  aasta     INTEGER DEFAULT year()        NOT NULL,
  summa     NUMERIC(14, 2) DEFAULT 0      NOT NULL,
  muud      TEXT,
  tunnus    VARCHAR(20),
  kood1     VARCHAR(20),
  kood2     VARCHAR(20),
  kood3     VARCHAR(20),
  kood4     VARCHAR(20),
  kood5     VARCHAR(20),
  kpv       DATE,
  kuu       SMALLINT DEFAULT 0,
  is_kulud  SMALLINT not null,
  is_parandus integer not null default 0,
  variantid INTEGER  DEFAULT 0,
  status integer default 1
);


GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE eelarve.eelarve TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE  ON TABLE eelarve.eelarve TO dbkasutaja;
GRANT ALL ON TABLE eelarve.eelarve TO dbadmin;
GRANT SELECT ON TABLE eelarve.eelarve TO dbvaatleja;


