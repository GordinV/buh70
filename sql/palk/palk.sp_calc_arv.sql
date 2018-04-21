DROP FUNCTION IF EXISTS palk.sp_calc_arv(params JSONB );

CREATE FUNCTION palk.sp_calc_arv(IN  params JSONB,
                                 OUT selg   TEXT, OUT summa NUMERIC(14, 2), OUT sm NUMERIC(14, 2),
                                 OUT tm     NUMERIC(14, 2), OUT tka NUMERIC(14, 2), OUT tki NUMERIC(14, 2),
                                 OUT pm     NUMERIC(14, 2), OUT mvt NUMERIC(14, 2))
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid      INTEGER = params ->> 'lepingid';
  l_libid         INTEGER = params ->> 'libid';
  l_kpv           DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  l_alus_summa    NUMERIC = params ->> 'alus_summa'; -- для расчета налогов
  is_umardamine   BOOLEAN = params ->> 'umardamine'; -- если истина, то это округление
  is_percent      BOOLEAN = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                     TRUE); -- kas pk summa percentis (100%)
  l_palk_summa    NUMERIC = coalesce((params ->> 'palk') :: NUMERIC, 0);
  l_pk_summa      NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, CASE WHEN is_percent
    THEN 100
                                                                      ELSE l_palk_summa END);
  is_alimentid    BOOLEAN = coalesce((params ->> 'alimentid') :: BOOLEAN, FALSE); -- начисление алиментов
  l_tund          PALK_TUND_LIIK = params ->> 'tund'; -- tunni liik
  l_tunnid_kokku  NUMERIC = params ->> 'tunnid_kokku'; -- tunnid taabeli jargi

  l_tululiik      TEXT = coalesce((params ->> 'tululiik') :: TEXT, '10');
  l_PM_maksustav  INTEGER = coalesce((params ->> 'pm_maksustav') :: INTEGER, 1); -- является основой для ПН налога
  l_SM_maksustav  INTEGER = coalesce((params ->> 'sm_maksustav') :: INTEGER, 1); -- облагается соц. налогом
  l_tasuliik      INTEGER = array_position((enum_range(NULL :: PALK_TASU_LIIK)), 'ASTMEPALK');
  l_koormus       INTEGER = 100;

  tdperiod        DATE;
  l_hours         NUMERIC(20, 10) = 0;
  l_rate          NUMERIC(20, 10); -- bruttopalk
  lnBaas          NUMERIC(20, 10) = 0;
  ltEnter         TEXT;

  l_mvt_kokku     NUMERIC(14, 4) = 0; -- mvt taotluse summa
  l_kasutatud_mvt NUMERIC(14, 4) = 0;
  l_isiku_mvt     NUMERIC(14, 4) = 0; -- isiku kasutatud mvt

  l_PM_maar       NUMERIC(8, 2) = 2;
  l_TKI_maar      NUMERIC(8, 2) = 1.6;
  l_TKA_maar      NUMERIC(8, 2) = 0.8;
  l_SM_maar       NUMERIC(8, 2) = 33;
  l_TM_maar       NUMERIC(8, 2) = 20;
  l_min_sots      INTEGER = 0; -- kas arvesta min.sots.maks
  l_kuu_alg       DATE = date(year(l_kpv), month(l_kpv), 01);
  l_kuu_lopp      DATE = date(year(l_kpv), month(l_kpv), day(get_last_day(l_kpv)));
  l_round         NUMERIC = 0.01;
  l_params        JSON;
  l_min_palk      NUMERIC = 470;
  l_toopaev       NUMERIC = 8;
  l_rekvid        INTEGER;
  l_isik_id       INTEGER;
BEGIN
  ltEnter = '
