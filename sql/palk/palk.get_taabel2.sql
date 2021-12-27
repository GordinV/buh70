DROP FUNCTION IF EXISTS palk.get_taabel2(JSONB);

CREATE FUNCTION palk.get_taabel2(IN params JSONB, OUT result NUMERIC, OUT tahtpaeva_tunnid NUMERIC)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_kuu              INTEGER = coalesce((params ->> 'kuu')::INTEGER, month(current_date));
    l_aasta            INTEGER = coalesce((params ->> 'aasta')::INTEGER, year(current_date));
    l_kpv_alg          DATE    = coalesce((params ->> 'alg_kpv')::DATE, make_date(l_aasta, l_kuu, 1));
    l_kpv_lopp         DATE    = coalesce((params ->> 'lopp_kpv')::DATE, gomonth(l_kpv_alg, 1) - 1);
    l_toograf          INTEGER = params ->> 'toograf';
    i                  INTEGER = 1;
    l_json             JSONB;
    l_tunnid           NUMERIC = 0;
    l_tahtpaeva_tunnid NUMERIC = 0;
    l_arv_lopp_kpv     DATE    = l_kpv_lopp;
BEGIN
    result = 0;
    tahtpaeva_tunnid = 0;

    FOR i IN month(l_kpv_alg)..month(l_kpv_lopp)
        LOOP
            l_arv_lopp_kpv = gomonth(make_date(yEAR(l_kpv_alg), i, 01), 1) - 1;
            IF l_arv_lopp_kpv > l_kpv_lopp
            THEN
                l_arv_lopp_kpv = l_kpv_lopp;
            END IF;

            l_json = JSONB_BUILD_OBJECT('kuu', i,
                                        'aasta', YEAR(l_kpv_lopp),
                                        'alg_paev', (CASE WHEN MONTH(l_kpv_alg) = i THEN DAY(l_kpv_alg) ELSE 1 END),
                                        'lopp_paev', day(l_arv_lopp_kpv),
                                        'lepingid', params ->> 'lepingid',
                                        'toograf', coalesce(l_toograf, 0)
                );

            SELECT coalesce(t.result, 0), coalesce(t.tahtpaeva_tunnid, 0)
            INTO l_tunnid, l_tahtpaeva_tunnid
            FROM palk.sp_calc_taabel2(l_json::JSONB) t;
            result = result + l_tunnid;
            tahtpaeva_tunnid = tahtpaeva_tunnid + l_tahtpaeva_tunnid;
        END LOOP;
    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION palk.get_taabel2( JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.get_taabel2( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_taabel2( JSONB ) TO dbpeakasutaja;

SELECT *
FROM palk.get_taabel2('{
  "kuu": 3,
  "aasta": 2021,
  "lepingid": 31867,
  "alg_kpv": "2021-03-12",
  "lopp_kpv": "2021-03-12",
  "toograf": 1
}' :: JSONB);

/*
SELECT result palk.get_taabel('{"kuu":8,"aasta":2021,"lepingid":30951, "alg_kpv":"2021-08-01", "lopp_kpv":"2021-08-31"}' :: JSONB);


select palk.get_taabel('{"aasta":2021,"alg_kpv":"20210312","kuu":3,"lepingid":31867,"lopp_kpv":"20210312","toograf":0}'::jsonb) as tunnid,
       palk.get_holidays('{"aasta":2021,"alg_kpv":"20210312","kuu":3,"lepingid":31867,"lopp_kpv":"20210312","toograf":0}'::jsonb) as tahtpaevad
*/