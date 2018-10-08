DROP TABLE IF EXISTS palk.palk_kaart;

CREATE TABLE palk.palk_kaart
(
  id         SERIAL                   NOT NULL
    CONSTRAINT palk_kaart_pkey
    PRIMARY KEY,
  parentid   INTEGER,
  lepingid   INTEGER,
  libid      INTEGER,
  summa      NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  percent_   SMALLINT DEFAULT 1       NOT NULL,
  tulumaks   SMALLINT DEFAULT 1       NOT NULL,
  tulumaar   SMALLINT DEFAULT 26      NOT NULL,
  status     SMALLINT DEFAULT 1       NOT NULL,
  alimentid  INTEGER DEFAULT 0        NOT NULL,
  tunnus     TEXT,
  minsots    INTEGER,
  muud       TEXT,
  ajalugu    JSONB,
  properties JSONB,
  TIMESTAMP TIMESTAMP not null default now()
);
CREATE INDEX palk_kaart_parentid_idx
  ON palk.palk_kaart (parentid);
CREATE INDEX palk_kaart_lepingid
  ON palk.palk_kaart (lepingid);
CREATE INDEX palk_kaart_libid
  ON palk.palk_kaart (libid);

drop index if exists palk.palk_kaart_status ;

CREATE  INDEX palk_kaart_status
  ON palk.palk_kaart USING BTREE
  (status)
  WHERE (status <> 3)
