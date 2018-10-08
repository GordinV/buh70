DROP FUNCTION IF EXISTS palk.sp_calc_sots( INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS palk.sp_calc_sots(params JSONB );
DROP FUNCTION IF EXISTS palk.sp_calc_sots(user_id INTEGER, params JSON );

CREATE FUNCTION palk.sp_calc_sots(user_id       INTEGER, params JSON,
  OUT                             summa         NUMERIC,
  OUT                             selg          TEXT,
  OUT                             error_code    INTEGER,
  OUT                             result        INTEGER,
  OUT                             error_message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid                 INTEGER = params ->> 'lepingid';
  l_libId                    INTEGER = params ->> 'libid';
  l_kpv                      DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  l_pk_summa                 NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, 33);
  is_percent                 BOOLEAN = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                                TRUE); -- kas pk summa percentis (33%)
  l_min_sots                 INTEGER = ((coalesce((params ->> 'minsots') :: INTEGER, 0)) :: INTEGER);
  l_alus_summa               NUMERIC(12, 4) = params ->> 'alus_summa'; -- tulud , milliest arvestame sots.maks
  l_round                    NUMERIC = 0.01;
  l_params                   JSON;

  v_tooleping                RECORD;
  l_min_palk                 NUMERIC(12, 4) = 470; --alus arvestada sots.maks min palgast

  ln_umardamine              NUMERIC(14, 4) = 0;
  l_sotsmaks_min_palgast     NUMERIC(14, 4) = 0;
  l_enne_arvestatud_sotsmaks NUMERIC(14, 4) = 0; -- summa, mis ole arvestatud koos tulu summaga, palk.oper.sotsmaks
  l_enne_koostatud_sotsmaks  NUMERIC(14, 4) = 0; -- sotsmaks, arvestatus selles kuues enne kaesolev arvestus
  l_too_paevad               INTEGER = 30;
  l_puudu_paevad             INTEGER = 0;
  l_last_paev                DATE = (date(year(l_kpv), month(l_kpv), 1) + INTERVAL '1 month') :: DATE - 1;

