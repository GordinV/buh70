DROP FUNCTION IF EXISTS rekl.sp_calc_dekl_jaak( IN user_id INTEGER, IN params JSON );

CREATE FUNCTION rekl.sp_calc_dekl_jaak(dekl_id integer)
  RETURN numeric
LANGUAGE plpgsql
AS $$
DECLARE
  l_dekl_Id         INTEGER = params ->> 'id';
  l_kpv             DATE = params ->> 'kpv';
  l_summa           NUMERIC = params ->> 'summa';
  l_alus            TEXT = params ->> 'alus';
  l_tasu_id         INTEGER;

  l_volg_kpv        INTEGER = 0;
  v_dekl            RECORD;
  v_toiming         RECORD;
  v_luba            RECORD;
  l_ettemaksu_summa NUMERIC = 0;
  l_journal_id      INTEGER;
  json_params       JSONB;
  l_ettemaks_id     INTEGER;
  v_ettemaks        RECORD;
BEGIN
  -- otsime luba

  SELECT
         l.*,
         t.number AS t_number,
         t.id     AS deklid
      INTO v_luba
  FROM rekl.luba l
         INNER JOIN rekl.toiming t ON l.parentid = t.lubaid
  WHERE t.parentid = l_dekl_Id;

  -- kontrollime ettemaks
  SELECT sum(summa)
      INTO l_ettemaksu_summa
  FROM rekl.ettemaksud e
  WHERE asutusid = v_luba.asutusid
    AND staatus <> 'deleted';

  IF (l_ettemaksu_summa - l_summa) < 0
  THEN
    -- puudub ettemaks
    error_code = 6;
    error_message = 'Puudub ettemaks';
    result = 0;
    RETURN;
  END IF;

  l_ettemaksu_summa = l_summa;

  SELECT
         0                 AS id,
         0                 AS number,
         v_luba.asutusid,
         v_luba.parentid   AS lubaid,
         l_kpv             AS kpv,
         l_ettemaksu_summa AS summa,
         l_alus :: TEXT    AS alus,
         NULL :: TEXT      AS ettekirjutus,
         l_kpv             AS tahtaeg,
         'TASU'            AS tyyp
      INTO v_toiming;

  SELECT row_to_json(row)
      INTO json_params
  FROM (SELECT
               0                      AS id,
               row_to_json(v_toiming) AS data) row;

  l_tasu_id = rekl.sp_salvesta_toiming(json_params :: JSON, user_id, v_luba.rekvid);
  -- konteerimine

  IF l_tasu_id IS NOT NULL AND l_tasu_id > 0
  THEN
    SELECT row_to_json(row)
        INTO json_params
    FROM (SELECT l_tasu_id AS id) row;

    SELECT qry.result
    FROM rekl.gen_lausend_rekltasu(user_id, json_params :: JSON) qry
        INTO l_journal_id;
  ELSE
    l_journal_id = 0;
  END IF;

  IF l_alus = 'Ettemaks' AND l_tasu_id IS NOT NULL AND l_tasu_id <> 0
  THEN
    -- ettemaks nullime

    SELECT
           0                      AS id,
           0                      AS number,
           v_luba.asutusid,
           l_kpv                  AS kpv,
           -1 * l_ettemaksu_summa AS summa,
           l_alus :: TEXT         AS selg,
           'KREEDIT'              AS doktyyp,
           l_tasu_id              AS dokid,
           CASE WHEN l_journal_id IS NOT NULL AND l_journal_id = 1
                     THEN NULL
                ELSE l_journal_id END  AS journalid
        INTO v_ettemaks;

    SELECT row_to_json(row)
        INTO json_params
    FROM (SELECT
                 0                       AS id,
                 row_to_json(v_ettemaks) AS data) row;
    l_ettemaks_id = rekl.sp_salvesta_ettemaksud(json_params :: JSON, user_id, v_luba.rekvid);

  END IF;

  -- salvestame tasu info

  SELECT
         id,
         parentid,
         lubaid,
         coalesce((lisa ->> 'dekltasu') :: JSONB, '[]' :: JSONB) AS dekltasu,
         tahtaeg
      INTO v_dekl
  FROM rekl.toiming
  WHERE parentid = l_dekl_Id;

  -- kui palju paevad oli tahtajatu
  IF v_dekl.tahtaeg < l_kpv
  THEN
    l_volg_kpv = l_kpv - v_dekl.tahtaeg;
  END IF;

  -- tasu summa, dekltasu array
  SELECT row_to_json(row)
      INTO json_params
  FROM (SELECT
               l_tasu_id         AS tasuid,
               l_kpv             AS tasukpv,
               l_volg_kpv        AS volgkpv,
               l_ettemaksu_summa AS summa) row;

  v_dekl.dekltasu = v_dekl.dekltasu || json_params;

  -- lisa
  SELECT row_to_json(row)
      INTO json_params
  FROM (SELECT v_dekl.dekltasu AS dekltasu) row;

  UPDATE rekl.toiming
  SET lisa  = coalesce(lisa, '{}' :: JSONB) || json_params,
      staatus = 'closed'
  WHERE parentid = l_dekl_Id;

  -- luba jaak
  SELECT row_to_json(row)
      INTO json_params
  FROM (SELECT v_dekl.lubaid AS id) row;

  PERFORM rekl.sp_recalc_rekl_jaak(user_id, json_params :: JSON);
  PERFORM rekl.sp_set_ettemaks_staatus(v_luba.asutusid);
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
select * from rekl.sp_tasu_dekl(1,'{"id":294186,"kpv":"20180710","summa":66,"alus":"Ettemaks"}')

select * from rekl.toiming where staatus <> 'deleted' order by id desc

*/