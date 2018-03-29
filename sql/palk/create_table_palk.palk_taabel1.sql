DROP TABLE IF EXISTS palk.palk_taabel1;

CREATE TABLE palk.palk_taabel1
(
  id         SERIAL                                          NOT NULL
    CONSTRAINT palk_taabel1_pkey
    PRIMARY KEY,
  lepingid   INTEGER DEFAULT 0                               NOT NULL,
  kuu        SMALLINT DEFAULT month(('now' :: TEXT) :: DATE) NOT NULL,
  aasta      SMALLINT DEFAULT year(('now' :: TEXT) :: DATE)  NOT NULL,
  muud       TEXT,
  kokku      NUMERIC(12, 4)                                           DEFAULT 0,
  too        NUMERIC(12, 4)                                           DEFAULT 0,
  paev       NUMERIC(12, 4)                                           DEFAULT 0,
  ohtu       NUMERIC(12, 4)                                           DEFAULT 0,
  oo         NUMERIC(12, 4)                                           DEFAULT 0,
  tahtpaev   NUMERIC(12, 4)                                           DEFAULT 0,
  puhapaev   NUMERIC(12, 4)                                           DEFAULT 0,
  uleajatoo  NUMERIC(12, 4)                                           DEFAULT 0,
  ajalugu    JSONB,
  properties JSONB,
  TIMESTAMP  TIMESTAMP                                       NOT NULL DEFAULT now() :: DATE
);
CREATE INDEX ix_palk_taabel1_lepingid
  ON palk.palk_taabel1 (lepingid);
CREATE INDEX palk_taabel1_period
  ON palk.palk_taabel1 (kuu, aasta);
