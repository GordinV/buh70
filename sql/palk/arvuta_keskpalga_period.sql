DROP FUNCTION IF EXISTS palk.arvuta_keskpalga_period(JSONB);

CREATE FUNCTION palk.arvuta_keskpalga_period(IN params JSONB,
                                             OUT alg_kpv DATE,
                                             OUT lopp_kpv DATE)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_kpv_1   DATE = params ->> 'alg_kpv';
    l_kpv_2 date;
    l_kpv_alg DATE;
    l_vm_kpv  date;
BEGIN

    lopp_kpv = get_last_day((l_kpv_1 - interval '1 month')::date);
    l_kpv_alg = lopp_kpv - interval '5 month';
    alg_kpv = make_date(year(l_kpv_alg), month(l_kpv_alg), 1);

    l_vm_kpv = palk.arvuta_puhkuse_vm_paev((jsonb_build_object('alg_kpv', lopp_kpv)));

    if month(l_vm_kpv) < month(l_kpv_1) then
        -- если дата выплаты смещена на месяц, то период считаем на месяц раньше
        l_kpv_2 = get_last_day((l_kpv_1 - interval '1 month')::date);
        lopp_kpv = get_last_day((l_kpv_2 - interval '1 month')::date);
        l_kpv_alg = lopp_kpv - interval '5 month';
        alg_kpv = make_date(year(l_kpv_alg), month(l_kpv_alg), 1);

    end if;


    RETURN;

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION palk.arvuta_keskpalga_period( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_keskpalga_period( JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_keskpalga_period( JSONB ) TO dbvaatleja;


select *
from palk.arvuta_keskpalga_period('{
  "alg_kpv": "2025-08-01"
}')

/*
SELECT *
FROM palk.fnc_get_sunnipaev(1, '{
  "isikukood": "37303023721"
}');
*/