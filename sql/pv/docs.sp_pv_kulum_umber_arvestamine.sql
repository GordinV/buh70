DROP FUNCTION IF EXISTS docs.sp_pv_kulum_umber_arvestamine(IN tnId INTEGER, IN userId INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_pv_kulum_umber_arvestamine(parandus_oper_id INTEGER, user_id INTEGER,
                                                              OUT error_code INTEGER,
                                                              OUT result INTEGER,
                                                              OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_pv_oper    RECORD;
  l_rekvid     INTEGER = (SELECT rekvid
                          FROM ou.userid
                          WHERE id = user_id);
  KULUM_LIIK   INTEGER = 2; -- вид операции износ
  v_tulemus    RECORD;
  json_object  JSON;
  l_pv_oper_id INTEGER;
BEGIN

  IF l_rekvid IS NULL
  THEN
    RAISE NOTICE 'User not found %', user_id;
    error_code = 5;
    error_message = 'User not found';
    RETURN;
  END IF;

  -- пройдем циклом по карточкам для перерасчета износа
  FOR v_pv_oper IN
    SELECT pv.*
    FROM docs.pv_oper pv,
         (SELECT pv_kaart_id, kpv FROM docs.pv_oper po WHERE parentid = parandus_oper_id) AS po
    WHERE pv.pv_kaart_id = po.pv_kaart_id
      AND pv.liik = KULUM_LIIK
      AND pv.kpv > po.kpv
    LOOP
      -- расчет износа

      SELECT
        qry.result,
        qry.selgitus,
        qry.summa
        INTO v_tulemus
      FROM docs.sp_calc_kulum(v_pv_oper.pv_kaart_id :: INTEGER, v_pv_oper.kpv) qry;

      IF v_tulemus.result > 0 AND v_tulemus.summa > 0 and v_tulemus.summa <> v_pv_oper.summa
      THEN
        v_pv_oper.summa = v_tulemus.summa;
        v_pv_oper.muud = v_tulemus.selgitus;


        -- salvesta pv oper
        json_object = json_build_object('data', row_to_json(v_pv_oper.*), 'id', v_pv_oper.parentid);

        l_pv_oper_id = docs.sp_salvesta_pv_oper(json_object, user_id, l_rekvid);

        IF l_pv_oper_id > 0
        THEN
          -- контировка
          PERFORM docs.gen_lausend_pv_oper(l_pv_oper_id, user_id);
        END IF;

      END IF;
      result = coalesce(result, 0) + 1;
    END LOOP;

  result = 1;
  RETURN;
  EXCEPTION
  WHEN OTHERS
    THEN
      RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
      error_code = 1;
      error_message = SQLERRM;
      result = 0;
      RETURN;

END;
$BODY$
  LANGUAGE 'plpgsql'
  VOLATILE
  COST 100;



GRANT EXECUTE ON FUNCTION docs.sp_pv_kulum_umber_arvestamine(IN tnId INTEGER, IN userId INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_pv_kulum_umber_arvestamine(IN tnId INTEGER, IN userId INTEGER) TO dbpeakasutaja;


COMMENT ON FUNCTION docs.sp_pv_kulum_umber_arvestamine(IN tnId INTEGER, IN userId INTEGER) IS 'перерасчет износа';

/*

select docs.sp_pv_kulum_umber_arvestamine(297424, 1)

select * from docs.pv_oper order by id desc limit 10

*/