DROP TABLE IF EXISTS palk.palk_oper CASCADE;

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
  tululiik    VARCHAR(20),
  kood1       VARCHAR(20),
  kood2       VARCHAR(20),
  kood3       VARCHAR(20),
  kood4       VARCHAR(20),
  kood5       VARCHAR(20),
  konto       VARCHAR(20),
  tp          VARCHAR(20),
  tunnus      VARCHAR(20),
  proj        VARCHAR(20),
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


CREATE INDEX palk_oper_makse_kpv
    ON palk.palk_oper (jsonb_extract_path_text(properties, 'maksekpv'));

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE palk.palk_oper TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE palk.palk_oper TO dbkasutaja;
GRANT all ON TABLE palk.palk_oper TO dbadmin;
GRANT SELECT ON TABLE palk.palk_oper TO dbvaatleja;


