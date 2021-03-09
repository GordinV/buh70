DROP FUNCTION IF EXISTS palk.get_work_hours(params JSONB);

CREATE FUNCTION palk.get_work_hours(params JSONB)
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_lepingid         INTEGER = params ->> 'lepingid';
    l_kpv              DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_tund             NUMERIC = params ->> 'tund';
    l_start_paev       INTEGER = coalesce((params ->> 'paev') :: INTEGER, 1);
    l_lopp_paev        INTEGER = coalesce((params ->> 'lopp') :: INTEGER, day(get_last_day(l_kpv)));
    l_toopaev          NUMERIC = params ->> 'toopaev';
    l_params           JSON;
    l_rekvid           INTEGER;
    l_pohikoht         INTEGER;
    l_tahtpaeva_tunnid INTEGER = 0;
    kas_tahtpaevad     BOOLEAN = coalesce((params ->> 'kas_tahtpaevad')::BOOLEAN, FALSE);
BEGIN
    IF kas_tahtpaevad IS NULL
    THEN
        kas_tahtpaevad = FALSE;
    END IF;


    IF l_tund IS NULL AND l_lepingid IS NOT NULL
    THEN
        -- parameter tund puudub, võttame taabelist

        SELECT t.tund INTO l_tund
        FROM palk.cur_toografik t
        WHERE lepingid = l_lepingid
          AND kuu = month(l_kpv)
          AND aasta = year(l_kpv);

    END IF;

    -- proovime leia kui palju töötunnid tööpäevas
    IF l_toopaev IS NULL AND l_lepingid IS NOT NULL
    THEN
        --otsime tööpäev
        SELECT toopaev,
               rekvid,
               pohikoht
               INTO l_toopaev, l_rekvid, l_pohikoht
        FROM palk.com_toolepingud t
        WHERE id = l_lepingid;
    ELSE
        SELECT rekvid,
               pohikoht
               INTO l_rekvid, l_pohikoht
        FROM palk.com_toolepingud t
        WHERE id = l_lepingid;

    END IF;

    IF coalesce(l_tund, 0) = 0
    THEN
        -- parameter või tööajagraafik puudub, arvestame
        SELECT row_to_json(row) INTO l_params
        FROM (SELECT month(l_kpv) AS kuu,
                     year(l_kpv)  AS aasta,
                     l_lepingid   AS lepingid,
                     l_rekvid     AS rekvid,
                     l_start_paev AS paev,
                     l_lopp_paev  AS lopp) row;

        l_tund = (SELECT palk.get_work_days(l_params :: JSON) * coalesce(l_toopaev, 8));

-- праздники
        IF (kas_tahtpaevad)
        THEN

            l_tahtpaeva_tunnid = l_pohikoht * (SELECT count(id)
                                               FROM cur_tahtpaevad l
                                               WHERE (l.rekvid = l_rekvid OR l.rekvid IS NULL)
                                                 AND kuu = month(l_kpv)
                                                 AND aasta = year(l_kpv)
                                                 AND l.luhipaev = 1) * 3;

            RAISE NOTICE 'kas_tahtpaevad %, l_tahtpaeva_tunnid %, l_pohikoht %',kas_tahtpaevad, l_tahtpaeva_tunnid, l_pohikoht;
        END IF;


    END IF;

    RETURN coalesce(l_tund, 0) - coalesce(l_tahtpaeva_tunnid, 0);

END;
$$;

/*
select palk.get_work_hours('{"lepingid":4, "kpv":"2018-04-18"}'::jsonb)  -- -> 0
select palk.get_work_hours(null::jsonb)  -- -> 0
select palk.get_work_hours('{"kpv":"2018-04-18","toopaev":4}'::jsonb)  -- -> 0
 */