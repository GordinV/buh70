DROP FUNCTION IF EXISTS palk.fnc_get_periodis_from_date_range(JSONB);

CREATE FUNCTION palk.fnc_get_periodis_from_date_range(IN params JSONB)
    RETURNS TABLE
            (
                period_start            date,
                period_finish           date,
                work_days_in_month      integer,
                work_days_in_period     integer,
                calendar_days_in_month  integer,
                calendar_days_in_period integer
            )
as
$BODY$

DECLARE
    l_alg_kpv            date    = params ->> 'alg_kpv';
    l_lopp_kpv           date    = params ->> 'lopp_kpv';
    l_periods            integer = (
                                       select
                                           (year(l_lopp_kpv) - year(l_alg_kpv)) * 12 +
                                           (month(l_lopp_kpv) - month(l_alg_kpv) + 1)
                                   );
    l_alg_arv_kpv        date    = l_alg_kpv;
    l_lopp_arv_kpv       date    = l_lopp_kpv;
    tulemused            jsonb   = '[]';
BEGIN

    if l_periods is null then
        return query
            select
                null::date period_start,
                null::date period_finish,
                0 as       work_days_in_month,
                0 as       work_days_in_period,
                0 as       calendar_days_in_month,
                0 as       calendar_days_in_period;
    else

        FOR i IN 1..l_periods
            loop
                l_lopp_arv_kpv = get_last_day(l_alg_arv_kpv);

                if i > 1 then
                    l_alg_arv_kpv = make_date(year(l_alg_arv_kpv), month(l_alg_arv_kpv), 1);
                end if;

                if l_lopp_arv_kpv > l_lopp_kpv then
                    l_lopp_arv_kpv = l_lopp_kpv;
                end if;

                tulemused = tulemused || jsonb_build_object('alg_kpv', l_alg_arv_kpv,
                                                            'lopp_kpv', l_lopp_arv_kpv,
                                                            'work_days_in_period',
                                                            (palk.get_work_days(json_build_object('kuu',
                                                                                                  month(l_alg_arv_kpv),
                                                                                                  'aasta',
                                                                                                  year(l_alg_arv_kpv),
                                                                                                  'paev',
                                                                                                  day(l_alg_arv_kpv),
                                                                                                  'lopp',
                                                                                                  day(l_lopp_arv_kpv)
                                                                                ))),
                                                            'work_days_in_month',
                                                            (palk.get_work_days(json_build_object('kuu',
                                                                                                  month(l_alg_arv_kpv),
                                                                                                  'aasta',
                                                                                                  year(l_alg_arv_kpv)
                                                                                ))),
                                                            'calendar_days_in_month',
                                                            (day(get_last_day(l_alg_arv_kpv))),
                                                            'calendar_days_in_period',
                                                            (l_lopp_arv_kpv - l_alg_arv_kpv + 1)
                                         );
                l_alg_arv_kpv = gomonth(l_alg_arv_kpv, 1);
            end loop;

        return query
            select
                qry.period_start,
                qry.period_finish,
                qry.work_days_in_month,
                qry.work_days_in_period,
                qry.calendar_days_in_month,
                qry.calendar_days_in_period

            from
                (
                    select
                        (p ->> 'alg_kpv')::date                    as period_start,
                        (p ->> 'lopp_kpv')::date                   as period_finish,
                        (p ->> 'work_days_in_period')::integer     as work_days_in_period,
                        (p ->> 'work_days_in_month')::integer      as work_days_in_month,
                        (p ->> 'calendar_days_in_month')::integer  as calendar_days_in_month,
                        (p ->> 'calendar_days_in_period')::integer as calendar_days_in_period

                    from
                        jsonb_array_elements(tulemused) p
                ) qry;
    end if;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION palk.fnc_get_periodis_from_date_range( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.fnc_get_periodis_from_date_range( JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.fnc_get_periodis_from_date_range( JSONB ) TO dbvaatleja;

-- lepingid, kuu, aasta, alg_kpv , lopp_kpv, toograf

/*
select *
from
    palk.fnc_get_periodis_from_date_range('{
      "alg_kpv": "2025-06-09",
      "lopp_kpv": "2025-07-08"
    }')
*/