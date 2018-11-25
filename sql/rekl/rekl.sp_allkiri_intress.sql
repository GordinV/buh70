--rekl.sp_tuhistada_saatmine

DROP FUNCTION IF EXISTS rekl.sp_allkiri_intress(INTEGER, JSON);

CREATE FUNCTION rekl.sp_allkiri_intress(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                        OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)

  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  l_dekl_id   INTEGER = params ->> 'id';
  v_toiming   RECORD;
  json_params JSON;
  l_json      JSON;

BEGIN
  SELECT journalid, staatus, u.kasutaja, lubaid
      INTO v_toiming
  FROM rekl.toiming t,
       ou.userid u
  WHERE t.parentid = l_dekl_id
    AND u.id = user_id;

  IF v_toiming IS NULL
  THEN
    -- документ не найден
    error_code = 6;
    error_message = 'Dokument ei leidnud';
    result = 0
    RETURN;

  END IF;

  IF v_toiming.staatus IS NOT NULL AND v_toiming.staatus = 'closed'
  THEN
    error_message = 'Viga, intress juba tasud';
    error_code = 5;
    result = 0;
    RETURN;
  END IF;

  -- устанавливаем статус
  UPDATE rekl.toiming SET staatus = 'active' WHERE parentid = l_dekl_id;

  -- контировка
  SELECT row_to_json(row)
      INTO json_params FROM (SELECT l_dekl_id AS id) row;

  PERFORM rekl.gen_lausend_reklintress(user_id, json_params :: JSON);

  -- ajalugu ja status

  l_json = (SELECT row_to_json(row) FROM (SELECT v_toiming.kasutaja, now() AS updated, 'allkiri' as action) row);

  UPDATE docs.doc
  SET status     = 1,
      lastupdate = now(),
      history    = history || l_json :: JSONB
  WHERE id = l_dekl_id;

  SELECT row_to_json(row)
      INTO json_params FROM (SELECT v_toiming.lubaid AS id) row;

  result = (SELECT qry.result FROM rekl.sp_recalc_rekl_jaak(user_id, json_params) AS qry);

  result = 1;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    result = 0;
    error_code = 1;
    error_message = SQLERRM;

    RETURN;
END;
$$;

/*

select rekl.sp_allkiri_intress(64, '{"id":1443574}')
select * from rekl.toiming where tyyp = 'DEKL'  and saadetud is not null

select * from rekl.toiming where parentid = 294135

 */