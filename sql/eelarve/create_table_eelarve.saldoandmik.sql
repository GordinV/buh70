DROP TABLE if exists eelarve.saldoandmik;

CREATE TABLE eelarve.saldoandmik
(
  id serial NOT NULL,
  nimetus character varying(254) NOT NULL DEFAULT space(1),
  db numeric(12,2) NOT NULL DEFAULT 0,
  kr numeric(12,2) NOT NULL DEFAULT 0,
  konto character varying(20) NOT NULL DEFAULT space(1),
  tegev character varying(20) NOT NULL DEFAULT space(1),
  tp character varying(20) NOT NULL DEFAULT space(1),
  allikas character varying(20) NOT NULL DEFAULT space(1),
  rahavoo character varying(20) NOT NULL DEFAULT space(1),
  kpv date DEFAULT date(),
  aasta integer DEFAULT year(date()),
  rekvid integer,
  omatp character varying(20) NOT NULL DEFAULT space(1),
  tyyp integer DEFAULT 0,
  kuu integer DEFAULT 0
)
WITH (OIDS=FALSE);

ALTER table eelarve.saldoandmik ADD COLUMN timestamp timestamp not null DEFAULT now();


GRANT SELECT ON TABLE eelarve.saldoandmik TO dbvaatleja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE eelarve.saldoandmik TO saldoandmikkoostaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE eelarve.saldoandmik TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE eelarve.saldoandmik TO dbkasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE eelarve.saldoandmik TO eelaktsepterja;

-- Index: ix_saldoandmik_period

-- DROP INDEX ix_saldoandmik_period;

CREATE INDEX idx_saldoandmik_period
  ON eelarve.saldoandmik
  USING btree
  (kuu, aasta);

CREATE INDEX idx_saldoandmik_rekvid
  ON eelarve.saldoandmik
  USING btree
  (rekvid);

