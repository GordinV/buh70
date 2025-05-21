DROP TABLE IF EXISTS palk.puudumine;

CREATE TABLE palk.puudumine
(
  id              SERIAL                               NOT NULL
    CONSTRAINT puudumine_pkey
    PRIMARY KEY,
  kpv1            DATE DEFAULT ('now' :: TEXT) :: DATE NOT NULL,
  kpv2            DATE DEFAULT ('now' :: TEXT) :: DATE NOT NULL,
  paevad          INTEGER DEFAULT 0                    NOT NULL,
  summa           NUMERIC(12, 4) DEFAULT 0             NOT NULL,
  puudumiste_liik PUUDUMISTE_LIIGID                    NOT NULL,
  tyyp            INTEGER DEFAULT 0                    NOT NULL,
  muud            TEXT,
  libid           INTEGER DEFAULT 0,
  lepingid        INTEGER,
  status          DOK_STATUS                           NOT NULL,
  ajalugu         JSONB,
  properties      JSONB
);
CREATE INDEX puudumine_libid
  ON palk.puudumine (libid);

CREATE INDEX puudumine_lepingid
  ON palk.puudumine (lepingid);

alter table palk.puudumine add COLUMN if not exists puudumiste_liik PUUDUMISTE_LIIGID;