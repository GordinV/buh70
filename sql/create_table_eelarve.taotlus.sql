DROP TABLE IF EXISTS eelarve.taotlus CASCADE;

CREATE TABLE eelarve.taotlus
(
  id         SERIAL               NOT NULL
    CONSTRAINT taotlus_pkey
    PRIMARY KEY,
  parentid   INTEGER,
  rekvid     INTEGER              NOT NULL,
  koostajaid INTEGER              NOT NULL,
  ametnikid  INTEGER,
  aktseptid  INTEGER,
  kpv        DATE                 NOT NULL,
  number     VARCHAR(20)          NOT NULL,
  aasta      INTEGER DEFAULT 2008 NOT NULL,
  kuu        INTEGER DEFAULT 0    NOT NULL,
  status     INTEGER DEFAULT 0    NOT NULL,
  allkiri    INTEGER DEFAULT 0    NOT NULL,
  muud       TEXT,
  tunnus     INTEGER DEFAULT 0,
  ajalugu    JSONB,
  timestamp  TIMESTAMP
);


CREATE INDEX taotlus_rekvid
  ON eelarve.taotlus (rekvid);
CREATE INDEX taotlus_status
  ON eelarve.taotlus (status, allkiri);
