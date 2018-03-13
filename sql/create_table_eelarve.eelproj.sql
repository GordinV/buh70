DROP TABLE IF EXISTS eelarve.eelproj;

CREATE TABLE eelarve.eelproj
(
  id         SERIAL               NOT NULL
    CONSTRAINT eelproj_pkey
    PRIMARY KEY,
  rekvid     INTEGER              NOT NULL,
  aasta      INTEGER DEFAULT 2008 NOT NULL,
  kuu        INTEGER DEFAULT 0    NOT NULL,
  staatus    INTEGER DEFAULT 0    NOT NULL,
  kinnitaja  INTEGER DEFAULT 0    NOT NULL,
  muud       TEXT,
  properties JSONB,
  ajalugu    JSONB,
  TIMESTAMP  TIMESTAMP            NOT NULL DEFAULT now(),
  status     INT                  NOT NULL DEFAULT 1
);

CREATE INDEX eelproj_rekvid
  ON eelarve.eelproj (rekvid);

