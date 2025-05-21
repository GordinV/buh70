DROP FUNCTION IF EXISTS palk.arvuta_keskpalga_period(JSONB);

CREATE FUNCTION palk.arvuta_keskpalga_period(IN params JSONB,
                                             OUT alg_kpv DATE,
                                             OUT lopp_kpv DATE)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_kpv_1   DATE = params ->> 'alg_kpv';
    l_kpv_alg DATE;
BEGIN
    lopp_kpv = get_last_day((l_kpv_1 - interval '1 month')::date);
    l_kpv_alg = lopp_kpv - interval '6 month';
    alg_kpv = make_date(year(l_kpv_alg), month(l_kpv_alg), 1);
    RETURN;

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION palk.arvuta_keskpalga_period( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_keskpalga_period( JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_keskpalga_period( JSONB ) TO dbvaatleja;


select * from palk.arvuta_keskpalga_period('{
  "alg_kpv": "20250221",
  "lopp_kpv": "20250228",
  "isik_id": 30984,
  "tyyp": "PUHKUS"
}')

/*
SELECT *
FROM palk.fnc_get_sunnipaev(1, '{
  "isikukood": "37303023721"
}');
*/