DROP FUNCTION IF EXISTS palk.get_work_hours(params JSONB );

CREATE FUNCTION palk.get_work_hours(params JSONB)
  RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid   INTEGER = params ->> 'lepingid';
  l_kpv        DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  l_tund       INTEGER = params ->> 'tund';
  l_start_paev INTEGER = coalesce((params ->> 'paev') :: INTEGER, 1);
  l_lopp_paev  INTEGER = coalesce((params ->> 'lopp') :: INTEGER, day(get_last_day(l_kpv)));
  l_toopaev    NUMERIC = params ->> 'toopaev';
  l_puudumised NUMERIC = 0; -- puudumised tunnid
  v_taabel     RECORD;
  l_params     JSON;
BEGIN

  IF l_tund IS NULL AND l_lepingid IS NOT NULL
  THEN
    -- parameter tund puudub, võttame taabelist

    SELECT t.tund
    INTO l_tund
    FROM palk.cur_toografik t
    WHERE lepingid = l_lepingid
          AND kuu = month(l_kpv)
          AND aasta = year(l_kpv);

  END IF;

  -- proovime leia kui palju töötunnid tööpäevas
  IF l_toopaev IS NULL AND l_lepingid IS NOT NULL
  THEN
    --otsime tööpäev
    SELECT toopaev
    INTO l_toopaev
    FROM palk.com_toolepingud t
    WHERE id = l_lepingid;

  END IF;

  IF coalesce(l_tund, 0) = 0
  THEN
    -- parameter või tööajagraafik puudub, arvestame
    SELECT row_to_json(row)
    INTO l_params
    FROM (SELECT
            month(l_kpv) AS kuu,
            year(l_kpv)  AS aasta,
            l_lepingid   AS lepingid,
            l_start_paev AS paev,
            l_lopp_paev  AS lopp) row;

    l_tund = (select result from sp_workdays(l_params :: JSON)) * coalesce(l_toopaev, 8);

  END IF;

  RAISE NOTICE 'l_tund %, l_toopaev %', l_tund, l_toopaev;
  l_puudumised = palk.get_puudumine(l_params :: JSONB);

  RETURN coalesce(l_tund, 0) - coalesce(l_puudumised, 0);

END;
$$;

/*
select palk.get_work_hours('{"lepingid":4, "kpv":"2018-04-18"}'::jsonb)  -- -> 0
select palk.get_work_hours(null::jsonb)  -- -> 0
select palk.get_work_hours('{"kpv":"2018-04-18","toopaev":4}'::jsonb)  -- -> 0
 */