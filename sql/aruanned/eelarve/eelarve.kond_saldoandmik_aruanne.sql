DROP FUNCTION IF EXISTS eelarve.kond_saldoandmik_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER );
DROP FUNCTION IF EXISTS eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER );

CREATE OR REPLACE FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER)
  RETURNS TABLE(
    rekv_id  INTEGER,
    konto    VARCHAR(20),
    tp       VARCHAR(20),
    tegev    VARCHAR(20),
    allikas  VARCHAR(20),
    rahavoog VARCHAR(20),
    deebet   NUMERIC(14, 2),
    kreedit  NUMERIC(14, 2),
    tyyp     INTEGER
  ) AS
$BODY$
SELECT
  rekvid,
  konto,
  tp,
  tegev,
  allikas,
  rahavoo,
  db as deebet,
  kr as kreedit,
  tyyp
FROM eelarve.saldoandmik s
WHERE aasta = year(l_kpv) AND kuu = month(l_kpv)
      AND (l_rekvid  = 999 or  s.rekvid IN (SELECT rekv_id
                        FROM get_asutuse_struktuur(l_rekvid))
);

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

SELECT *
FROM eelarve.kond_saldoandmik_aruanne('2018-01-31' :: DATE, 999 :: INTEGER)
