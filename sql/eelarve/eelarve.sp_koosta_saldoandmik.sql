DROP FUNCTION IF EXISTS eelarve.sp_koosta_saldoandmik( INTEGER, JSON );

CREATE OR REPLACE FUNCTION eelarve.sp_koosta_saldoandmik(
  IN  user_id       INTEGER,
  IN  params        JSON,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  l_rekvid INTEGER = coalesce((params ->> 'rekvid') :: INTEGER, (SELECT rekvid
                                                                 FROM ou.userid
                                                                 WHERE id = user_id));
  l_kpv    DATE = params ->> 'kpv';
  l_kpv1   DATE = date(year(l_kpv), month(l_kpv), 1);
  l_kpv2   DATE = gomonth(l_kpv1, 1) - 1;
  l_tyyp   INTEGER = coalesce((params ->> 'tyyp') :: INTEGER, 1);
  v_rekv   RECORD;
  l_oma_tp TEXT = fnc_getomatp(L_rekvid, year(l_kpv));
  l_params JSON;

BEGIN
  IF NOT empty(l_tyyp)
  THEN
    -- re-arvesta saldoandmik
    DELETE FROM eelarve.saldoandmik
    WHERE aasta = year(l_kpv) AND kuu = month(l_kpv);
  END IF;

  -- Kontrolin kas arvestame saldoandmik uuesti

  IF NOT exists(SELECT id
                FROM eelarve.saldoandmik
                WHERE aasta = year(l_kpv) AND kuu = month(l_kpv))
  THEN

    FOR v_rekv IN
    SELECT id
    FROM ou.rekv
    WHERE parentid <> 9999 AND id NOT IN (123, 116, 122)
    LOOP
      l_oma_tp = fnc_getomatp(L_rekvid, year(l_kpv));
      INSERT INTO eelarve.saldoandmik (nimetus, db, kr, konto, tegev, tp, allikas, rahavoo, kpv, aasta, kuu, rekvid, omatp, tyyp)
        SELECT
          l.nimetus,
          qry.deebet,
          qry.kreedit,
          qry.konto,
          qry.tegev,
          qry.tp,
          qry.allikas,
          qry.rahavoog,
          l_kpv,
          year(l_kpv),
          month(l_kpv),
          v_rekv.id,
          l_oma_tp,
          0
        FROM eelarve.saldoandmik_aruanne(l_kpv1, l_kpv2, l_rekvid) qry
          LEFT OUTER JOIN com_kontoplaan l ON l.kood = qry.konto
        WHERE qry.rekv_id = l_rekvid;

      -- kassakulud
      l_params = row_to_json(row) FROM ( SELECT l_kpv AS kpv,
      l_rekvid AS rekvid ) ROW;

      PERFORM eelarve.sp_koosta_kassakulud(v_rekv.id, l_params :: JSON);
    END LOOP;


  ELSE
    result = 0;
    error_message = 'Andmed on olemas, vajalik kustuta ära';
    RETURN;
  END IF;

  result = 1;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_message = SQLERRM;
    result = 0;
    RETURN;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION eelarve.sp_koosta_saldoandmik(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_koosta_saldoandmik(INTEGER, JSON) TO dbpeakasutaja;

/*
select error_code, result, error_message from eelarve.sp_koosta_saldoandmik(1,'{"kpv":"2018-01-31"}'::json)
*/