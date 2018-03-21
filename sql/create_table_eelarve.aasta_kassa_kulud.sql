DROP TABLE IF EXISTS eelarve.aasta_kassa_kulud;

CREATE TABLE eelarve.aasta_kassa_kulud
(
  id      SERIAL                                         NOT NULL,
  summa   NUMERIC(18, 8) DEFAULT 0                       NOT NULL,
  valuuta VARCHAR(20) DEFAULT 'EUR'                      NOT NULL,
  kuurs   NUMERIC(8, 4) DEFAULT 1                        NOT NULL,
  tegev   VARCHAR(20),
  allikas VARCHAR(20),
  art     VARCHAR(20),
  kpv     DATE    DEFAULT date(),
  aasta   INTEGER DEFAULT year(date()),
  rekvid  INTEGER,
  omatp   VARCHAR(20),
  tyyp    INTEGER DEFAULT 0,
  kuu     INTEGER DEFAULT 0
);

CREATE INDEX ix_aasta_kassa_kulud_period
  ON eelarve.aasta_kassa_kulud (kuu, aasta);

CREATE INDEX ix_aasta_kassa_kulud_rekvid
  ON eelarve.aasta_kassa_kulud (rekvid);