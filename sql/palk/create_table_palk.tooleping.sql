DROP TABLE IF EXISTS libs.tooleping;
DROP TABLE IF EXISTS palk.tooleping;

CREATE TABLE palk.tooleping
(
  id          SERIAL                                                         NOT NULL
    CONSTRAINT tooleping_pkey
    PRIMARY KEY,
  parentid    INTEGER                                                        NOT NULL,
  osakondid   INTEGER,
  ametid      INTEGER,
  algab       DATE DEFAULT ('now') :: DATE                                   NOT NULL,
  lopp        DATE,
  palk        NUMERIC(12, 4) DEFAULT 0                                       NOT NULL,
  palgamaar   SMALLINT DEFAULT 0                                             NOT NULL,
  pohikoht    SMALLINT DEFAULT 1                                             NOT NULL,
  ametnik     SMALLINT DEFAULT 0                                             NOT NULL,
  tasuliik    SMALLINT DEFAULT 1                                             NOT NULL,
  pank        SMALLINT DEFAULT 0                                             NOT NULL,
  aa          VARCHAR(16) DEFAULT public.space(1)                            NOT NULL,
  muud        TEXT,
  rekvid      INTEGER                                                        NOT NULL,
  resident    INTEGER DEFAULT 1                                              NOT NULL,
  riik        VARCHAR(3) DEFAULT public.space(1)                             NOT NULL,
  toend       DATE,
  vanaid      INTEGER,
  vanakoormus NUMERIC(12, 4),
  koormus     NUMERIC(12, 4),
  vanatoopaev INTEGER,
  toopaev     NUMERIC(12, 4) DEFAULT 0                                       NOT NULL,
  properties  JSONB,
  ajalugu     JSONB,
  TIMESTAMP   TIMESTAMP DEFAULT now()                                        NOT NULL
);
CREATE INDEX parentid_idx
  ON palk.tooleping (parentid);
CREATE INDEX tooleping_osakondid
  ON palk.tooleping (osakondid);
CREATE INDEX tooleping_ametid
  ON palk.tooleping (ametid);
CREATE INDEX "tooleping_rekvId_idx"
  ON palk.tooleping (rekvid);
