--rekl.sp_tuhistada_saatmine

DROP FUNCTION IF EXISTS rekl.sp_tuhistada_saatmine( INTEGER, JSON );

CREATE FUNCTION rekl.sp_tuhistada_saatmine(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                           OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)

  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  l_dekl_id   INTEGER = params ->> 'id';
  v_toiming   RECORD;
  json_params JSON;

BEGIN
  SELECT
    journalid,
    staatus
  INTO v_toiming
  FROM rekl.toiming t
  WHERE t.parentid = l_dekl_id;

  IF v_toiming.staatus = 'closed'
  THEN
    error_message = 'Viga, deklaratsioon tasunud';
    error_code = 5;
    result = 0;
    RETURN;
  ELSE
    IF v_toiming.journalid IS NOT NULL AND v_toiming.journalid > 0
    THEN
      result = docs.sp_delete_journal(user_id, v_toiming.journalid);
    END IF;

    UPDATE rekl.toiming
    SET saadetud = NULL,
      journalid  = NULL
    WHERE parentid = l_dekl_id;

    SELECT row_to_json(row)
    INTO json_params
    FROM (SELECT v_toiming.journalid AS id) row;

    result = (SELECT qry.result
              FROM rekl.sp_recalc_rekl_jaak(user_id, json_params) AS qry);

  END IF;
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

select rekl.sp_tuhistada_saatmine(1, '{"id":294185}')
select * from rekl.toiming where tyyp = 'DEKL'  and saadetud is not null

select * from rekl.toiming where parentid = 294135

 */