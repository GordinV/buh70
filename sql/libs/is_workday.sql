DROP FUNCTION IF EXISTS is_workday( DATE, INTEGER );

CREATE FUNCTION is_workday(l_kpv DATE, l_rekv_id INTEGER)
  RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN

  IF dow(l_kpv) IN (0, 6, 7) OR
     exists(SELECT 1
            FROM cur_tahtpaevad
            WHERE rekvid = l_rekv_id
                  AND paEv = DAY(l_kpv) AND kuU = MONTH(l_kpv))
  THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;

END;
$$;

/*
SELECT * from is_workday( current_date, 1)
SELECT * from is_workday( '2018-01-01', 1)
*/