-- remote table

DROP FOREIGN TABLE IF EXISTS remote_saldoandmik;

CREATE FOREIGN TABLE remote_saldoandmik (
  id      INTEGER                NOT NULL,
  nimetus CHARACTER VARYING(254) NOT NULL DEFAULT space(1),
  db      NUMERIC(12, 2)         NOT NULL DEFAULT 0,
  kr      NUMERIC(12, 2)         NOT NULL DEFAULT 0,
  konto   CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  tegev   CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  tp      CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  allikas CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  rahavoo CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  kpv     DATE                            DEFAULT date(),
  aasta   INTEGER                         DEFAULT year(date()),
  rekvid  INTEGER,
  omatp   CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  tyyp    INTEGER                         DEFAULT 0,
  kuu     INTEGER                         DEFAULT 0
)
SERVER db_narva_ee
OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'saldoandmik'
)
;

CREATE FOREIGN TABLE remote_saldoandmik_2019 (
  id      INTEGER                NOT NULL,
  nimetus CHARACTER VARYING(254) NOT NULL DEFAULT space(1),
  db      NUMERIC(12, 2)         NOT NULL DEFAULT 0,
  kr      NUMERIC(12, 2)         NOT NULL DEFAULT 0,
  konto   CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  tegev   CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  tp      CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  allikas CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  rahavoo CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  kpv     DATE                            DEFAULT date(),
  aasta   INTEGER                         DEFAULT year(date()),
  rekvid  INTEGER,
  omatp   CHARACTER VARYING(20)  NOT NULL DEFAULT space(1),
  tyyp    INTEGER                         DEFAULT 0,
  kuu     INTEGER                         DEFAULT 0
  )
  SERVER dbarch_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'saldoandmik'
  );

--DELETE from eelarve.saldoandmik;
DELETE from eelarve.saldoandmik
where aasta = 2020 and kuu = 12;

-- 2019
INSERT INTO eelarve.saldoandmik (rekvid, nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, kpv, aasta, omatp, tyyp, kuu)
SELECT
  rekvid,
  nimetus,
  db,
  kr,
  konto,
  tegev,
  tp,
  allikas,
  rahavoo,
  kpv,
  aasta,
  omatp,
  tyyp,
  kuu
FROM remote_saldoandmik_2019
where aasta = 2020 and kuu = 12
;

INSERT INTO eelarve.saldoandmik (rekvid, nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, kpv, aasta, omatp, tyyp, kuu)
  SELECT
    rekvid,
    nimetus,
    db,
    kr,
    konto,
    tegev,
    tp,
    allikas,
    rahavoo,
    kpv,
    aasta,
    omatp,
    tyyp,
    kuu
  FROM remote_saldoandmik
where aasta = 2020 and kuu = 12
;

DROP RULE IF EXISTS saldoandmik_2020_delete ON eelarve.saldoandmik;
CREATE RULE saldoandmik_2020_delete AS ON DELETE TO eelarve.saldoandmik
  WHERE aasta <= 2020
  DO INSTEAD NOTHING;

DROP RULE IF EXISTS saldoandmik_2020_insert ON eelarve.saldoandmik;
CREATE RULE saldoandmik_2020_insert AS ON DELETE TO eelarve.saldoandmik
  WHERE aasta <= 2020
  DO INSTEAD NOTHING;


select * from eelarve.saldoandmik where aasta = 2019 and kuu = 12