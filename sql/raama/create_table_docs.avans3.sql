DROP TABLE IF EXISTS docs.avans3;

CREATE TABLE docs.avans3
(
  id       SERIAL            NOT NULL
    CONSTRAINT avans3_pkey
    PRIMARY KEY,
  parentid INTEGER           NOT NULL,
  dokid    INTEGER           NOT NULL,
  liik     INTEGER DEFAULT 1 NOT NULL,
  muud     TEXT,
  summa    NUMERIC(14, 2) DEFAULT 0
);

DROP INDEX IF EXISTS avans3_idx1;

CREATE INDEX avans3_idx1
  ON docs.avans3 (parentid);

DROP INDEX IF EXISTS avans3_idx2;

CREATE INDEX avans3_idx2
  ON docs.avans3 (dokid, liik);
