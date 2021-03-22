DROP FUNCTION IF EXISTS palk.get_holidays(JSONB);

CREATE FUNCTION palk.get_holidays(IN params JSONB, OUT result INTEGER)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_kpv_alg  DATE = params ->> 'alg_kpv';
    l_kpv_lopp DATE = params ->> 'lopp_kpv';
BEGIN

    result = coalesce((SELECT count(id)
                       FROM cur_tahtpaevad t
                       WHERE make_date(t.aasta, t.kuu, t.paev) >= l_kpv_alg
                         AND make_date(t.aasta, t.kuu, t.paev) <= l_kpv_lopp
                         AND (rekvid IS NULL OR rekvid IN (SELECT rekvid
                                                           FROM palk.tooleping
                                                           WHERE id = (params ->> 'lepingid')::INTEGER))), 0);
    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION palk.get_holidays( JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.get_holidays( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_holidays( JSONB ) TO dbpeakasutaja;


/*
SELECT palk.get_holidays('{"kuu":8,"aasta":2021,"lepingid":30951, "alg_kpv":"2021-08-01", "lopp_kpv":"2021-09-01"}' :: JSONB);


*/