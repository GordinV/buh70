DROP FUNCTION IF EXISTS palk.arvuta_puudumise_paevad(JSONB);

CREATE FUNCTION palk.arvuta_puudumise_paevad(IN params JSONB,
                                             OUT puudumise_paevad INTEGER,
                                             OUT arvestatud_paevad INTEGER,
                                             OUT puudumise_tunnid numeric)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_liik           text    = params ->> 'liik';
    l_tyyp           integer = params ->> 'tyyp';
    l_puudumised     integer = 0;
    l_miinus         integer = 0;
    l_max            integer = 0;
    l_kpv_1          date    = params ->> 'alg_kpv';
    l_kpv_2          date    = params ->> 'lopp_kpv';
    v_puudumine_liik record;
BEGIN

    select
        eesti as nimetus,
        vs_kooded
    into v_puudumine_liik
    from
        palk.com_puudumiste_tyyp
    where
          liik::text = l_liik
      and id = l_tyyp;

    -- При расчете компенсации по болезни счетвертый по восьмой день (у нас дополнительно второй и третий день) (Закон о гигиене и безопасности труда статья 12 (2) часть 1)

    if l_liik = 'HAIGUS' AND v_puudumine_liik.vs_kooded <@ array ['AH', 'H', 'PH', 'HP'] THEN
        l_miinus = 1;
        l_max = 7; -- При расчете компенсации по болезни с четвертый по восьмой день (у нас дополнительно второй и третий день)
    end if;

    if l_liik <> 'HAIGUS' then
        l_puudumised = coalesce(palk.get_holidays(params::JSONB), 0);
    end if;

    puudumise_tunnid = (
                           select
                               result
                           from
                               palk.get_taabel2(params::JSONB) t
                       );
    puudumise_paevad = l_kpv_2 - l_kpv_1 - l_puudumised + 1;
    arvestatud_paevad = puudumise_paevad - l_miinus;

    -- проверка на предельное кол-во дней
    if l_max > 0 and arvestatud_paevad > l_max then
        arvestatud_paevad = l_max;
    end if;
    RETURN;

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION palk.arvuta_puudumise_paevad( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_puudumise_paevad( JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_puudumise_paevad( JSONB ) TO dbvaatleja;

-- lepingid, kuu, aasta, alg_kpv , lopp_kpv, toograf

select *
from
    palk.arvuta_puudumise_paevad('{
      "alg_kpv": "2025-03-20",
      "lopp_kpv": "2025-03-31",
      "lepingid": 28310,
      "kuu": 4,
      "aasta": 2025,
      "toograf": 1,
      "liik": "HAIGUS",
      "tyyp": 1
    }')

/*
SELECT *
FROM palk.fnc_get_sunnipaev(1, '{
  "isikukood": "37303023721"
}');
*/