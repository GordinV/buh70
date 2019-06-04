DROP FUNCTION IF EXISTS eelarve.kond_saldoandmik_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER );
DROP FUNCTION IF EXISTS eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER );

CREATE OR REPLACE FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER)
  RETURNS TABLE(
    konto    VARCHAR(20),
    nimetus  VARCHAR(254),
    tp       VARCHAR(20),
    tegev    VARCHAR(20),
    allikas  VARCHAR(20),
    rahavoog VARCHAR(20),
    deebet   NUMERIC(14, 2),
    kreedit  NUMERIC(14, 2),
    tyyp     INTEGER
  ) AS
$BODY$

-- rekvid  = 999 (kond)

SELECT
  s.konto,
  coalesce(k.nimetus, '') :: VARCHAR(254) AS nimetus,
  s.tp,
  s.tegev,
  s.allikas,
  s.rahavoo,
  sum(s.db)                               AS deebet,
  sum(s.kr)                               AS kreedit,
  s.tyyp
FROM eelarve.saldoandmik s
  LEFT OUTER JOIN com_kontoplaan k ON k.kood = s.konto
WHERE s.aasta = year(l_kpv)
      AND s.kuu = month(l_kpv)
      AND s.rekvid = l_rekvid

GROUP BY s.konto, k.nimetus, s.tp, s.tegev, s.allikas, s.rahavoo, s.tyyp;

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION eelarve.kond_saldoandmik_aruanne(l_kpv DATE, l_rekvid INTEGER) TO PUBLIC ;
/*

SELECT *
FROM eelarve.kond_saldoandmik_aruanne('2018-09-30' :: DATE, 999 :: INTEGER)
*/