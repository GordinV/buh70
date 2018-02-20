DROP TABLE IF EXISTS docs.doklausend CASCADE;
CREATE TABLE docs.doklausend
(
  id         SERIAL                        NOT NULL
    CONSTRAINT doklausend_pkey
    PRIMARY KEY,
  parentid   INTEGER                       NOT NULL,
  summa      NUMERIC(12, 4) DEFAULT 0      NOT NULL,
  muud       TEXT,
  kood1      VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood2      VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood3      VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood4      VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood5      VARCHAR(20) DEFAULT space(20) NOT NULL,
  deebet     VARCHAR(20) DEFAULT space(20) NOT NULL,
  kreedit    VARCHAR(20) DEFAULT space(20) NOT NULL,
  lisa_d     VARCHAR(20) DEFAULT space(20) NOT NULL,
  lisa_k     VARCHAR(20) DEFAULT space(20) NOT NULL,
  properties JSONB
);

drop index if exists doklausend_parentid;

CREATE INDEX doklausend_parentid
  ON docs.doklausend (parentid);
