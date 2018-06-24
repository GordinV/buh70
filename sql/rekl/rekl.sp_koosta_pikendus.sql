DROP FUNCTION IF EXISTS rekl.sp_koosta_pikendus( INTEGER, JSON );

CREATE FUNCTION rekl.sp_koosta_pikendus(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                        OUT error_code INTEGER, OUT error_message TEXT)

  RETURNS RECORD

LANGUAGE plpgsql
AS $$
DECLARE

  l_id        INTEGER = params ->> 'id';
  l_kpv       DATE = params ->> 'kpv';
  v_luba      RECORD;
  l_alus      TEXT;
  v_toiming   RECORD;
  json_params JSON;
BEGIN
  result = 1;
  SELECT *
  INTO v_luba
  FROM rekl.luba
  WHERE parentid = l_id;

  IF v_luba.staatus = 0
  THEN
    error_message = 'Luba anulleritud';
    error_code = 3;
    RETURN;
  END IF;

  l_alus = 'Dekl. number:' + ltrim(rtrim(v_luba.number)) || ' ' || l_kpv :: TEXT;

  SELECT
    0               AS id,
    0               AS number,
    v_luba.asutusid,
    v_luba.parentid AS lubaid,
    date()          AS kpv,
    0               AS summa,
    l_alus :: TEXT  AS alus,
    NULL :: TEXT    AS ettekirjutus,
    l_kpv           AS tahtaeg,
    'PIKENDUS'      AS tyyp
  INTO v_toiming;

  SELECT row_to_json(row)
  INTO json_params
  FROM (SELECT
          0                      AS id,
          row_to_json(v_toiming) AS data) row;

  result = rekl.sp_salvesta_toiming(json_params, user_id, v_luba.rekvid);

  IF result > 0
  THEN
    UPDATE rekl.luba
    SET loppkpv = l_kpv
    WHERE id = l_id;
  END IF;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_code = 1;
    error_message = SQLERRM;
    result = 0;
    RETURN;

END;
$$;


GRANT EXECUTE ON FUNCTION rekl.sp_koosta_pikendus(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_koosta_pikendus(INTEGER, JSON) TO dbpeakasutaja;

/*
select rekl.sp_koosta_pikendus(1,'{"id":5,"kpv":"2018-06-30"}'::json)
 */