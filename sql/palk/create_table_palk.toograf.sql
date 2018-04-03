DROP TABLE IF EXISTS palk.toograf;
CREATE TABLE palk.toograf
(
  id         SERIAL                                         NOT NULL
    CONSTRAINT toograf_pkey
    PRIMARY KEY,
  lepingid   INTEGER                                        NOT NULL,
  kuu        INTEGER DEFAULT month(('now' :: TEXT) :: DATE) NOT NULL,
  aasta      INTEGER DEFAULT year(('now' :: TEXT) :: DATE)  NOT NULL,
  tund       NUMERIC(12, 4)                                          DEFAULT 0,
  muud       TEXT,
  ajalugu    JSONB,
  properties JSONB,
  status     DOK_STATUS                                     NOT NULL DEFAULT 'active',
  TIMESTAMP  TIMESTAMP                                      NOT NULL DEFAULT now()
);

CREATE INDEX toograf_lepingid_idx
  ON palk.toograf (lepingid, kuu, aasta);