BEGIN

  RAISE NOTICE 'sm arv params %, l_alus_summa %', params, l_alus_summa;
  IF l_alus_summa IS NULL
  THEN
    -- meil ei ole alus summa, vaja arvestada alus

    -- select lepinguandmed
    SELECT
      t.pohikoht,
      t.rekvid,
      t.algab,
      t.lopp,
      t.parentid
    INTO v_tooleping
    FROM palk.tooleping t
    WHERE t.id = l_lepingid;


    SELECT
      pk.summa,
      empty(pk.percent_ :: INTEGER),
      coalesce(pk.minsots, 0) AS minsots,
      coalesce(pc.minpalk, 0) AS minpalk,
      l.round
    --    INTO v_palk_kaart
    INTO l_pk_summa, is_percent, l_min_sots, l_min_palk, l_round
    FROM palk.palk_kaart pk
      LEFT OUTER JOIN palk.palk_config pc ON pc.rekvid = v_tooleping.rekvid
      INNER JOIN palk.com_palk_lib l ON pk.libid = l.id
    WHERE pk.lepingid = l_lepingid
          AND libId = l_libId;

    SELECT
      sum(po.sotsmaks) AS sotsmaks,
      sum(po.summa)
    INTO summa, l_alus_summa
    FROM palk.cur_palkoper po
      INNER JOIN libs.library l ON l.id = po.libid
    WHERE po.kpv = l_kpv
          AND po.rekvid = v_tooleping.rekvId
          AND po.lepingId = l_lepingid
          AND po.palk_liik = 'ARVESTUSED'
          AND po.sotsmaks IS NOT NULL;

    IF coalesce(l_min_sots, 0) > 0
    THEN

      --parandame tööpäevad, kui töötaja töötas mitte täis kuu
      l_too_paevad = CASE WHEN COALESCE(v_tooleping.lopp, l_last_paev) < l_last_paev
        THEN v_tooleping.lopp
                     ELSE l_last_paev END -
                     CASE WHEN v_tooleping.algab > date(YEAR(l_kpv), MONTH(l_kpv), 1)
                       THEN v_tooleping.algab
                     ELSE date(YEAR(l_kpv), MONTH(l_kpv), 1) END +
                     1 - l_puudu_paevad;

      -- params
      SELECT row_to_json(row)
      INTO l_params
      FROM (SELECT
              month(l_kpv) AS kuu,
              year(l_kpv)  AS aasta,
              l_lepingid   AS lepingid) row;


      l_puudu_paevad = palk.get_puudumine(l_params :: JSONB);

      -- kontrollime enne arvestatud sotsmaks

      SELECT sum(po.summa)
      INTO l_enne_arvestatud_sotsmaks
      FROM palk.cur_palkoper po
      WHERE year(po.kpv) = year(l_kpv) AND month(po.kpv) = month(l_kpv)
            AND po.palk_liik :: TEXT = 'SOTSMAKS'
            AND po.lepingid IN (SELECT t.id
                                FROM palk.tooleping t
                                WHERE t.parentid = v_tooleping.parentid AND t.rekvid = v_tooleping.rekvId)
            AND po.id NOT IN (SELECT p.id
                              FROM palk.cur_palkoper p
                              WHERE p.lepingId = l_lepingid
                                    AND libId = l_libId
                                    AND kpv = l_kpv);

      l_enne_arvestatud_sotsmaks = coalesce(l_enne_arvestatud_sotsmaks, 0);

      -- kontrollime enne koostatud sotsmaks (ilma kaesoaleva lepinguta)
      SELECT sum(sotsmaks)
      INTO l_enne_koostatud_sotsmaks
      FROM palk.cur_palkoper po
      WHERE year(kpv) = year(l_kpv) AND month(kpv) = month(l_kpv)
            AND po.palk_liik :: TEXT = 'ARVESTUSED'
            AND po.lepingid IN (SELECT t.id
                                FROM palk.tooleping t
                                WHERE t.parentid = v_tooleping.parentid
                                      AND t.rekvid = v_tooleping.rekvId
                                      AND t.id <> l_lepingid);

      IF coalesce(l_enne_arvestatud_sotsmaks, 0) > l_enne_koostatud_sotsmaks
      THEN
        -- sotsmaks min.pallgast oli kasutusel
        l_min_sots = 0;
      END IF;

      IF coalesce(l_enne_arvestatud_sotsmaks, 0) = 0 AND coalesce(l_enne_koostatud_sotsmaks, 0) > 0
      THEN
        l_enne_arvestatud_sotsmaks = l_enne_koostatud_sotsmaks;
      END IF;

    END IF;


    IF l_puudu_paevad = 0
    THEN
      l_too_paevad = 30;
    END IF;

    IF NOT empty(l_min_sots) AND NOT empty(l_min_palk) --arvetsame sotsmaks min.palgast
    THEN
      l_sotsmaks_min_palgast = ((l_min_palk * l_min_sots * l_pk_summa * 0.01) / 30 * (l_too_paevad));

      IF l_sotsmaks_min_palgast > coalesce(l_enne_arvestatud_sotsmaks, 0)
      THEN
        l_sotsmaks_min_palgast = l_sotsmaks_min_palgast - coalesce(l_enne_arvestatud_sotsmaks, 0);
      ELSE
        -- не используем см с мин. ЗП
        l_sotsmaks_min_palgast = 0;
      END IF;

    END IF;

    IF coalesce(summa, 0) < l_sotsmaks_min_palgast AND (l_alus_summa = 0 OR summa > 0)

    THEN
      -- ainult , kui olid tulud
      l_sotsmaks_min_palgast = (l_sotsmaks_min_palgast - summa);

    END IF;

    summa = f_round(coalesce(summa, 0) + l_sotsmaks_min_palgast + ln_umardamine, l_round);

    selg = coalesce(summa, 0) :: TEXT || ' + ' || l_sotsmaks_min_palgast :: TEXT || ' + ' || ln_umardamine :: TEXT;
  ELSE
    -- arvestus
    summa = l_alus_summa * l_pk_summa * 0.01;
    selg = l_alus_summa :: TEXT || '*' || (l_pk_summa * 0.01) :: TEXT;

  END IF;

  result = 1;
  summa = coalesce(f_round(summa, l_round), 0);
  RETURN;

END;
$$;

/*
select * from palk.sp_calc_sots(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSON)
select * from palk.sp_calc_sots(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09", "alus_summa":100, "summa":33}'::JSON)
select * from palk.sp_calc_sots(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09", "alus_summa":0, "summa":50, "is_percent":false}'::JSON)
select * from  palk.sp_calc_sots(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09", "alus_summa":100, "summa":33, "is_percent":true,"minsots":1}'::JSON)
select * from palk.sp_calc_sots(1, '{"alus_summa":100, "summa":33, "is_percent":true,"minsots":1}'::JSON)
select * from palk.sp_calc_sots(1,'{"lepingid":4,"libid":524,"kpv":20180407}'::JSON)

 */