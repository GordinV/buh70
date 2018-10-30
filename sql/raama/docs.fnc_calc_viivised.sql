DROP FUNCTION IF EXISTS docs.fnc_calc_viivised( INTEGER, params JSON );

CREATE FUNCTION docs.fnc_calc_viivised(IN  user_id       INTEGER, IN params JSON,
                                       OUT selg          TEXT,
  --                                 OUT tki           NUMERIC,
                                       OUT error_code    INTEGER,
                                       OUT result        INTEGER,
                                       OUT error_message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  l_asutus_id    INTEGER = params ->> 'asutus_id';
  l_arve_id      INTEGER = params ->> 'arve_id';
  l_leping_id    INTEGER = params ->> 'leping_id';
  l_liik         INTEGER = params ->> 'liik'; -- 1 -  arve, 2 - leping, 3 - asutus
  l_viivise_maar INTEGER = params ->> 'viivise_maar';
  l_kpv          DATE = coalesce((params ->> 'kpv') :: DATE, current_date);

  v_arved        RECORD;
  l_viivis_kokku NUMERIC(12, 2) = 0;
  l_ids          INTEGER [] = '{}' :: INTEGER [] || l_leping_id;
  l_json         JSONB = '[]'::jsonb;
BEGIN
  RAISE NOTICE ' l_ids %', l_ids;


  DROP TABLE IF EXISTS temp_viivis;

  CREATE TEMPORARY TABLE temp_viivis (
    arve_id  INTEGER,
    viivis numeric(14,2),
    selgitus JSONB
  );
  -- otsime arved
  FOR v_arved IN
  SELECT
    d.id,
    a.summa,
    a.kpv,
    a.asutusid,
    a.jaak,
    a.tahtaeg,
    a.tasud,
    (l_kpv - a.tahtaeg) :: INTEGER AS paevad
  FROM docs.arv a
    INNER JOIN docs.doc d ON d.id = a.parentid
  WHERE d.rekvid = (SELECT rekvid
                    FROM ou.userid
                    WHERE id = user_id)
        AND coalesce(a.tahtaeg, current_date) < l_kpv
        AND year(a.kpv) >= 2011
        AND coalesce(a.jaak, 0) > 0
        --        or coalesce(a.tahtaeg, current_date)   -- не оплаченные или оплаченные с опозданием
        AND (l_ids IS NOT NULL AND d.docs_ids @> l_ids
             OR l_arve_id IS NOT NULL AND d.id = l_arve_id
             OR l_asutus_id IS NOT NULL AND a.asutusid = l_asutus_id)

  LOOP
    l_viivis_kokku = v_arved.jaak * v_arved.paevad * l_viivise_maar * 0.01;
    RAISE NOTICE ' l_viivis_kokku %, v_arved.id %', l_viivis_kokku, v_arved;

    l_json =   l_json || (select to_jsonb(row)
    FROM (SELECT
            l_viivis_kokku  AS viivis_kokku,
            l_kpv           AS kpv,
            l_viivise_maar  AS maar,
            v_arved.summa   AS arve_summa,
            v_arved.tahtaeg AS tahtaeg,
            v_arved.tasud   AS viimane_tasu_kpv,
            v_arved.jaak    AS volg,
            v_arved.paevad) row);

    INSERT INTO temp_viivis (arve_id, viivis, selgitus)
    VALUES (v_arved.id, l_viivis_kokku, l_json);
-- @todo arvesta juba salvestatud intressid
  END LOOP;
  result = 1;
  RETURN;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    selg = selg || SQLERRM;
    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION docs.fnc_calc_viivised( INTEGER, params JSON ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.fnc_calc_viivised( INTEGER, params JSON ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.fnc_calc_viivised( INTEGER, params JSON ) TO dbpeakasutaja;




/*


SELECT docs.fnc_calc_viivised(70, '{
  "asutus_id": 30224,
  "leping_id": 1438054,
  "viivise_maar": 6
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