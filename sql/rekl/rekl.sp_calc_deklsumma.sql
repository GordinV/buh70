DROP FUNCTION IF EXISTS rekl.sp_calc_deklsumma( INTEGER, DATE );

CREATE FUNCTION rekl.sp_calc_deklsumma(l_id INTEGER, l_kpv DATE)
  RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE

  v_luba    RECORD;

  l_alg_kpv  DATE;
  l_lopp_kpv DATE;
  l_summa   NUMERIC = 0;
  l_paevad  INT;
BEGIN

  SELECT l.*
  INTO v_luba
  FROM rekl.luba l
  WHERE l.parentid = l_id;

  IF v_luba.id IS NULL
  THEN
    RAISE EXCEPTION 'Luba not found %', l_id;
  END IF;

  IF l_kpv >= v_luba.algkpv AND l_kpv <= v_luba.loppkpv
  THEN
    l_summa = v_luba.summa;
--  ELSE
--    RAISE EXCEPTION 'Vigane period %', l_kpv;
  END IF;

  IF v_luba.kord = 'PAEV'
  THEN
    RETURN v_luba.summa;
  END IF;

  IF l_summa > 0
  THEN
    IF v_luba.kord = 'NADAL'
    THEN
      l_paevad = l_kpv - v_luba.algkpv + 1;
      l_alg_kpv = v_luba.algkpv + (floor(l_paevad / 7)) * 7;
      l_summa = (l_summa / 7) * (l_kpv - l_alg_kpv);

    ELSEIF ltrim(rtrim(v_luba.kord)) = 'KUU'
      THEN
        -- OTSIME alg kpv
        RAISE NOTICE 'Kuu';
        l_alg_kpv = date(year(v_luba.algkpv), month(v_luba.algkpv), 1);
        l_lopp_kpv = (l_alg_kpv + interval '1 month')::date - 1;
--        l_lopp_kpv = gomonth(l_alg_kpv, 1) - 1;

        IF v_luba.algkpv > l_alg_kpv AND month(l_kpv) = month(v_luba.algkpv) AND year(l_kpv) = year(v_luba.algkpv)
        THEN
          -- esimine kuu
          l_summa = (l_summa / 30) * (v_luba.algkpv - l_alg_kpv);
        ELSEIF month(l_kpv) = month(v_luba.loppkpv) AND year(l_kpv) = year(v_luba.loppkpv)
          THEN
            -- viimane kuu
            l_alg_kpv = date(year(v_luba.loppkpv), month(v_luba.loppkpv), 1);
            l_paevad = (v_luba.loppkpv - l_alg_kpv);

            IF l_paevad > 30
            THEN
              l_paevad = 30;
            END IF;

            l_summa = (l_summa / 30) * l_paevad;
        END IF; --alg lopp kpv
        --		end if; -- kord
    ELSEIF ltrim(rtrim(v_luba.kord)) = 'KVARTAL'
      THEN
        -- OTSIME alg kpv

        -- kvartal number
        IF (l_kpv - v_luba.algkpv) < 90 OR (v_luba.loppkpv - l_kpv) < 90
        THEN
          IF month(l_kpv) < 4
          THEN
            l_alg_kpv = date(year(l_kpv), 1, 1);
            l_lopp_kpv = date(year(l_kpv), 3, 31);
          ELSEIF month(l_kpv) > 3 AND month(l_kpv) < 7
            THEN
              l_alg_kpv = date(year(l_kpv), 4, 1);
              l_lopp_kpv = date(year(l_kpv), 6, 30);
          ELSEIF month(l_kpv) > 6 AND month(l_kpv) < 10
            THEN
              l_alg_kpv = date(year(l_kpv), 7, 1);
              l_lopp_kpv = date(year(l_kpv), 9, 30);
          ELSE
            l_alg_kpv = date(year(l_kpv), 10, 1);
            l_lopp_kpv = date(year(l_kpv), 12, 31);
          END IF;

          IF v_luba.loppkpv <= l_lopp_kpv AND v_luba.algkpv >= l_alg_kpv
          THEN

            l_summa = (l_summa / 90) * (v_luba.loppkpv - v_luba.algkpv + 1);
          ELSEIF v_luba.algkpv > l_alg_kpv AND l_lopp_kpv < v_luba.loppkpv
            THEN
              -- esimine kvartal
              l_summa = (l_summa / 90) * (l_lopp_kpv - v_luba.algkpv + 1);
          ELSEIF v_luba.loppkpv < l_lopp_kpv AND v_luba.algkpv < l_alg_kpv
            THEN
              -- viimane kvartal

              l_summa = (l_summa / 90) * (v_luba.loppkpv - l_alg_kpv + 1);
          END IF; --alg lopp kpv
        END IF; -- kvartal
    ELSEIF ltrim(rtrim(v_luba.kord)) = 'AASTA'
      THEN
        -- OTSIME alg kpv

        l_alg_kpv = date(year(l_kpv), 1, 1);
        l_lopp_kpv = date(year(l_kpv), 12, 31);

        IF l_alg_kpv <> v_luba.algkpv OR l_lopp_kpv <> v_luba.loppkpv
        THEN
          IF v_luba.loppkpv <= l_lopp_kpv AND v_luba.algkpv >= l_alg_kpv
          THEN
            l_summa = (l_summa / 360) * (v_luba.loppkpv - v_luba.algkpv);
          ELSEIF v_luba.algkpv > l_alg_kpv AND l_lopp_kpv <= v_luba.loppkpv
            THEN
              -- esimine aasta
              l_summa = (l_summa / 360) * (l_lopp_kpv - v_luba.algkpv);
          ELSEIF v_luba.loppkpv < l_lopp_kpv AND v_luba.algkpv <= l_alg_kpv
            THEN
              -- viimane aasta
              l_summa = (l_summa / 360) * (v_luba.loppkpv - l_alg_kpv);
          END IF; --alg lopp kpv
        END IF; --aasta
    END IF; -- kord
  END IF; -- summa

  RETURN l_summa;

END;
$$;


/*
select  rekl.sp_calc_deklsumma(294175, date('2018-06-30'));

update rekl.luba set algkpv = date(2018,06,01), loppkpv = date(2018,12,31), summa = 100 where parentid = 294175
*/

