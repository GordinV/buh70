DROP FUNCTION IF EXISTS rekl.sp_saada_dekl(IN user_id INTEGER, IN params JSON);

CREATE FUNCTION rekl.sp_saada_dekl(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                   OUT error_code INTEGER, OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  l_id        INTEGER = params ->> 'id';
  l_dokpropid INTEGER = params ->> 'dokprop_id';
  l_kpv       DATE = coalesce((params ->> 'kpv') :: DATE, current_date :: DATE);

  v_toiming   RECORD;
  json_params JSON;

BEGIN

  SELECT d.rekvid,
         t.parentid                              AS id,
         t.number                                AS number,
         t.asutusid,
         t.lubaid,
         t.kpv                                   AS kpv,
         t.summa                                 AS summa,
         t.alus,
         t.ettekirjutus,
         t.tahtaeg,
         t.tyyp,
         t.muud,
         rekl.get_deklstaatus(t.parentid, l_kpv) AS staatus,
         l_dokpropid as dokpropid,
         t.deklid,
         t.failid,
         l_kpv                                   AS saadetud
      INTO v_toiming
  FROM rekl.toiming t
         INNER JOIN docs.doc d ON d.id = t.parentid
  WHERE d.id = l_id;

  SELECT row_to_json(row)
      INTO json_params
  FROM (SELECT v_toiming.id AS id, row_to_json(v_toiming) AS data) row;

  result = rekl.sp_salvesta_toiming(json_params, user_id, v_toiming.rekvid);

  SELECT row_to_json(row)
      INTO json_params FROM (SELECT v_toiming.id AS id) row;

  -- konteerimine
  PERFORM rekl.gen_lausend_reklmaks(user_id, json_params :: JSON);

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
select * from rekl.toiming where saadetud is null
limit 10

select rekl.sp_saada_dekl(1, '{"id":294135,"kpv":"2018-06-30"}'::json );

 */