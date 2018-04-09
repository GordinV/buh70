DROP FUNCTION IF EXISTS sp_calc_muuda( INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS palk.sp_calc_muuda(params JSONB );

CREATE FUNCTION palk.sp_calc_muuda(params JSONB)
  RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid    INTEGER = params ->> 'lepingid';
  l_libId       INTEGER = params ->> 'libid';
  l_kpv         DATE = coalesce((params ->> 'kpv') :: DATE, current_date);

  l_summa       NUMERIC(14, 4) = 0;
  v_palk_kaart  RECORD;
  v_tulemus     RECORD;
BEGIN

  --load metedata
  SELECT pk.*
  INTO v_palk_kaart
  FROM palk.com_palk_kaart pk
  WHERE pk.lepingid = l_lepingid
        AND pk.libId = l_libId;

  IF NOT empty(v_palk_kaart.percent_)  -- = 1 считаем в процентах от брутто зп
  THEN
    SELECT
      sum(coalesce(tka, 0))       AS tka,
      sum(coalesce(tootumaks, 0)) AS tki,
      sum(coalesce(pensmaks, 0))  AS pm
    INTO v_tulemus
    FROM palk.cur_palkoper po
    WHERE lepingid = l_lepingid
          AND kpv = l_kpv
          AND liik = '+';
    CASE
      WHEN v_palk_kaart.liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
           AND empty(v_palk_kaart.asutusest)
      THEN
        l_summa = v_tulemus.tki;
      WHEN v_palk_kaart.liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
           AND NOT empty(v_palk_kaart.asutusest)
      THEN
        l_summa = v_tulemus.tka;

      WHEN v_palk_kaart.liik = array_position((enum_range(NULL :: PALK_LIIK)), 'PENSIONIMAKS')
      THEN
        l_summa = f_round(v_tulemus.pm, v_palk_kaart.round);

    END CASE;
  ELSE
    l_summa := f_round(v_palk_kaart.Summa, v_palk_kaart.round);
  END IF;

  RETURN coalesce(l_summa,0);
END;
$$;

/*
select palk.sp_calc_muuda('{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSONB)
 */