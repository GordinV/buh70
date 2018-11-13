DROP FUNCTION IF EXISTS docs.sp_calc_viivised( INTEGER, params JSON );

CREATE FUNCTION docs.sp_calc_viivised(IN user_id INTEGER, IN params JSON)
  RETURNS TABLE(
    number VARCHAR(20), kpv DATE, tahtaeg DATE, jaak NUMERIC(14, 2), summa NUMERIC, tasud NUMERIC, viivis NUMERIC, selg TEXT, konto VARCHAR(20), asutus VARCHAR(254)
  )
LANGUAGE plpgsql
AS $$
DECLARE
  l_asutus_id      INTEGER = params ->> 'asutus_id';
  l_arve_id        INTEGER = params ->> 'arve_id';
  l_leping_id      INTEGER = params ->> 'leping_id';
  l_viivise_maar   NUMERIC = coalesce((params ->> 'viivise_maar') :: NUMERIC, 0.10);
  l_kpv            DATE = coalesce((params ->> 'kpv') :: DATE, current_date);

  v_arved          RECORD;
  l_viivis_kokku   NUMERIC(12, 2) = 0;
  l_ids            INTEGER [] = '{}' :: INTEGER [] || l_leping_id;
  l_json           JSONB;
  l_selg           TEXT;
  l_arve_lisa_info JSON;
  v_viivis         RECORD;
BEGIN


  summa = 0;
  -- otsime arved
  FOR v_arved IN
  SELECT
    d.id,
    a.summa,
    a.kpv,
    a.asutusid,
    a.jaak,
    a.tahtaeg,
    a.number,
    (SELECT to_json(array_agg(at))
     FROM docs.arvtasu at
     WHERE at.doc_arv_id = d.id)                AS tasud,
    coalesce((SELECT sum(tasu.summa)
              FROM docs.arvtasu tasu
              WHERE tasu.doc_arv_id = d.id), 0) AS tasud_kokku,
    l.details ->> 'konto'                       AS konto,
    asutus.nimetus :: VARCHAR(254)              AS asutus
  FROM docs.arv a
    INNER JOIN docs.doc d ON d.id = a.parentid
    LEFT OUTER JOIN libs.dokprop l ON a.doklausid = l.id
    INNER JOIN libs.asutus asutus ON a.asutusid = asutus.id
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

    -- расчет интресса
    SELECT
      qry.summa,
      qry.selg
    INTO l_viivis_kokku, l_json
    FROM docs.fnc_calc_viivised(
             (SELECT to_jsonb(row)
              FROM (SELECT
                      l_kpv           AS kpv,
                      l_viivise_maar  AS viivise_maar,
                      v_arved.summa   AS summa,
                      v_arved.tahtaeg AS tahtaeg,
                      v_arved.tasud   AS tasud) row) :: JSON) qry;

    -- @todo arvesta juba salvestatud intressid
    summa = summa + coalesce(l_viivis_kokku, 0);

    l_selg = '';

    FOR v_viivis IN
    SELECT *
    FROM
          jsonb_to_recordset(l_json) AS x(kpv DATE, volg NUMERIC(14, 2), paevad INTEGER, viivis NUMERIC(14, 2))
    LOOP
      l_selg = 'Kuupäev:' || v_viivis.kpv :: TEXT || ', võlg:' || v_viivis.volg :: TEXT || ', päevad:' ||
               v_viivis.paevad :: TEXT || ', intress:' || l_viivise_maar :: TEXT || ', viivis:' || v_viivis.viivis ||
               chr(13);
    END LOOP;
    RETURN QUERY SELECT
                   v_arved.number :: VARCHAR(20),
                   v_arved.kpv                  AS kpv,
                   v_arved.tahtaeg              AS tahtaeg,
                   v_arved.jaak                 AS jaak,
                   v_arved.summa                AS summa,
                   v_arved.tasud_kokku          AS tasud,
                   l_viivis_kokku               AS viivis,
                   l_selg                       AS selg,
                   v_arved.konto :: VARCHAR(20) AS konto,
                   v_arved.asutus;

  END LOOP;
  RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION docs.sp_calc_viivised(INTEGER, params JSON) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.sp_calc_viivised(INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_calc_viivised(INTEGER, params JSON) TO dbpeakasutaja;


/*


SELECT docs.sp_calc_viivised(70, '{
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