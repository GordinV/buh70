DROP FUNCTION IF EXISTS check_puhkus(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.check_puhkus(JSONB);
DROP FUNCTION IF EXISTS palk.check_puudumine(JSONB);
DROP FUNCTION IF EXISTS palk.get_puudumine(params JSONB);

CREATE FUNCTION palk.get_puudumine(params JSONB)
  RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid       INTEGER = params ->> 'lepingid';
  l_kuu            INTEGER = params ->> 'kuu';
  l_aasta          INTEGER = params ->> 'aasta';
  l_pohjus         TEXT = (params ->> 'pohjus');

  l_start_paev     INTEGER;
  l_lopp_paev      INTEGER;

  l_result         NUMERIC = 0;
  qryPuhkused      RECORD;
  l_puhkuse_tunnid NUMERIC = 0;
  l_paevad NUMERIC = 0;
  params JSONB;
BEGIN

  --selecting data
  FOR qryPuhkused IN
  SELECT p.*, toopaev, (SELECT palk.get_work_days((SELECT row_to_json(row)
                                          FROM (SELECT day(p.kpv1) AS paev,
                                                       day(p.kpv2) AS lopp) row) :: JSON))  AS too_kpv
  FROM palk.cur_puudumine p
         INNER JOIN palk.tooleping t ON t.id = p.lepingid
  WHERE p.lepingid = l_lepingid
    AND (month(p.kpv1) = l_kuu AND year(p.kpv1) = l_aasta
           OR (month(kpv2) = l_kuu AND year(kpv2) = l_aasta))
    AND (l_pohjus IS NULL OR p.pohjus = l_pohjus)
  LOOP
    -- arvestame alg. päev
    IF month(qryPuhkused.kpv1) = l_kuu AND year(qryPuhkused.kpv1) = l_aasta
    THEN
      l_start_paev = day(qryPuhkused.kpv1);
    ELSE
      l_start_paev = 1;
    END IF;

    --arvestame lõpp päev
    IF month(qryPuhkused.kpv2) = l_kuu AND year(qryPuhkused.kpv2) = l_aasta
    THEN
      l_lopp_paev = day(qryPuhkused.kpv2);
    ELSE
      l_lopp_paev = get_last_day(date(tnAasta, tnKuu, 1));
    END IF;

    -- считаем часы по кол-ву раб. дней
    SELECT row_to_json(row)
        INTO params
    FROM (SELECT l_kuu        AS kuu,
                 l_aasta      AS aasta,
                 l_lepingid   AS lepingid,
                 l_start_paev AS paev,
                 l_lopp_paev  AS lopp) row;


    -- arvestame tunnid
    SELECT sum(p.summa), (SELECT  palk.get_work_days(params :: JSON)) as paevad
        INTO l_puhkuse_tunnid, l_paevad
    FROM palk.cur_puudumine p
    WHERE lepingid = l_lepingid
      AND ((month(kpv1) = l_kuu AND year(kpv1) = l_aasta)
             OR (month(kpv2) = l_kuu AND year(kpv2) = l_aasta))
      AND (l_pohjus IS NULL OR p.pohjus = l_pohjus);

    IF (l_paevad is null or empty(l_paevad)) and coalesce(l_puhkuse_tunnid, 0) > 0
    THEN
      l_result = l_result + (l_puhkuse_tunnid / qryPuhkused.toopaev);
    ELSE
      l_result = l_result + l_paevad;
    END IF;
  END LOOP;
  RETURN l_result;

END;
$$;



GRANT EXECUTE ON FUNCTION palk.get_puudumine(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_puudumine(JSONB) TO dbpeakasutaja;


/*
select palk.get_puudumine('{"lepingid":27377, "kuu":11, "aasta":2018}'::jsonb)  -- -> 0

select palk.get_puudumine(null::jsonb)  -- -> 0
select palk.get_puudumine('{"lepingid":4}'::jsonb)  -- -> 0
select palk.get_puudumine('{"lepingid":4, "kuu":4, "aasta":2018}'::jsonb)  -- -> 0
select palk.get_puudumine('{"lepingid":4, "kuu":4, "aasta":2018, "pohjus":"PUHKUS"}'::jsonb)  -- -> 0
 */