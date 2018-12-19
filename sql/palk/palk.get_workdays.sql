DROP FUNCTION IF EXISTS palk.get_work_days( JSON );

CREATE FUNCTION palk.get_work_days(IN params JSON)
  RETURNS INTEGER
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
  l_result integer = 0;
BEGIN
  l_result = (SELECT qry.result
   FROM sp_workdays((SELECT row_to_json(row)
                     FROM (SELECT l_esimine_paev AS paev,
                                  l_lopp_paev AS lopp) row) :: JSON) qry);

  return l_result;

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