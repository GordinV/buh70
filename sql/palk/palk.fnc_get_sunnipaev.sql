DROP FUNCTION IF EXISTS palk.fnc_get_sunnipaev( INTEGER, JSON );

CREATE FUNCTION palk.fnc_get_sunnipaev(IN  user_id       INTEGER,
                                       IN  params        JSON,
                                       OUT error_code    INTEGER,
                                       OUT result        INTEGER,
                                       OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  l_isikukood TEXT = params ->> 'isikukood';
  l_sajandik  TEXT = CASE WHEN left(l_isikukood, 1) :: INTEGER < 4
    THEN '19'
                     ELSE '20' END;
  l_aasta     TEXT = l_sajandik || substring(l_isikukood FROM 2 FOR 2);
BEGIN
  IF l_isikukood IS NULL
  THEN
    error_code = 6;
    error_message = 'Puudub isikukood';
    RETURN;
  END IF;
  result = date_part('year', now()) - l_aasta :: INTEGER;
  RETURN;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_code = 1;
    error_message = SQLERRM;
    result = 0;
    RETURN;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.fnc_get_sunnipaev( INTEGER, JSON ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.fnc_get_sunnipaev( INTEGER, JSON ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.fnc_get_sunnipaev( INTEGER, JSON ) TO dbvaatleja;


/*
SELECT *
FROM palk.fnc_get_sunnipaev(1, '{
  "isikukood": "37303023721"
}');
*/