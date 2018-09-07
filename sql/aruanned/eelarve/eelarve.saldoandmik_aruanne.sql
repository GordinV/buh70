DROP FUNCTION IF EXISTS eelarve.saldoandmik_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER );

CREATE OR REPLACE FUNCTION eelarve.saldoandmik_aruanne(l_kpv1 DATE, l_kpv2 DATE, l_rekvid INTEGER)
  RETURNS TABLE(
    rekv_id  INTEGER,
    konto    VARCHAR(20),
    tp       VARCHAR(20),
    tegev    VARCHAR(20),
    allikas  VARCHAR(20),
    rahavoog VARCHAR(20),
    artikkel VARCHAR(20),
    deebet   NUMERIC(14, 2),
    kreedit  NUMERIC(14, 2),
    tyyp     INTEGER
  ) AS
$BODY$
WITH qrySaldoAndmik AS (
  SELECT
    j.kpv,
    j.rekvid,
    j1.deebet                         AS konto,
    CASE WHEN empty(l.tun1) OR left(l.kood, 3) IN ('154', '155', '156')
      THEN ''
    ELSE j1.lisa_d END :: VARCHAR(20) AS tp,
    CASE WHEN empty(l.tun2) OR left(l.kood, 3) IN ('154', '155', '156')
      THEN ''
    ELSE j1.kood1 END :: VARCHAR(20)  AS tegev,
    CASE WHEN empty(l.tun3)
      THEN ''
    ELSE j1.kood2 END :: VARCHAR(20)  AS allikas,
    CASE WHEN empty(l.tun4)
      THEN ''
    ELSE j1.kood3 END :: VARCHAR(20)  AS rahavoog,
    CASE WHEN empty(l.tun2)
      THEN ''
    ELSE j1.kood5 END :: VARCHAR(20)  AS artikkel,
    j1.summa                          AS deebet,
    0 :: NUMERIC                      AS kreedit,
    coalesce(l.tun5, 1)               AS tyyp
  FROM docs.doc d
    INNER JOIN docs.journal j ON j.parentid = d.id
    INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
    INNER JOIN libs.library l ON l.library = 'KONTOD' AND l.kood = j1.deebet
  UNION ALL
  SELECT
    j.kpv,
    j.rekvid,
    j1.kreedit                        AS konto,
    CASE WHEN empty(l.tun1) OR left(l.kood, 3) IN ('154', '155', '156')
      THEN ''
    ELSE j1.lisa_k END :: VARCHAR(20) AS tp,
    CASE WHEN empty(l.tun2) OR left(l.kood, 3) IN ('154', '155', '156')
      THEN ''
    ELSE j1.kood1 END :: VARCHAR(20)  AS tegev,
    CASE WHEN empty(l.tun3)
      THEN ''
    ELSE j1.kood2 END :: VARCHAR(20)  AS allikas,
    CASE WHEN empty(l.tun4)
      THEN ''
    ELSE j1.kood3 END :: VARCHAR(20)  AS rahavoog,
    CASE WHEN empty(l.tun2)
      THEN ''
    ELSE j1.kood5 END :: VARCHAR(20)  AS artikkel,
    0 :: NUMERIC                      AS deebet,
    j1.summa                          AS kreedit,
    coalesce(l.tun5, 1)               AS tyyp
  FROM docs.doc d
    INNER JOIN docs.journal j ON j.parentid = d.id
    INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
    INNER JOIN libs.library l ON l.library = 'KONTOD' AND l.kood = j1.kreedit
  WHERE d.rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid))
        AND j.kpv <= l_kpv2
)
SELECT
  rekvid,
  konto,
  tp,
  tegev,
  allikas,
  '00' :: VARCHAR(20) AS rahavoog,
  artikkel,
  sum(deebet)         AS deebet,
  sum(kreedit)        AS kreedit,
  tyyp
FROM qrySaldoAndmik qry
WHERE qry.kpv < l_kpv1
      AND konto NOT IN ('999999', '000000', '888888')
GROUP BY rekvid, konto, tp, tegev, allikas, artikkel, tyyp
UNION ALL
SELECT
  rekvid,
  konto,
  tp,
  tegev,
  allikas,
  rahavoog,
  artikkel,
  sum(deebet)  AS deebet,
  sum(kreedit) AS kreedit,
  tyyp
FROM qrySaldoAndmik qry
WHERE qry.kpv >= l_kpv1
      AND qry.kpv <= l_kpv2
      AND konto NOT IN ('999999', '000000', '888888')

GROUP BY rekvid, konto, tp, tegev, allikas, artikkel, rahavoog, tyyp

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

SELECT *
FROM eelarve.saldoandmik_aruanne('2018-01-01' :: DATE, current_date :: DATE, 1 :: INTEGER)

