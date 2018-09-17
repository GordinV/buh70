-- remote table

DROP FOREIGN TABLE IF EXISTS remote_aastakassakulud;

CREATE FOREIGN TABLE remote_aastakassakulud (
  id      SERIAL                NOT NULL,
  summa   NUMERIC(18, 8)        NOT NULL DEFAULT 0,
  valuuta CHARACTER VARYING(20) NOT NULL DEFAULT 'EEK' :: CHARACTER VARYING,
  kuurs   NUMERIC(8, 4)         NOT NULL DEFAULT 1,
  tegev   CHARACTER VARYING(20) NOT NULL DEFAULT space(1),
  allikas CHARACTER VARYING(20) NOT NULL DEFAULT space(1),
  art     CHARACTER VARYING(20) NOT NULL DEFAULT space(1),
  kpv     DATE                           DEFAULT date(),
  aasta   INTEGER                        DEFAULT year(date()),
  rekvid  INTEGER,
  omatp   CHARACTER VARYING(20) NOT NULL DEFAULT space(1),
  tyyp    INTEGER                        DEFAULT 0,
  kuu     INTEGER                        DEFAULT 0
)
SERVER db_narva_ee
OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'aastakassakulud'
);

DELETE FROM eelarve.aasta_kassa_kulud;

INSERT INTO eelarve.aasta_kassa_kulud (summa, valuuta, kuurs, tegev, allikas, art, kpv, aasta, kuu, rekvid, omatp, tyyp)

  SELECT
    summa,
    valuuta,
    kuurs,
    tegev,
    allikas,
    art,
    kpv,
    aasta,
    kuu,
    rekvid,
    omatp,
    tyyp
  FROM remote_aastakassakulud;

DROP FOREIGN TABLE IF EXISTS remote_aastakassakulud;
