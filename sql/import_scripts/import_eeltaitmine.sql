-- remote table

DROP FOREIGN TABLE IF EXISTS remote_eeltaitmine;

CREATE FOREIGN TABLE remote_eeltaitmine (
  id     SERIAL         NOT NULL,
  rekvid INTEGER        NOT NULL,
  aasta  SMALLINT       NOT NULL DEFAULT 0,
  kuu    SMALLINT       NOT NULL DEFAULT 0,
  kood1  CHARACTER(20)  NOT NULL DEFAULT space(20),
  kood2  CHARACTER(20)  NOT NULL DEFAULT space(20),
  kood3  CHARACTER(20)  NOT NULL DEFAULT space(20),
  kood4  CHARACTER(20)  NOT NULL DEFAULT space(20),
  kood5  CHARACTER(20)  NOT NULL DEFAULT space(20),
  objekt CHARACTER(20)  NOT NULL DEFAULT space(20),
  proj   CHARACTER(20)  NOT NULL DEFAULT space(20),
  summa  NUMERIC(14, 2) NOT NULL DEFAULT 0,
  muud   TEXT
)
SERVER db_narva_ee
OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'eeltaitmine'
);

DELETE FROM eelarve.eeltaitmine;

INSERT INTO eelarve.eeltaitmine (rekvid, aasta, kuu, kood1, kood2, kood4, kood5, proj, objekt, summa)
  SELECT
    rekvid,
    aasta,
    kuu,
    kood1,
    kood2,
    kood4,
    kood5,
    proj,
    objekt,
    summa
  FROM remote_eeltaitmine;

DROP FOREIGN TABLE IF EXISTS remote_eeltaitmine;
