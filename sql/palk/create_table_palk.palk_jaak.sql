DROP TABLE IF EXISTS palk_palk_jaak;

CREATE TABLE palk.palk_jaak
(
  id         SERIAL                   NOT NULL
    CONSTRAINT palk_jaak_pkey
    PRIMARY KEY,
  lepingid   INTEGER DEFAULT 0        NOT NULL,
  kuu        SMALLINT DEFAULT 1       NOT NULL,
  aasta      SMALLINT DEFAULT year()  NOT NULL,
  jaak       NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  arvestatud NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  kinni      NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  tki        NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  tka        NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  pm         NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  tulumaks   NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  sotsmaks   NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  muud       NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  g31        NUMERIC(12, 4) DEFAULT 0 NOT NULL
);
CREATE INDEX palk_jaak_lepingid
  ON palk.palk_jaak (lepingid);
CREATE INDEX palk_jaak_period
  ON palk.palk_jaak (kuu, aasta);


DROP RULE IF EXISTS palk_jaak_insert_2020 ON palk.palk_jaak;
CREATE RULE palk_jaak_insert_2020 AS ON INSERT TO palk.palk_jaak
  WHERE aasta <= 2020
  DO INSTEAD NOTHING;

DROP RULE IF EXISTS palk_jaak_2020 ON palk.palk_jaak;
CREATE RULE palk_jaak_2020 AS ON DELETE TO palk.palk_jaak
  WHERE aasta = 2020
    AND kuu = 12
  DO INSTEAD NOTHING;

