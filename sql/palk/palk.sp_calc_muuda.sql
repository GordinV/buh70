DROP FUNCTION IF EXISTS sp_calc_muuda( INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS palk.sp_calc_muuda(params JSONB );

CREATE FUNCTION palk.sp_calc_muuda(params JSONB)
  RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid   INTEGER = params ->> 'lepingid';
  l_libId      INTEGER = params ->> 'libid';
  l_kpv        DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  l_alus_summa NUMERIC = params ->> 'alus_summa';
  l_pk_summa   NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, 0.8); -- default TKA
  is_percent   BOOLEAN = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                  TRUE); -- kas pk summa percentis (33%)
  l_asutusest  INTEGER = coalesce((params ->> 'asutusest') :: INTEGER, 1);
  l_liik       INTEGER = coalesce((params ->> 'liik') :: INTEGER,
                                  array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS'));
  l_round      NUMERIC = 0.01;

  l_summa      NUMERIC(14, 4) = 0;
  v_tulemus    RECORD;
BEGIN

  IF l_alus_summa IS NULL
  THEN
    --load metadata
    SELECT
      p.summa,
      p.asutusest,
      p.liik,
      l.round,
      empty(p.percent_ :: INTEGER)
    INTO l_pk_summa, l_asutusest, l_liik, l_round, is_percent
    FROM palk.com_palk_kaart p
      INNER JOIN palk.com_palk_lib l ON p.libid = l.id
    WHERE p.lepingid = l_lepingid AND p.libId = l_libId;

  END IF;

  IF l_alus_summa IS NULL
  THEN
    IF is_percent
    THEN -- считаем в процентах от брутто зп
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
        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
             AND empty(l_asutusest)
        THEN
          l_summa = v_tulemus.tki;
        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
             AND NOT empty(l_asutusest)
        THEN
          l_summa = v_tulemus.tka;

        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'PENSIONIMAKS')
        THEN
          l_summa = f_round(v_tulemus.pm, l_round);

      END CASE;
    END IF;
  ELSE
    IF is_percent
    THEN
      l_summa = f_round(l_alus_summa * 0.01 * l_pk_summa, l_round);
    END IF;
  END IF;

  IF NOT is_percent
  THEN
    l_summa = f_round(l_pk_summa, l_round);
  END IF;
  RETURN coalesce(l_summa, 0);
END;
$$;

/*
select palk.sp_calc_muuda('{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSONB)
select palk.sp_calc_muuda('{"alus_summa":100}'::JSONB)
select palk.sp_calc_muuda('{"alus_summa":100, "summa":2}'::JSONB)
select palk.sp_calc_muuda('{"alus_summa":0, "summa":100, "is_percent":false}'::JSONB)
 */