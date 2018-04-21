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
  l_alus_summa NUMERIC = params ->> 'alus_summa';
  l_asutusest  INTEGER = coalesce((params ->> 'asutusest') :: INTEGER, 1);
  l_liik       INTEGER = params ->> 'liik';
  l_pk_summa   NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, CASE WHEN l_liik = 7 THEN 1.6 ELSE 2 END);
  is_percent   BOOLEAN = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                  TRUE); -- kas pk summa percentis (33%)

  l_summa      NUMERIC(12, 4) = 0;
  l_round      NUMERIC = 0.01;

  l_kulumaks   NUMERIC(12, 4) = 0;
  l_params     JSON;
  v_tulemus    RECORD;
BEGIN

  raise notice 'kinni l_pk_summa %', l_pk_summa;
  IF l_alus_summa IS NULL
  THEN

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


    IF (NOT empty(l_asutusest)
        AND l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')) --tka
    THEN

      SELECT row_to_json(row)
      INTO l_params
      FROM (SELECT
              month(l_kpv) AS kuu,
              year(l_kpv)  AS aasta,
              l_lepingid   AS lepingid) row;

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
        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
             AND NOT empty(l_asutusest)
        THEN
          l_summa = v_tulemus.tki;
        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TULUMAKS')
        THEN
          l_summa = v_tulemus.tm;

        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'PENSIONIMAKS')
        THEN
          l_summa = f_round(v_tulemus.pm, l_round);
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
  ELSE
    IF is_percent
    THEN
      -- summa in pk is in percent
      l_summa = f_round(l_alus_summa * l_pk_summa * 0.01, l_round);
    ELSE
      l_summa = f_round(l_pk_summa, l_round);
    END IF;
  END IF; -- l_alus_summ
  RETURN coalesce(l_summa, 0);
END;
$$;

/*
select palk.sp_calc_kinni('{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSONB)
select palk.sp_calc_kinni('{"alus_summa":100, "liik":7}'::JSONB)
select palk.sp_calc_kinni('{"alus_summa":100, "liik":8, "summa":3}'::JSONB)
select palk.sp_calc_kinni('{"alus_summa":0,"liik":8, "summa":100, "is_percent":false}'::JSONB)
 */