DROP FUNCTION IF EXISTS rekl.sp_koosta_parandus( INTEGER, JSON );

CREATE FUNCTION rekl.sp_koosta_parandus(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                        OUT error_code INTEGER, OUT error_message TEXT)

  RETURNS RECORD

LANGUAGE plpgsql
AS $$
DECLARE

  l_luba_id        INTEGER = params ->> 'id';
  l_kpv       DATE = coalesce((params ->> 'kpv')::date,current_date::date);
  v_luba      RECORD;
  l_alus      TEXT;
  v_toiming   RECORD;
  json_params JSON;
BEGIN
  result = 1;
  SELECT *
  INTO v_luba
  FROM rekl.luba
  WHERE parentid = l_luba_id;

  IF v_luba.staatus = 0
  THEN
    error_message = 'Luba anulleritud';
    error_code = 3;
    RETURN;
  END IF;

  l_alus = 'Dekl. number:' + ltrim(rtrim(v_luba.number)) || ' ' || l_kpv :: TEXT || ' nt maksumaksja avaldus ';

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
    'PARANDUS'      AS tyyp
  INTO v_toiming;

  SELECT row_to_json(row)
  INTO json_params
  FROM (SELECT
          0                      AS id,
          row_to_json(v_toiming) AS data) row;

  result = rekl.sp_salvesta_toiming(json_params, user_id, v_luba.rekvid);

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_code = 1;
    error_message = SQLERRM;
    result = 0;
    RETURN;

END;
$$;


GRANT EXECUTE ON FUNCTION rekl.sp_koosta_parandus(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_koosta_parandus(INTEGER, JSON) TO dbpeakasutaja;

/*
select rekl.sp_koosta_parandus(1,'{"id":294112,"kpv":"2018-06-30"}'::json)

select * from rekl.luba
 */