';

  IF l_lepingid IS NOT NULL
  THEN
    SELECT
      t.toopaev,
      pc.minpalk,
      t.rekvid,
      CASE WHEN t.algab > l_kuu_alg AND month(t.algab) = month(l_kpv) AND
                year(t.algab) = year(l_kpv)
        THEN t.algab
      ELSE l_kuu_alg END,
      CASE WHEN t.lopp IS NOT NULL AND t.lopp < l_kuu_lopp AND month(t.lopp) = month(l_kpv) AND
                year(t.lopp) = year(l_kpv)
        THEN t.lopp
      ELSE l_kuu_lopp END,
      t.tasuliik,
      t.koormus,
      t.palk,
      t.parentid
    INTO l_toopaev, l_min_palk, l_rekvid, l_kuu_alg, l_kuu_lopp, l_tasuliik, l_koormus, l_palk_summa, l_isik_id
    FROM palk.com_toolepingud t
      LEFT OUTER JOIN palk.palk_config pc ON pc.rekvid = t.rekvid
    WHERE t.id = l_lepingid;

    -- parametrid puuduvad, võttame kõik andmebaasist
    -- palk kaart
    SELECT
      pk.percent_,
      pk.summa,
      NOT empty(pk.alimentid),
      l.round,
      l.tund,
      l.tululiik,
      l.liik,
      l.round
    INTO is_percent, l_pk_summa, is_alimentid, l_round, l_tund, l_tululiik
    FROM palk.palk_kaart pk
      INNER JOIN palk.com_palk_lib l ON pk.libid = l.id
    WHERE pk.lepingid = l_lepingid
          AND pk.libId = l_libId;

    SELECT CASE l_tund
           WHEN 'KÕIK'
             THEN kokku
           WHEN 'PÄEVAD'
             THEN paev
           WHEN 'ÕHTUL'
             THEN ohtu
           WHEN 'ÖÖSEL'
             THEN oo
           WHEN 'PUHKUS'
             THEN tahtpaev
           WHEN 'PÜHAPAEVAL'
             THEN puhapaev
           WHEN 'ÜLEAJATÖÖ'
             THEN uleajatoo
           END AS tunnid
    INTO l_tunnid_kokku
    FROM palk.cur_palk_taabel t
    WHERE lepingId = l_lepingid
          AND kuu = month(l_kpv)
          AND aasta = year(l_kpv);

  END IF;

  SELECT
    --    l.muud              AS lisa,
    CASE WHEN empty(l.tun1)
      THEN 0 :: NUMERIC
    ELSE l_TM_maar :: NUMERIC END  AS tm_maar,
    CASE WHEN l_SM_maksustav IS NOT NULL
      THEN l_SM_maksustav
    ELSE l.tun2 END                AS sm_maksustav,
    CASE WHEN empty(l.tun4)
      THEN 0 :: NUMERIC
    ELSE l_TKI_maar :: NUMERIC END AS tki_maar,
    CASE WHEN l_PM_maksustav IS NOT NULL
      THEN l_PM_maksustav
    ELSE (l.tun5) END              AS pm_maksustav
  INTO l_TM_maar, l_SM_maksustav, l_TKI_maar, l_PM_maksustav
  FROM libs.library l
  WHERE LIBRARY = 'MAKSUKOOD'
        AND l.kood = l_tululiik
        AND l.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');

  IF l_alus_summa IS NULL
  THEN
    IF is_percent
    THEN
      -- calc based on taabel
      -- prepaire parameters for hours calculation
      SELECT row_to_json(row)
      INTO l_params
      FROM (SELECT
              l_kpv           AS kpv,
              l_lepingid      AS lepingid,
              l_toopaev       AS toopaev,
              day(l_kuu_alg)  AS paev,
              day(l_kuu_lopp) AS lopp) row;


      l_hours = palk.get_work_hours(l_params :: JSONB);

      selg = selg + 'Kokku tunnid kuues,:' + ltrim(rtrim(round(l_hours, 2) :: VARCHAR)) + ltEnter;

      IF l_tasuliik = array_position((enum_range(NULL :: PALK_TASU_LIIK)), 'ASTMEPALK')
      THEN
        l_rate := l_palk_summa / l_hours * 0.01 * l_koormus;

        selg = selg + 'Tunni hind:' + ltrim(rtrim(round(l_rate, 2) :: VARCHAR)) + ltEnter;

        summa := f_round(l_rate * l_pk_summa * 0.01 * l_tunnid_kokku, l_round);
        selg = selg + 'parandamine:' + ltrim(rtrim(round(l_rate, 2) :: VARCHAR)) + '*' +
               ltrim(rtrim(round(l_pk_summa, 2) :: VARCHAR)) + ' * 0.01 * ' +
               ltrim(rtrim(round(l_tunnid_kokku, 3) :: VARCHAR)) + ltEnter;

        lnBaas := l_tunnid_kokku;

      ELSE
        --tunni alusel
        summa := f_round((l_palk_summa) * l_tunnid_kokku, l_round);
        l_rate := l_palk_summa;
        selg = selg + 'arvestus:' + ltrim(rtrim(l_palk_summa :: TEXT)) + '*' +
               ltrim(rtrim(round(l_tunnid_kokku, 3) :: TEXT)) + ltEnter;

      END IF;

    ELSE
      -- not percent
      summa = f_round(l_pk_summa, l_round);
      selg = selg + ltrim(rtrim(l_pk_summa :: VARCHAR)) + '/' + ltEnter;
    END IF;
  ELSE
    selg = selg + ' Käsi arvestus või ümardamine ' + ltEnter;
    summa = l_alus_summa;
  END IF;

  --TKI arvestus
  SELECT row_to_json(row)
  INTO l_params
  FROM (SELECT
          summa      AS alus_summa,
          l_TKI_maar AS summa,
          7          AS liik) row;

  tki = f_round(palk.sp_calc_kinni(l_params :: JSONB), l_round);

  selg = selg + 'TKI arvestus:' + round(summa, 2) :: TEXT + '*' + (0.01 * l_TKI_maar) :: TEXT + '*' +
         l_TKI_maar :: TEXT + ltEnter;

  -- PM arvestus
  SELECT row_to_json(row)
  INTO l_params
  FROM (SELECT
          summa     AS alus_summa,
          l_PM_maar AS summa,
          8         AS liik) row;
  pm = f_round(palk.sp_calc_kinni(l_params :: JSONB), l_round) * l_PM_maksustav;

  selg = selg + 'PM arvestus:' + round(summa, 2) :: TEXT + '*' + (0.01 * l_PM_maar) :: TEXT + '*' +
         l_PM_maksustav :: TEXT + ltEnter;

  --SM arvestus
  SELECT row_to_json(row)
  INTO l_params
  FROM (SELECT
          summa      AS alus_summa,
          l_SM_maar  AS summa,
          l_min_sots AS minsots) row;

  sm = f_round(palk.sp_calc_sots(l_params :: JSONB), l_round) * l_SM_maksustav;

  selg = selg + 'SM arvestus: ' + (CASE WHEN summa < l_min_palk * l_min_sots
    THEN l_min_palk
                                   ELSE round(summa, 2) END) :: TEXT +
         '*' + (0.01 * l_SM_maar) :: TEXT + '*' + l_SM_maksustav :: TEXT + ltEnter;

  -- TKA arvestus
  SELECT row_to_json(row)
  INTO l_params
  FROM (SELECT
          summa      AS alus_summa,
          7          AS liik,
          0          AS asutusest,
          l_TKA_maar AS summa) row;

  tka = f_round(palk.sp_calc_muuda(l_params :: JSONB), l_round);

  selg = selg + 'TKA arvestus:' + round(summa, 2) :: TEXT +
         '*' + (0.01 * l_TKA_maar) :: TEXT + ltEnter;

  IF l_lepingid IS NOT NULL AND l_libid IS NOT NULL
  THEN
    -- get taotluse_summa
    l_mvt_kokku = coalesce((SELECT sum(mvt.summa)
                            FROM palk.taotlus_mvt mvt
                              INNER JOIN palk.com_toolepingud t ON t.id = mvt.lepingId
                            WHERE t.parentId = l_isik_id
                                  AND (l_rekvid IS NULL OR t.rekvid = l_rekvid)
                                  AND alg_kpv <= l_kpv
                                  AND lopp_kpv >= l_kpv), 0);

    SELECT
      sum(po.tulubaas)                                          AS isiku_tulubaas,
      sum(po.tulubaas)
        FILTER (WHERE po.tululiik :: TEXT = l_tululiik :: TEXT) AS kasutatud_mvt
    INTO l_isiku_mvt, l_kasutatud_mvt
    FROM palk.cur_palkoper po
      INNER JOIN palk.com_toolepingud t ON t.id = po.lepingId
    WHERE t.parentid = l_isik_id
          AND (l_rekvid IS NULL OR t.rekvid = l_rekvid)
          AND po.period IS NULL
          AND po.palk_liik = 'ARVESTUSED'
          AND (l_alus_summa IS NULL OR po.tululiik :: TEXT = l_tululiik :: TEXT)
          -- calculate only 1 tululiik
          AND year(po.kpv) = year(l_kpv) AND month(po.kpv) = month(l_kpv)
          AND (l_alus_summa IS NOT NULL OR po.id NOT IN (SELECT id
                                                         FROM palk.palk_oper
                                                         WHERE
                                                           kpv = l_kpv
                                                           AND lepingid = l_lepingid
                                                           AND libid = l_libId));

  END IF;

  IF is_umardamine AND l_mvt_kokku > 0
  THEN
    -- не будем считать MVT, а используем уже примененный
    mvt = coalesce(l_kasutatud_mvt, 0);
  ELSE
    -- MVT  arvestus
    SELECT row_to_json(row)
    INTO l_params
    FROM (SELECT
            summa                    AS summa,
            coalesce(l_mvt_kokku, 0) AS mvt_kokku,
            -- should select from taotlused
            coalesce(l_isiku_mvt, 0) AS kokku_kasutatud_mvt,
            -- should select from palk.palk_oper
            tki                      AS tki,
            pm                       AS pm) row;

    mvt = palk.fnc_calc_mvt(l_params :: JSONB);

  END IF;

  -- TM arvestus
  tm = palk.fnc_calc_tm(summa, mvt, tki, pm, l_tululiik);

  selg = selg + 'TM arvestus:' + round(tm, 2) :: TEXT + ltEnter;
  summa = coalesce(summa, 0);

  RETURN;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    selg = SQLERRM;
    summa = 0;
    RETURN;

END;
$$;


/*
select * from palk.sp_calc_arv('{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSONB)
SELECT * FROM palk.sp_calc_arv('{ "alus_summa": 100,"kpv": "2018-04-09"}' :: JSONB)
SELECT * FROM palk.sp_calc_arv('{ "alus_summa": 100,"tululiik":"13","kpv": "2018-04-09"}' :: JSONB)
SELECT * FROM palk.sp_calc_arv('{"kpv": "2018-04-09", "palk": 1200,  "summa":100,"tunnid_kokku":168}' :: JSONB)
SELECT * FROM palk.sp_calc_arv('{"kpv": "2018-04-09", "palk": 1200, "is_percent":false}' :: JSONB)
SELECT * FROM palk.sp_calc_arv('{"kpv": "2018-04-09", "palk": 1200, "is_percent":false, "pm_maksustav":0}' :: JSONB)
SELECT * FROM palk.sp_calc_arv('{"kpv": "2018-04-09", "palk": 1200, "is_percent":false, "sm_maksustav":0}' :: JSONB)

*/