DROP FUNCTION IF EXISTS palk.sp_calc_sots( INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS palk.sp_calc_sots(params JSONB );

CREATE FUNCTION palk.sp_calc_sots(params JSONB)
  RETURNS NUMERIC
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

  l_sotsmaksu_summa          NUMERIC(12, 4) = 0;
  v_tooleping                RECORD;
  l_min_palk                 NUMERIC(12, 4) = 470; --alus arvestada sots.maks min palgast

  ln_umardamine              NUMERIC(14, 4) = 0;
  l_sotsmaks_min_palgast     NUMERIC(14, 4) = 0;
  l_enne_arvestatud_sotsmaks NUMERIC(14, 4) = 0; -- summa, mis ole arvestatud koos tulu summaga, palk.oper.sotsmaks
  l_enne_koostatud_sotsmaks  NUMERIC(14, 4) = 0; -- sotsmaks, arvestatus selles kuues enne kaesolev arvestus
  lnEnneArvestatudSM         NUMERIC(14, 4) = 0;
  l_kuu_paevad               INTEGER =
  (gomonth(date(year(l_kpv), month(l_kpv), 1), 1) - 1) - date(year(l_kpv), month(l_kpv), 1) + 1; -- paevad kuus
  l_too_paevad               INTEGER = 30;
  l_puudu_paevad             INTEGER = 0;
  l_last_paev                DATE = (date(year(l_kpv), month(l_kpv), 1) + INTERVAL '1 month') :: DATE - 1;

BEGIN
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

    -- 2015
    SELECT
      sum(po.sotsmaks) AS sotsmaks,
      sum(po.summa)
    INTO l_sotsmaksu_summa, l_alus_summa
    FROM palk.cur_palkoper po
      INNER JOIN libs.library l ON l.id = po.libid
    WHERE po.kpv = l_kpv
          AND po.rekvid = v_tooleping.rekvId
          AND po.lepingId = l_lepingid
          AND po.palk_liik = 'ARVESTUSED'
          AND po.sotsmaks IS NOT NULL;

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
      l_min_sots = 1;
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

  IF NOT empty(l_min_sots) --arvetsame sotsmaks min.palgast
  THEN
    l_sotsmaks_min_palgast = ((l_min_palk * l_min_sots * l_pk_summa * 0.01) / 30 * (l_too_paevad))
                             - coalesce(l_enne_arvestatud_sotsmaks, 0);


    IF l_sotsmaks_min_palgast <= 0
    THEN
      l_sotsmaks_min_palgast = 0;
      IF NOT EMPTY(l_min_sots)
      THEN
        l_sotsmaksu_summa = 0; -- min. sotsmaks juba kasutusel
      END IF;
    END IF;
  END IF;

  IF l_sotsmaksu_summa < l_sotsmaks_min_palgast AND (l_alus_summa = 0 OR l_sotsmaksu_summa > 0)

  THEN
    -- ainult , kui olid tulud
    l_sotsmaks_min_palgast = (l_sotsmaks_min_palgast - l_sotsmaksu_summa);

    /*
      ltSelgitus =
      ltSelgitus + 'SM kasutame min.palk (' + v_Palk_kaart.MinPalk :: TEXT + ' / 30 * (30 - ' + l_puudu_paevad :: TEXT +
      '))' +
      CASE WHEN coalesce(lnEnneArvestatudSotsmaks, 0) <> 0
        THEN ' Enne arvestatud sotsmaks' + lnEnneArvestatudSotsmaks :: TEXT
      ELSE '' END +
      ' parandus maksusumma ' + round(lnSotsmaksMinPalk, 2) :: TEXT + ltEnter;
    */
    --		lnSumma = lnSotsmaksMinPalk + lnSumma;
    /*
      ELSE
        l_sotsmaks_min_palgast = 0;
    */
  END IF;

  /*
  IF lnSumma <> 0
  THEN
    ltSelgitus = ltSelgitus + ' Enne arvestatud sotsmaks: ' + coalesce(lnSumma, 0) :: VARCHAR + ltEnter;
  END IF;
  */

  l_sotsmaksu_summa = f_round(l_sotsmaksu_summa + l_sotsmaks_min_palgast + ln_umardamine, l_round);

  IF (coalesce(l_sotsmaksu_summa, 0) = 0 AND empty(l_min_sots))
  THEN
    -- puudub arvestus või sotsmaks = 0, kontrollime
    IF is_percent AND l_alus_summa IS NULL
    THEN
      SELECT sum(po.summa)
      INTO l_alus_summa
      FROM palk.cur_palkoper po
      WHERE po.kpv = l_kpv
            AND po.palk_liik = 'ARVESTUSED'
            AND po.lepingId = l_lepingid
            AND (po.is_sotsmaks);
    END IF;

    IF is_percent
    THEN
      l_sotsmaksu_summa = l_pk_summa * 0.01 * l_alus_summa;
    ELSE
      l_sotsmaksu_summa = l_pk_summa;
    END IF;

  END IF;
  l_sotsmaksu_summa = f_round(l_sotsmaksu_summa, l_round);
  RETURN coalesce(l_sotsmaksu_summa, 0)::numeric;

END;
$$;


/*
select palk.sp_calc_sots('{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSONB)
select palk.sp_calc_sots('{"lepingid":4, "libid":386, "kpv":"2018-04-09", "alus_summa":100, "summa":33}'::JSONB)
select palk.sp_calc_sots('{"lepingid":4, "libid":386, "kpv":"2018-04-09", "alus_summa":0, "summa":50, "is_percent":false}'::JSONB)
select palk.sp_calc_sots('{"lepingid":4, "libid":386, "kpv":"2018-04-09", "alus_summa":100, "summa":33, "is_percent":true,"minsots":1}'::JSONB)
select palk.sp_calc_sots('{"alus_summa":100, "summa":33, "is_percent":true,"minsots":1}'::JSONB)

 */