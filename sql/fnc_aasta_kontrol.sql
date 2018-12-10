DROP FUNCTION IF EXISTS ou.fnc_aasta_kontrol(INTEGER, DATE);

CREATE OR REPLACE FUNCTION ou.fnc_aasta_kontrol(l_rekvid INTEGER, l_kpv DATE)
  RETURNS BOOLEAN AS
$BODY$

BEGIN
  IF NOT exists(SELECT id FROM ou.aasta WHERE kuu = month(l_kpv) AND aasta = year(l_kpv) AND rekvid = l_rekvid)
  THEN
    INSERT INTO ou.aasta (rekvid, aasta, kuu, kinni)
    VALUES (l_rekvid, year(l_kpv), month(l_kpv), 0);
  END IF;

  IF exists(
      SELECT id FROM ou.aasta WHERE kuu = month(l_kpv) AND aasta = year(l_kpv) AND rekvid = l_rekvid AND kinni = 1)
  THEN
    --    RAISE EXCEPTION 'Ei tohi selles periodis töötada';
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END;
$BODY$
  LANGUAGE 'plpgsql'
  VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION ou.fnc_aasta_kontrol(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.fnc_aasta_kontrol(INTEGER, DATE) TO dbpeakasutaja;
