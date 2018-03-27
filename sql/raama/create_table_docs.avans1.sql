DROP TABLE IF EXISTS docs.avans1;

CREATE TABLE docs.avans1
(
  id        SERIAL                               NOT NULL
    CONSTRAINT avans1_pkey
    PRIMARY KEY,
  parentid  INTEGER                              NOT NULL,
  rekvid    INTEGER                              NOT NULL,
  userid    INTEGER                              NOT NULL,
  asutusid  INTEGER                              NOT NULL,
  kpv       DATE DEFAULT ('now' :: TEXT) :: DATE NOT NULL,
  number    VARCHAR(20) DEFAULT space(1)         NOT NULL,
  selg      TEXT DEFAULT (space(1)) :: TEXT      NOT NULL,
  journalid INTEGER DEFAULT 0                    NOT NULL,
  dokpropid INTEGER DEFAULT 0                    NOT NULL,
  muud      TEXT,
  jaak      NUMERIC(14, 2) DEFAULT 0
);

CREATE INDEX avans1_idx1
  ON docs.avans1 (rekvid, userid, asutusid, dokpropid, kpv, journalid);
CREATE INDEX avans1_idx2
  ON docs.avans1 (number);
