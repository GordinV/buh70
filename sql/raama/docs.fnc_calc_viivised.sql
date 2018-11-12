DROP FUNCTION IF EXISTS docs.fnc_calc_viivised( INTEGER, params JSON );
DROP FUNCTION IF EXISTS docs.fnc_calc_viivised( params JSON );

CREATE FUNCTION docs.fnc_calc_viivised(IN  params JSON,
                                       OUT selg   JSON,
                                       OUT summa  NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
  l_viivise_maar NUMERIC = COALESCE((params ->> 'viivise_maar') :: NUMERIC, 6); -- 6% в год
  l_kpv          DATE = coalesce((params ->> 'kpv') :: DATE, current_date); -- расчет на дату
  l_volg         NUMERIC = params ->> 'summa'; -- сумма долга
  l_tahtaeg      DATE = params ->> 'tahtaeg'; -- срок оплаты

  l_jaak         NUMERIC = l_volg;
  l_paevad       INTEGER = l_kpv - l_tahtaeg;
  l_viivis_kokku NUMERIC = 0; --l_jaak * l_paevad * l_viivise_maar * 0.01;
  l_json         JSONB = '[]';
  v_tasud        RECORD;
  l_viivis       NUMERIC = 0;
BEGIN
  IF l_tahtaeg > l_kpv
  THEN
    -- срок оплаты не наступил, долг = 0
    summa = 0;
    RETURN;
  END IF;

  IF (params :: JSON ->> 'tasud') IS NOT NULL
  THEN

    -- если оплаты
    FOR v_tasud IN
    SELECT *
    FROM
          json_to_recordset(params :: JSON -> 'tasud')
        AS x(summa NUMERIC, kpv DATE)
    LOOP
      -- проверяем дату оплаты и считаем дни
      IF v_tasud.kpv < l_tahtaeg
      THEN
        -- оплата произведена в срок, считаем сальдо
        l_jaak = l_jaak - v_tasud.summa;
        CONTINUE;
      END IF;
      l_paevad = v_tasud.kpv - l_tahtaeg;

      IF l_jaak > 0
      THEN
        l_viivis = l_jaak * l_paevad * l_viivise_maar * 0.01;
        l_json = (l_json || (SELECT to_jsonb(row)
                             FROM (SELECT
                                     l_viivis AS viivis,
                                     l_kpv    AS kpv,
                                     l_jaak   AS volg,
                                     l_paevad AS paevad) row)) :: JSON;
        summa = round(coalesce(summa, 0) + l_viivis, 2);
      END IF;
      -- считаем остаток на день оплаты
      l_jaak = l_jaak - v_tasud.summa;
    END LOOP;
  END IF;

  IF l_jaak > 0
  THEN
    -- оплат нет, считаем интрес с полной суммы
    l_paevad = l_kpv - l_tahtaeg;

    l_viivis = l_jaak * l_paevad * l_viivise_maar * 0.01;
    l_json = (l_json || (SELECT to_jsonb(row)
                         FROM (SELECT
                                 l_viivis AS viivis,
                                 l_kpv    AS kpv,
                                 l_jaak   AS volg,
                                 l_paevad AS paevad) row)) :: JSON;

    -- возврат результатов
    summa = round(coalesce(summa, 0) + l_viivis, 2);
    selg = l_json;
  END IF;

  RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION docs.fnc_calc_viivised(params JSON) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.fnc_calc_viivised(params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.fnc_calc_viivised(params JSON) TO dbpeakasutaja;


SELECT docs.fnc_calc_viivised('{
  "summa": 69.31,
  "viivise_maar": 0.10,
  "tahtaeg": "2018-09-30",
  "kpv": "20181101",
  "tasud": null}');

/*


SELECT docs.fnc_calc_viivised('{
            "summa": 69.31,
            "viivise_maar": 0.10,
            "tahtaeg": "2018-09-30",
            "kpv": "2018-11-01",
            "tasud": [{"kpv": "20180912","summa":56.95}, {"kpv": "20181015","summa":12.36}]
        }');


select * from temp_viivis

--   "arve_id": 1438089,


SELECT *
FROM palk.sp_calc_arv(1, '{
  "lepingid": 4,
  "libid": 384,
  "kpv": 20180501
}' :: JSON)
*/
/*
select * from palk.sp_calc_arv(1,'{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSON)
SELECT * FROM palk.sp_calc_arv(1,'{ "alus_summa": 100,"kpv": "2018-04-09"}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{ "alus_summa": 100,"tululiik":"13","kpv": "2018-04-09"}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"kpv": "2018-04-09", "palk": 1200,  "summa":100,"tunnid_kokku":168}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"kpv": "2018-04-09", "palk": 1200, "is_percent":false}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"kpv": "2018-04-09", "palk": 1200, "is_percent":false, "pm_maksustav":0}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"kpv": "2018-04-09", "palk": 1200, "is_percent":false, "sm_maksustav":0}' :: JSON)
SELECT * FROM palk.sp_calc_arv(1,'{"lepingid":4,"libid":526,"kpv":20180630}'::json)
        {"kpv":"2018-06-30","lepingid":4,"lib":526}
*/