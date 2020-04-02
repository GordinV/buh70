DROP FUNCTION IF EXISTS check_puhkus(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.check_puhkus(JSONB);
DROP FUNCTION IF EXISTS palk.check_puudumine(JSONB);
DROP FUNCTION IF EXISTS palk.get_puudumine(params JSONB);

CREATE FUNCTION palk.get_puudumine(params JSONB)
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_lepingid        INTEGER = params ->> 'lepingid';
    l_kuu             INTEGER = params ->> 'kuu';
    l_aasta           INTEGER = params ->> 'aasta';
    l_pohjus          TEXT    = (params ->> 'pohjus');

    l_start_paev      INTEGER;
    l_lopp_paev       INTEGER;

    l_result          NUMERIC = 0;
    qryPuhkused       RECORD;
    l_puhkuse_tunnid  NUMERIC = 0;
    l_paevad          NUMERIC = 0;
    params            JSONB;
    l_miinus_holidays INTEGER = 0; -- days with - holidays
    l_miinus_weekends INTEGER = 0; -- days with - weekend
BEGIN

    --selecting data
    FOR qryPuhkused IN
        SELECT p.*,
               toopaev,
               (SELECT palk.get_work_days((SELECT row_to_json(row)
                                           FROM (SELECT day(p.kpv1) AS paev,
                                                        day(p.kpv2) AS lopp) row) :: JSON)) AS too_kpv
        FROM palk.cur_puudumine p
                 INNER JOIN palk.tooleping t ON t.id = p.lepingid
        WHERE p.lepingid = l_lepingid
          AND (month(p.kpv1) = l_kuu AND year(p.kpv1) = l_aasta
            OR (month(kpv2) = l_kuu AND year(kpv2) = l_aasta))
          AND (l_pohjus IS NULL OR p.pohjus = l_pohjus)
        LOOP
            -- оюбнулим переменные
            l_paevad = 0;


            -- arvestame alg. päev

            IF month(qryPuhkused.kpv1) = l_kuu AND year(qryPuhkused.kpv1) = l_aasta
            THEN
                l_start_paev = day(qryPuhkused.kpv1);
            ELSE
                l_start_paev = 1;
            END IF;

            --arvestame lõpp päev
            IF month(qryPuhkused.kpv2) = l_kuu AND year(qryPuhkused.kpv2) = l_aasta
            THEN
                l_lopp_paev = day(qryPuhkused.kpv2);
            ELSE
                l_lopp_paev = day(get_last_day(date(l_aasta, l_kuu, 1)));
            END IF;

            -- arvestame tunnid

            IF (qryPuhkused.pohjus = 'PUHKUS' AND qryPuhkused.tyyp = 4)
            THEN
                -- except
                RAISE NOTICE 'except';
            ELSE
                l_result = l_result + CASE
                                          WHEN month(qryPuhkused.kpv1) = month(qryPuhkused.kpv2)
                                              THEN qryPuhkused.kpv2 - qryPuhkused.kpv1 + 1
                                          WHEN month(qryPuhkused.kpv1) <> month(qryPuhkused.kpv2) AND
                                               month(qryPuhkused.kpv2) = l_kuu
                                              THEN qryPuhkused.kpv2 - make_date(l_aasta, l_kuu, 1)
                                          ELSE get_last_day(qryPuhkused.kpv1) - qryPuhkused.kpv1 + 1 END;

            END IF;

            -- arvestame holidays in periood
            l_miinus_holidays = l_miinus_holidays + (SELECT count(*)
                                                     FROM cur_calender(make_date(l_aasta, l_kuu, l_start_paev),
                                                                       make_date(l_aasta, l_kuu, l_lopp_paev),
                                                                       qryPuhkused.rekvid)
                                                     WHERE is_tahtpaev);

            -- arvestame puhkepaevad perioodis
            l_miinus_weekends = l_miinus_weekends + (SELECT count(*)
                                                     FROM cur_calender(make_date(l_aasta, l_kuu, l_start_paev),
                                                                       make_date(l_aasta, l_kuu, l_lopp_paev),
                                                                       qryPuhkused.rekvid)
                                                     WHERE NOT is_toopaev);

        END LOOP;


    -- miinus
    l_result = l_result - (l_miinus_holidays + l_miinus_weekends);
    RETURN l_result;

END;
$$;



GRANT EXECUTE ON FUNCTION palk.get_puudumine(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_puudumine(JSONB) TO dbpeakasutaja;


/*
select palk.get_puudumine('{"lepingid":34408, "kuu":2, "aasta":2020, "pohjus":"HAIGUS"}'::jsonb)  -- -> 0

select palk.get_puudumine(null::jsonb)  -- -> 0
select palk.get_puudumine('{"lepingid":4}'::jsonb)  -- -> 0
select palk.get_puudumine('{"lepingid":4, "kuu":4, "aasta":2018}'::jsonb)  -- -> 0
select palk.get_puudumine('{"lepingid":4, "kuu":4, "aasta":2018, "pohjus":"PUHKUS"}'::jsonb)  -- -> 0
 */