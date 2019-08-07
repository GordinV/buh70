DROP FUNCTION IF EXISTS palk.sp_calc_kinni( INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS palk.sp_calc_kinni(params JSONB );
DROP FUNCTION IF EXISTS palk.sp_calc_kinni( INTEGER, params JSON );

CREATE FUNCTION palk.sp_calc_kinni(IN  user_id       INTEGER, IN params JSON, OUT summa NUMERIC,
                                   OUT selg          TEXT,
                                   OUT error_code    INTEGER,
                                   OUT result        INTEGER,
                                   OUT error_message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid   INTEGER = params ->> 'lepingid';
  l_libId      INTEGER = params ->> 'libid';
  l_kpv        DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  l_alus_summa NUMERIC = params ->> 'alus_summa';
  l_asutusest  INTEGER = coalesce((params ->> 'asutusest') :: INTEGER, 1);
  l_liik       INTEGER = params ->> 'liik';
  l_pk_summa   NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, CASE WHEN l_liik = 7
    THEN 1.6
                                                                   ELSE 2 END);
  is_percent   BOOLEAN = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                  TRUE); -- kas pk summa percentis (33%)

  l_round      NUMERIC = 0.01;

  l_kulumaks   NUMERIC(12, 4) = 0;
  l_params     JSON;
  v_tulemus    RECORD;
  l_enter      TEXT = '(r)'; -- Перевод строки
BEGIN

  IF l_alus_summa IS NULL
  THEN

      raise notice 'l_alus_summa IS NULL';
    selg = coalesce(selg, '') || 'sql' || l_enter;
    SELECT
      p.summa,
      p.asutusest,
      p.liik,
      l.round,
      not empty(p.percent_ :: INTEGER)
    INTO l_pk_summa, l_asutusest, l_liik, l_round, is_percent
    FROM palk.com_palk_kaart p
      INNER JOIN palk.com_palk_lib l ON p.libid = l.id
    WHERE p.lepingid = l_lepingid AND p.libId = l_libId;

    IF (NOT empty(l_asutusest)
        AND l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')) --tka
    THEN

      summa = (SELECT qry.summa
               FROM palk.sp_calc_muuda(user_id, params) AS qry);
      selg = coalesce(selg, '') || 'arvestatakse muud ' || summa :: TEXT || l_enter;

    ELSE

      SELECT
        sum(po.summa)  AS summa,
        sum(tootumaks) AS tki,
        sum(tulumaks)  AS tm,
        sum(pensmaks)  AS pm
      INTO v_tulemus
      FROM palk.cur_palkoper po
      WHERE po.lepingid = l_lepingid
            AND liik = '+'
            AND kpv = l_kpv;

        l_alus_summa =  v_tulemus.summa;
      raise notice 'arvestan alus l_alus_summa %, v_tulemus.summa %',l_alus_summa, v_tulemus.summa ;

      CASE
        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
             AND empty(l_asutusest)
        THEN
          summa = v_tulemus.tki;
        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TULUMAKS')
        THEN
          summa = v_tulemus.tm;

        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'PENSIONIMAKS')
        THEN
          summa = f_round(v_tulemus.pm, l_round);
        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'KINNIPIDAMISED')
          AND NOT is_percent
          THEN
              raise notice 'Kinni, not percent';
            summa = l_pk_summa;
        WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'KINNIPIDAMISED')
          AND is_percent
          THEN
            raise notice 'Kinni, not percent';
            summa = f_round(l_alus_summa * l_pk_summa * 0.01, l_round);
            selg = coalesce(selg, '') || 'arvestus ' || l_alus_summa :: TEXT || ' * ' || l_pk_summa :: TEXT || ' * 0.01 ' ||
                   l_enter;

      ELSE
        summa = 0;
      END CASE;
      selg = coalesce(selg, '') || 'ennearvestatud maksud ' || summa :: TEXT || l_enter;
    END IF;

    -- muudetud 23/02/2005
    IF summa > 0
    THEN
      -- kontrol kas on tulumaks avansimaksetest

      SELECT sum(p.summa)
      INTO l_kulumaks
      FROM palk.cur_palkoper p
      WHERE p.lepingId = l_lepingid
            AND YEAR(p.kpv) = YEAR(l_kpv)
            AND MONTH(p.kpv) = MONTH(l_kpv)
            AND p.libId = l_libId
            AND p.MUUD = 'AVANS';

      IF l_kulumaks > 0
      THEN
        summa = summa - l_kulumaks;
        selg = coalesce(selg, '') || 'miinus avans ' || l_kulumaks :: TEXT || l_enter;
      END IF;
    END IF;
  ELSE
    raise notice 'Enne';
    IF is_percent
    THEN

        raise notice 'is_percent %', is_percent;
      -- summa in pk is in percent
      summa = f_round(l_alus_summa * l_pk_summa * 0.01, l_round);
      selg = coalesce(selg, '') || 'arvestus ' || l_alus_summa :: TEXT || ' * ' || l_pk_summa :: TEXT || ' * 0.01 ' ||
             l_enter;
    ELSE
      summa = f_round(l_pk_summa, l_round);
      selg = coalesce(selg, '') || 'pk summa ' || l_pk_summa :: TEXT || l_enter;
    END IF;
  END IF; -- l_alus_summ
  result = 1;
  RETURN;
END;
$$;

/*
select * from palk.sp_calc_kinni(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSON)
select palk.sp_calc_kinni(1,'{"alus_summa":100, "liik":7}'::JSON)
select palk.sp_calc_kinni(1,'{"alus_summa":100, "liik":8, "summa":3}'::JSON)
select palk.sp_calc_kinni(1,'{"alus_summa":0,"liik":8, "summa":100, "is_percent":false}'::JSON)

select summa from palk.sp_calc_kinni(1,'{"alus_summa":100.0000,"summa":2.00,"liik":8}'::json) --pm
select summa, * from palk.sp_calc_kinni(1,'{"lepingid":4,"libid":528,"kpv":20180501}'::json) --tki
select * from palk.sp_calc_kinni(1, '{"lepingid":4,"libid":529,"kpv":20180501}'::JSON)


 */