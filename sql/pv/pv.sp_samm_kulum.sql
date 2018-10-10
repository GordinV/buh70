DROP FUNCTION IF EXISTS docs.sp_samm_kulum( IN tnId INTEGER, IN userId INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_samm_kulum(
      user_id       INTEGER,
      params        JSON,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  l_ids        JSON = params ->> 'ids'; -- массив карточек ОС для расчета
  l_kpv        DATE = coalesce((params ->> 'kpv') :: DATE, current_date); -- дата расчета
  l_nomid      INTEGER = params ->> 'nomid'; -- ссылка на ид номенклатуры (операции)
  l_doklausid  INTEGER = params ->> 'doklausid'; -- ссылка на dokprop
  RAHA_VOOG    TEXT = '11'; -- kulum
  v_pv_kaards  RECORD;
  v_tulemus    RECORD;
  v_nom        RECORD;
  l_pv_oper_id INTEGER = 0;
  json_object  JSON;
  l_rekvid     INTEGER = (SELECT rekvid
                          FROM ou.userid
                          WHERE id = user_id);
  l_journal_id integer;

BEGIN

  IF l_rekvid IS NULL
  THEN
    RAISE NOTICE 'User not found %', user_id;
    error_code = 5;
    error_message = 'User not found';
    RETURN;
  END IF;

  -- пройдем циклов по карточкам для расчета износа
  FOR v_pv_kaards IN
  SELECT
    value,
    value :: TEXT AS id
  FROM json_array_elements(l_ids)
  LOOP
    -- расчет износа

    SELECT
      qry.result,
      qry.selgitus,
      qry.summa
    INTO v_tulemus
    FROM docs.sp_calc_kulum(v_pv_kaards.id :: INTEGER) qry;
    IF v_tulemus.result > 0 AND v_tulemus.summa > 0
    THEN
      -- salvesta pv oper
      l_pv_oper_id = (SELECT id
                      FROM cur_pv_oper po
                      WHERE pv_kaart_id = v_pv_kaards.id :: INTEGER AND kpv = l_kpv);

      SELECT *
      INTO v_nom
      FROM com_nomenclature n
      WHERE id = l_nomid;

      SELECT row_to_json(row)
      INTO json_object
      FROM (SELECT
              l_pv_oper_id              AS id,
              l_kpv                     AS kpv,
              l_nomid                   AS nomid,
              2                         AS liik,
              l_doklausid               AS doklausid,
              v_tulemus.summa           AS summa,
              v_nom.konto               AS konto,
              v_nom.proj                AS proj,
              v_nom.tegev               AS kood1,
              v_nom.allikas             AS kood2,
              RAHA_VOOG                 AS kood3,
              v_nom.artikkel            AS kood5,
              'AUTOMATSELT ARVESTUS'    AS muud,
              v_pv_kaards.id :: INTEGER AS pv_kaart_id) row;

      SELECT row_to_json(row)
      INTO json_object
      FROM (SELECT
              l_pv_oper_id AS id,
              json_object  AS data) row;

      l_pv_oper_id = docs.sp_salvesta_pv_oper(json_object, user_id, l_rekvid);

      IF l_pv_oper_id > 0 AND coalesce(l_doklausid, 0) > 0
      THEN
        -- контировка
        perform docs.gen_lausend_pv_oper(l_pv_oper_id, user_id);
      END IF;

    END IF;
    result = coalesce(result, 0) + 1;
  END LOOP;

  result = 1;
  RETURN;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_code = 1;
    error_message = SQLERRM;
    result = 0;
    RETURN;

END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

/*
SELECT *
FROM docs.sp_samm_kulum(1, '{
  "ids": [
    236182,
    235982,
    236184
  ],
  "nomid": 76,
  "kpv": "2018-08-31",
  "doklausid": 60
}');

*/