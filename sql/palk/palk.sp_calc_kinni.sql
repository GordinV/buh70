DROP FUNCTION IF EXISTS palk.sp_calc_kinni( INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS palk.sp_calc_kinni(params JSONB );

CREATE FUNCTION palk.sp_calc_kinni(params JSONB)
  RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid   INTEGER = params ->> 'lepingid';
  l_libId      INTEGER = params ->> 'libid';
  l_kpv        DATE = coalesce((params ->> 'kpv') :: DATE, current_date);

  l_summa      NUMERIC(12, 4) = 0;
  v_palk_kaart RECORD;
  v_tooleping  RECORD;
  v_palkLib    RECORD;
  v_taabel     RECORD;
  l_palk       NUMERIC(12, 4) = 0;
  nHours       INTEGER = 0;
  l_kulumaks   NUMERIC(12, 4) = 0;
  l_params     JSON;
  v_tulemus    RECORD;
BEGIN
  SELECT t.*
  INTO v_tooleping
  FROM palk.tooleping t
  WHERE t.id = l_lepingid;

  SELECT *
  INTO v_palkLib
  FROM palk.com_palk_lib
  WHERE id = l_libId;

  SELECT *
  INTO v_taabel
  FROM palk.cur_palk_taabel t
  WHERE t.lepingId = l_lepingid AND t.kuu = month(l_kpv) AND t.aasta = year(l_kpv);

  SELECT p.*
  INTO v_palk_kaart
  FROM palk.com_palk_kaart p
  WHERE p.lepingid = l_lepingid AND p.libId = l_libId;

  IF (NOT empty(v_palkLib.asutusest)
      AND v_palkLib.LIIK = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')) --tka
  THEN

    SELECT row_to_json(row)
    INTO l_params
    FROM (SELECT
           month(l_kpv)       AS kuu,
            year(l_kpv)     AS aasta,
            l_lepingid  AS lepingid) row;

    l_summa = palk.sp_calc_muuda(l_params);

  ELSE
    SELECT
      sum(tootumaks) AS tki,
      sum(tulumaks)  AS tm,
      sum(pensmaks)  AS pm
    INTO v_tulemus
    FROM palk.cur_palkoper po
    WHERE po.lepingid = l_lepingid
          AND liik = '+'
          AND kpv = l_kpv;

    CASE
      WHEN v_palk_kaart.liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
           AND NOT empty(v_palk_kaart.asutusest)
      THEN
        l_summa = v_tulemus.tki;
      WHEN v_palk_kaart.liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TULUMAKS')
      THEN
        l_summa = v_tulemus.tm;

      WHEN v_palk_kaart.liik = array_position((enum_range(NULL :: PALK_LIIK)), 'PENSIONIMAKS')
      THEN
        l_summa = f_round(v_tulemus.pm, v_palk_kaart.round);
    ELSE
      l_summa = 0;
    END CASE;

  END IF;

  -- muudetud 23/02/2005
  IF l_summa > 0
  THEN
    -- kontrol kas on tulumaks avansimaksetest

    SELECT sum(summa)
    INTO l_kulumaks
    FROM palk.cur_palkoper p
    WHERE p.lepingId = l_lepingid
          AND YEAR(p.kpv) = YEAR(l_kpv)
          AND MONTH(p.kpv) = MONTH(l_kpv)
          AND p.libId = l_libId
          AND p.MUUD = 'AVANS';

    IF l_kulumaks > 0
    THEN
      l_summa = l_summa - l_kulumaks;
    END IF;
  END IF;

  RETURN coalesce(l_summa, 0);
END;
$$;

/*
select palk.sp_calc_kinni('{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSONB)
 */