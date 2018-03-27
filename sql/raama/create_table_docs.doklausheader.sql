DROP TABLE IF EXISTS docs.doklausheader;

CREATE TABLE docs.doklausheader
(
  id         SERIAL                      NOT NULL
    CONSTRAINT doklausheader_pkey
    PRIMARY KEY,
  rekvid     INTEGER                     NOT NULL,
  dok        CHAR(50) DEFAULT space(20)  NOT NULL,
  proc_      CHAR(254) DEFAULT space(20) NOT NULL,
  selg       TEXT DEFAULT space(20)      NOT NULL,
  muud       TEXT,
  status INTEGER,
  properties JSONB
);

CREATE INDEX doklausheader_rekvid
  ON docs.doklausheader (rekvid);
