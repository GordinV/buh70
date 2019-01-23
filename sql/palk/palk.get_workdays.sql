DROP FUNCTION IF EXISTS palk.get_work_days(JSON);

CREATE FUNCTION palk.get_work_days(IN params JSON)
  RETURNS INTEGER
  LANGUAGE plpgsql
AS
$$
DECLARE
  l_lepingid     INTEGER = params ->> 'lepingid';
  l_kuu          INTEGER = coalesce((params ->> 'kuu') :: INTEGER, month(current_date));
  l_aasta        INTEGER = coalesce((params ->> 'aasta') :: INTEGER, year(current_date));
  l_esimine_paev INTEGER = coalesce((params ->> 'paev') :: INTEGER, 1);
  l_lopp_paev    INTEGER = coalesce((params ->> 'lopp') :: INTEGER, 31);
  l_rekvid       INTEGER = params ->> 'rekvid';

  l_maxdays      INTEGER = DAY(GOMONTH(DATE(l_aasta, l_kuu, 1), 1) - 1);
  l_holidays     INTEGER = 0;
  l_date         DATE    = DATE(l_aasta, l_kuu, l_esimine_paev); -- arv. kuupaev
  qrytoograf     RECORD;
  lnDow          INT;
  l_result       INTEGER = 0;
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

      RETURN (coalesce(qrYtoograf.tuNd, 0) / coalesce(qrYtoograf.toOpaev, 8));

    END IF;

    IF l_rekvid IS NULL
    THEN
      SELECT rekvid
             INTO l_rekvId
      FROM palk.tooleping
      WHERE id = l_lepingid;
    END IF;
  END IF;

  IF l_maxdays > l_lopp_paev
  THEN
    l_maxdays = l_lopp_paev;
  END IF;

  FOR i IN l_esimine_paev..l_maxdays
    LOOP
      lnDow := DOW(l_date);

      IF lnDOW = 6 OR lnDOW = 7 OR lnDow = 0
      THEN
        l_holidays := l_holidays + 1;
      ELSE
        IF exists(SELECT 1
                  FROM cur_tahtpaevad l
                  WHERE (l.rekvId IS NULL OR l.rekvid = l_rekvId)
                    AND
                    l.paEv = DAY(l_date)
                    AND kuu = MONTH(l_date)
                    AND (aasta IS NULL OR aasta = year(l_date)))
        THEN
          l_holidays := l_holidays + 1;
        END IF;
      END IF;
      l_date := l_date + 1;
    END LOOP;

  l_result = COALESCE((l_maxdays - l_holidays - l_esimine_paev + 1), 0) :: INTEGER;
  RETURN l_result;

END;
$$;

GRANT EXECUTE ON FUNCTION palk.get_work_days( JSON ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_work_days( JSON ) TO dbpeakasutaja;


/*
SELECT sp_workdays(1, NULL :: JSON);

SELECT sp_workdays('{"kuu":1,"aasta":2018}' :: JSON);

SELECT sp_workdays('{"kuu":1,"aasta":2018,"lepingid":2}' :: JSON);

SELECT sp_workdays('{"kuu":1,"aasta":2018,"lepingid":2}' :: JSON);

SELECT sp_workdays('{"kuu":1,"aasta":2018,"lepingid":2, "paev":4, "lopp":20}' :: JSON);

*/