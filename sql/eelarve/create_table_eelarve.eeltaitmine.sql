DROP TABLE IF EXISTS eelarve.eeltaitmine;

CREATE TABLE eelarve.eeltaitmine
(
  id       SERIAL                     NOT NULL
    CONSTRAINT eeltaitmine_pkey
    PRIMARY KEY,
  rekvid   INTEGER                    NOT NULL,
  aasta    SMALLINT DEFAULT 0         NOT NULL,
  kuu      SMALLINT DEFAULT 0         NOT NULL,
  kood1    CHAR(20) DEFAULT space(20) NOT NULL,
  kood2    CHAR(20) DEFAULT space(20) NOT NULL,
  kood3    CHAR(20) DEFAULT space(20) NOT NULL,
  kood4    CHAR(20) DEFAULT space(20) NOT NULL,
  kood5    CHAR(20) DEFAULT space(20) NOT NULL,
  objekt   CHAR(20) DEFAULT space(20) NOT NULL,
  proj     CHAR(20) DEFAULT space(20) NOT NULL,
  summa    NUMERIC(14, 2) DEFAULT 0   NOT NULL,
  tunnus varchar(20),
  muud     TEXT,
  is_kulud BOOLEAN                    NOT NULL DEFAULT TRUE
);
CREATE INDEX eeltaitmine_rekvid
  ON eelarve.eeltaitmine (rekvid);
CREATE INDEX eeltaitmine_period
  ON eelarve.eeltaitmine (aasta, kuu);


GRANT SELECT ON TABLE eelarve.eeltaitmine TO dbpeakasutaja;
GRANT SELECT ON TABLE eelarve.eeltaitmine TO dbkasutaja;
GRANT ALL ON TABLE eelarve.eeltaitmine TO dbadmin;
GRANT SELECT ON TABLE eelarve.eeltaitmine TO dbvaatleja;
GRANT SELECT ON TABLE eelarve.eeltaitmine TO eelaktsepterja;
GRANT SELECT ON TABLE eelarve.eeltaitmine TO eelallkirjastaja;
GRANT SELECT ON TABLE eelarve.eeltaitmine TO eelesitaja;
GRANT SELECT ON TABLE eelarve.eeltaitmine TO eelkoostaja;

