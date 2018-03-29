DROP TABLE IF EXISTS palk.palk_oper;

CREATE TABLE palk.palk_oper
(
  id          SERIAL                               NOT NULL
    CONSTRAINT palk_oper_pkey
    PRIMARY KEY,
  parentid    INTEGER,
  rekvid      INTEGER,
  libid       INTEGER,
  lepingid    INTEGER,
  kpv         DATE DEFAULT ('now' :: TEXT) :: DATE NOT NULL,
  summa       NUMERIC(12, 4) DEFAULT 0             NOT NULL,
  doklausid   INTEGER,
  journalid   INTEGER,
  journal1id  INTEGER,
  muud        TEXT,
  kood1       VARCHAR(20) DEFAULT space(20)        NOT NULL,
  kood2       VARCHAR(20) DEFAULT space(20)        NOT NULL,
  kood3       VARCHAR(20) DEFAULT space(20)        NOT NULL,
  kood4       VARCHAR(20) DEFAULT space(20)        NOT NULL,
  kood5       VARCHAR(20) DEFAULT space(20)        NOT NULL,
  konto       VARCHAR(20) DEFAULT space(20)        NOT NULL,
  tp          VARCHAR(20) DEFAULT space(20)        NOT NULL,
  tunnus      VARCHAR(20) DEFAULT space(20)        NOT NULL,
  proj        VARCHAR(20) DEFAULT space(1)         NOT NULL,
  palk_lehtid INTEGER,
  tulumaks    NUMERIC(18, 2),
  sotsmaks    NUMERIC(18, 2),
  tootumaks   NUMERIC(18, 2),
  pensmaks    NUMERIC(18, 2),
  tulubaas    NUMERIC(18, 2),
  tka         NUMERIC(18, 2),
  period      DATE,
  pohjus      VARCHAR(20),
  ajalugu     JSONB,
  properties  JSONB,
  TIMESTAMP   TIMESTAMP                            NOT NULL DEFAULT now() :: DATE
);
CREATE INDEX ix_palk_oper
  ON palk.palk_oper (rekvid);
CREATE INDEX ix_palk_oper_1
  ON palk.palk_oper (libid);
CREATE INDEX palk_oper_lepingid
  ON palk.palk_oper (lepingid);
CREATE INDEX ix_palk_oper_kpv
  ON palk.palk_oper (kpv);
CREATE INDEX palk_oper_journalid
  ON palk.palk_oper (journalid);
