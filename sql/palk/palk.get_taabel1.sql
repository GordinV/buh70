DROP FUNCTION IF EXISTS palk.get_taabel(JSONB);

CREATE FUNCTION palk.get_taabel(IN params JSONB, OUT result NUMERIC)
    LANGUAGE plpgsql
AS
$$
BEGIN
    result = (SELECT t.result from palk.get_taabel2(params) t);
    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION palk.get_taabel( JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.get_taabel( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_taabel( JSONB ) TO dbpeakasutaja;

SELECT palk.get_taabel('{
  "kuu": 3,
  "aasta": 2021,
  "lepingid": 31867,
  "alg_kpv": "2021-03-12",
  "lopp_kpv": "2021-03-12",
          "toograf": 1
}' :: JSONB);

/*
SELECT palk.get_taabel('{"kuu":8,"aasta":2021,"lepingid":30951, "alg_kpv":"2021-08-01", "lopp_kpv":"2021-08-31"}' :: JSONB);


select palk.get_taabel('{"aasta":2021,"alg_kpv":"20210312","kuu":3,"lepingid":31867,"lopp_kpv":"20210312","toograf":0}'::jsonb) as tunnid,
       palk.get_holidays('{"aasta":2021,"alg_kpv":"20210312","kuu":3,"lepingid":31867,"lopp_kpv":"20210312","toograf":0}'::jsonb) as tahtpaevad
*/