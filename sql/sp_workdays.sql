DROP FUNCTION IF EXISTS sp_workdays( INTEGER, INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS sp_workdays( JSONB );

CREATE FUNCTION sp_workdays(IN params JSONB)
  RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid     INTEGER = params ->> 'lepingid';
  l_kuu          INTEGER = coalesce((params ->> 'kuu') :: INTEGER, month(current_date));
  l_aasta        INTEGER = coalesce((params ->> 'aasta') :: INTEGER, year(current_date));
  l_esimine_paev INTEGER = coalesce((params ->> 'paev') :: INTEGER, 1);
  l_lopp_paev    INTEGER = coalesce((params ->> 'lopp') :: INTEGER, 31);

  l_maxdays      INTEGER = DAY(GOMONTH(DATE(l_aasta, l_kuu, 1), 1) - 1);
  l_holidays     INTEGER = 0;
  l_date         DATE = DATE(l_aasta, l_kuu, l_esimine_paev); -- arv. kuupaev
  l_rekvId       INTEGER;
  qrytoograf     RECORD;
  lnDow          INT;
BEGIN


  IF l_lepingid IS NOT NULL
  THEN
    IF exists(SELECT 1
              FROM palk.toograf
              WHERE lepingid = l_lepingid
                    AND kuu = l_kuu
                    AND aasta = l_aasta)
    THEN
      -- find exists data about working ours
      SELECT
        p.*,
        t.toopaev
      INTO qrytoograf
      FROM palk.toograf p
        INNER JOIN palk.tooleping t ON t.id = p.lepingid
      WHERE p.lepingid = l_lepingid
            AND p.kuu = l_kuu
            AND p.aasta = l_aasta;

      RETURN (coalesce(qrYtoograf.tuNd, 0) / coalesce(qrYtoograf.toOpaev, 8)) :: INTEGER;

    END IF;

    SELECT rekvid
    INTO l_rekvId
    FROM palk.tooleping
    WHERE id = l_lepingid;
  END IF;

  IF l_maxdays > l_lopp_paev
  THEN
    l_maxdays = l_lopp_paev;
  END IF;
raise notice 'l_esimine_paev %', l_esimine_paev;
  FOR i IN l_esimine_paev..l_maxdays
  LOOP
    lnDow:=DOW(l_date);
    IF lnDOW = 6 OR lnDOW = 7 OR lnDow = 0
    THEN
      l_holidays := l_holidays + 1;
    ELSE
      IF exists(SELECT 1
                FROM cur_tahtpaevad l
                WHERE (l_rekvId IS NULL OR l.rekvid = l_rekvId)
                      AND l.paEv = DAY(l_date)
                      AND kuu = MONTH(l_date)
                      AND (aasta IS NULL OR aasta = year(l_date)))
      THEN
        l_holidays := l_holidays + 1;
      END IF;
    END IF;
    l_date := l_date + 1;
  END LOOP;

  RETURN coalesce((l_maxdays - l_holidays - l_esimine_paev + 1), 0);
END;
$$;

/*
SELECT sp_workdays(NULL :: JSONB);

SELECT sp_workdays('{"kuu":1,"aasta":2018}' :: JSONB);

SELECT sp_workdays('{"kuu":1,"aasta":2018,"lepingid":2}' :: JSONB);

SELECT sp_workdays('{"kuu":1,"aasta":2018,"lepingid":2}' :: JSONB);

SELECT sp_workdays('{"kuu":1,"aasta":2018,"lepingid":2, "paev":4, "lopp":20}' :: JSONB);

*/