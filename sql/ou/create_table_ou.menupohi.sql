DROP TABLE IF EXISTS ou.menupohi;

CREATE TABLE ou.menupohi
(
  id         SERIAL                        NOT NULL
    CONSTRAINT menupohi_pkey
    PRIMARY KEY,
  pad        TEXT                          NOT NULL,
  bar        TEXT                          NOT NULL,
  idx        INTEGER DEFAULT 0             NOT NULL,
  properties JSONB,
  status dok_status default 'active'
);


CREATE INDEX menupohi_pad_index
  ON ou.menupohi (pad, bar);

CREATE INDEX menupohi_status_index
  ON ou.menupohi (status)
  where status = 'active';
