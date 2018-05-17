DROP FUNCTION IF EXISTS palk.sp_calc_palgajaak(user_id INTEGER, params JSON );

CREATE OR REPLACE FUNCTION palk.sp_calc_palgajaak(user_id INTEGER, params JSON)
  RETURNS INTEGER AS
$BODY$
DECLARE
  l_kpv1      DATE = coalesce((params ->> 'kpv1') :: DATE, date(year(current_date), month(current_date), 1));
  l_kpv2      DATE = coalesce((params ->> 'kpv2') :: DATE, current_date);
  v_tooleping RECORD;
  isik_ids    JSON = params ->> 'isikud';
  l_rekvid    INTEGER = params ->> 'rekvid';
  l_result INTEGER = 0;

BEGIN
  IF l_rekvid IS NULL OR isik_ids IS NULL OR json_array_length(isik_ids :: JSON) = 0
  THEN
    --puudub vajaliku parameter
    RETURN 0;
  END IF;

  FOR v_tooleping IN
  SELECT t.id
  FROM libs.asutus a
    INNER JOIN palk.tooleping t ON t.parentId = a.id
  WHERE a.id IN (SELECT value :: INTEGER
                 FROM json_array_elements_text(isik_ids))
        AND t.rekvid = l_rekvid
  LOOP
    raise notice 'lepingid %', v_tooleping.id;
    WHILE l_kpv2 >= l_kpv1
    LOOP
      l_result =  palk.sp_update_palk_jaak(l_kpv1, v_tooleping.id);
      l_kpv1 = l_kpv1 + INTERVAL ' 1 month ';
      raise notice 'l_result %, l_kpv1 %', l_result, l_kpv1;
    END LOOP;

    -- вернем стартовое значение даты
    l_kpv1 = coalesce((params ->> 'kpv1') :: DATE, date(year(current_date), month(current_date), 1));

  END LOOP;
  RETURN 1;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.sp_calc_palgajaak(user_id INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_calc_palgajaak(user_id INTEGER, params JSON) TO dbpeakasutaja;


SELECT palk.sp_calc_palgajaak(1, '{
  "kpv1":20180101,
  "kpv2":20180531,
  "isikud": [
    60,
    61,
    57,
    56
  ],
  "rekvid": 1
}')

/*
	SELECT palk.sp_calc_palgajaak(1,'{"rekvid":1,"isikud":[56],"kpv1":20180501, "kpv2":20180531}')

 */