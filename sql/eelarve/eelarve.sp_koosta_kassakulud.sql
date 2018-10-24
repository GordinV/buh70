DROP FUNCTION IF EXISTS eelarve.sp_koosta_kassakulud(user_id INTEGER, params JSON );

CREATE FUNCTION eelarve.sp_koosta_kassakulud(
      user_id       INTEGER,
      params        JSON,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  l_rekv_id INTEGER = params ->> 'rekvid';
  l_kpv     DATE = params ->> 'kpv';
  l_tyyp    INTEGER = params ->> 'type';

  lcOmaTp   VARCHAR;
  v_kulud   RECORD;
  ldKpv1    DATE;
  l_id      INTEGER;

  lnSummaDb NUMERIC(18, 6);
  lnSummaKr NUMERIC(18, 6);
  l_params  JSON;
  v_data    RECORD;
BEGIN

  --if tnTyyp = 1 then
  -- re-arvesta kassakulud

  --	raise notice 'Kustutan vana andmed ';
  DELETE FROM eelarve.aasta_kassa_kulud
  WHERE aasta = year(l_kpv) AND kuu = month(l_kpv) AND rekvid = l_rekv_id;

  DELETE FROM eelarve.eeltaitmine
  WHERE aasta = year(l_kpv) AND kuu = month(l_kpv) AND rekvid = l_rekv_id;

  -- Kontrolin kas arvestame saldoandmik uuesti

  IF exists(SELECT 1
            FROM eelarve.aasta_kassa_kulud
            WHERE aasta = year(l_kpv) AND kuu = month(l_kpv) AND rekvid = l_rekv_id)
  THEN
    error_message = 'Ei saa kustuta vana andmed ';
    error_code = 1;
    result = 0;
    RETURN;
  END IF;

  lcOmaTp = fnc_getomatp(l_rekv_id, year(l_kpv));

  -- Kassakulud koostamine
  ldKpv1 = date(year(l_kpv), 01, 01);

  FOR v_kulud IN
  SELECT *
  FROM cur_kulude_kassa_taitmine
  WHERE aasta = year(l_kpv) AND kuu = month(l_kpv) AND rekvid = l_rekv_id AND left(artikkel, 1) <> '3'
  LOOP
    SELECT
      0                AS id,
      v_kulud.summa    AS summa,
      'EUR'            AS valuuta,
      1                AS kuurs,
      v_kulud.tegev,
      v_kulud.allikas  AS allikas,
      v_kulud.artikkel AS artikkel,
      l_kpv            AS kpv,
      l_rekv_id        AS rekvid
    INTO v_data;

    l_params = row_to_json(row) FROM ( SELECT 0 AS id, v_data AS DATA ) ROW;

    l_id = eelarve.sp_salvesta_aastakassakulud(l_params, user_id, l_rekv_id);

    result = result + 1;

  END LOOP;

  FOR v_kulud IN
  SELECT *
  FROM cur_tulude_kassa_taitmine
  WHERE aasta = year(l_kpv) AND kuu = month(l_kpv) AND rekvid = l_rekv_id
        AND artikkel NOT IN (SELECT DISTINCT kood5
                             FROM eelarve.eeltaitmine
                             WHERE aasta = year(l_kpv) AND kuu = month(l_kpv) AND rekvid = l_rekv_id)

  LOOP

    SELECT
      0                AS id,
      v_kulud.summa    AS summa,
      'EUR'            AS valuuta,
      1                AS kuurs,
      v_kulud.tegev,
      v_kulud.allikas  AS allikas,
      v_kulud.artikkel AS artikkel,
      l_kpv            AS kpv,
      l_rekv_id        AS rekvid
    INTO v_data;

    l_params = row_to_json(row) FROM ( SELECT 0 AS id, v_data AS DATA ) ROW;
    l_id = eelarve.sp_salvesta_aastakassakulud(l_params, user_id, l_rekv_id);

    result = result + 1;
  END LOOP;

  --  INTO lnSummaDb

  SELECT
    sum(j1.summa)
      FILTER (WHERE j1.deebet LIKE '710000%' AND j1.lisa_d <> '18510101')                           AS summa_db,
    sum(j1.summa)
      FILTER (WHERE (kreedit IN ('203850', '350000') OR kreedit LIKE '103%') AND kood5 = '3500.00') AS summa_kr
  INTO lnSummaDb, lnSummaKr
  FROM docs.Journal j
    INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
  WHERE j.rekvid = l_rekv_id
        AND year(j.kpv) = year(l_kpv) AND month(j.kpv) = month(l_kpv);


  SELECT
    0                                               AS id,
    coalesce(lnSummaDb, 0) - coalesce(lnSummaKr, 0) AS summa,
    'EUR'                                           AS valuuta,
    1                                               AS kuurs,
    '',
    ''                                              AS allikas,
    '3500, 352'                                     AS artikkel,
    l_kpv                                           AS kpv,
    l_rekv_id                                       AS rekvid
  INTO v_data;

  l_params = row_to_json(row) FROM ( SELECT 0 AS id, v_data AS DATA ) ROW;
  l_id = eelarve.sp_salvesta_aastakassakulud(l_params, user_id, l_rekv_id);

  result = coalesce(result, 0) + 1;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_message = SQLERRM;
    result = 0;
    error_code = 1;
    RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION eelarve.sp_koosta_kassakulud(user_id INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_koosta_kassakulud(user_id INTEGER, params JSON) TO dbpeakasutaja;

SELECT eelarve.sp_koosta_kassakulud(1, '{
  "kpv": "2018-03-21",
  "rekvid": 1
}' :: JSON)


/*
select * from eelarve.a
 */