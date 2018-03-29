DROP TABLE IF EXISTS palk.puudumine;

CREATE TABLE palk.puudumine
(
  id         SERIAL                               NOT NULL
    CONSTRAINT puudumine_pkey
    PRIMARY KEY,
  kpv1       DATE DEFAULT ('now' :: TEXT) :: DATE NOT NULL,
  kpv2       DATE DEFAULT ('now' :: TEXT) :: DATE NOT NULL,
  paevad     INTEGER DEFAULT 0                    NOT NULL,
  summa      NUMERIC(12, 4) DEFAULT 0             NOT NULL,
  tunnus     INTEGER DEFAULT 0                    NOT NULL,
  tyyp       INTEGER DEFAULT 0                    NOT NULL,
  muud       TEXT,
  libid      INTEGER DEFAULT 0,
  lepingid   INTEGER,
  ajalugu    JSONB,
  properties JSONB
);
CREATE INDEX puudumine_libid
  ON palk.puudumine (tunnus, tyyp);
CREATE INDEX puudumine_tunnus
  ON palk.puudumine (tyyp, tunnus);
