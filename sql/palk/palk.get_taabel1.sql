DROP FUNCTION IF EXISTS palk.get_taabel(JSONB);

CREATE FUNCTION palk.get_taabel(IN params JSONB, OUT result INTEGER)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_kuu      INTEGER = coalesce((params ->> 'kuu')::INTEGER, month(current_date));
    l_aasta    INTEGER = coalesce((params ->> 'aasta')::INTEGER, year(current_date));
    l_kpv_alg  DATE    = coalesce((params ->> 'alg_kpv')::DATE, make_date(l_aasta, l_kuu, 1));
    l_kpv_lopp DATE    = coalesce((params ->> 'lopp_kpv')::DATE, gomonth(l_kpv_alg, 1) - 1);
    l_toograf  INTEGER = params ->> 'toograf';
    i          INTEGER = 1;
    l_json     JSONB;
    l_tunnid   INTEGER = 0;
BEGIN
    result = 0;

    FOR i IN month(l_kpv_alg)..month(l_kpv_lopp)
        LOOP
            l_json = JSONB_BUILD_OBJECT('kuu', i,
                                        'aasta', YEAR(l_kpv_lopp),
                                        'alg_paev', (CASE WHEN MONTH(l_kpv_alg) = i THEN DAY(l_kpv_alg) ELSE 1 END),
                                        'lopp_paev', (CASE WHEN month(l_kpv_lopp) = i THEN day(l_kpv_lopp) ELSE 31 END),
                                        'lepingid', params ->> 'lepingid',
                                        'toograf', coalesce(l_toograf, 0)
                );

            l_tunnid = palk.sp_calc_taabel1(l_json::JSONB);
            result = result + l_tunnid;
        END LOOP;
    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION palk.get_taabel( JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.get_taabel( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_taabel( JSONB ) TO dbpeakasutaja;

SELECT palk.get_taabel('{
  "kuu": 8,
  "aasta": 2021,
  "lepingid": 30951,
  "alg_kpv": "2021-08-01",
  "lopp_kpv": "2021-08-31"
}' :: JSONB);

/*
SELECT palk.get_taabel('{"kuu":8,"aasta":2021,"lepingid":30951, "alg_kpv":"2021-08-01", "lopp_kpv":"2021-08-31"}' :: JSONB);


*/