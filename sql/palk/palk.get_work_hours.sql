DROP FUNCTION IF EXISTS palk.get_work_hours(params JSONB);

CREATE FUNCTION palk.get_work_hours(params JSONB)
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS
$$
DECLARE
    -- Input parameters from JSONB
    l_lepingid                INTEGER = (params ->> 'lepingid')::INTEGER; -- Contract ID
    l_kpv                     DATE    = coalesce((params ->> 'kpv')::DATE, current_date); -- Date for calculation, defaults to current date
    l_hours_from_grafik       NUMERIC = (params ->> 'tund')::NUMERIC; -- Hours from work schedule (grafik)
    l_start_paev              INTEGER = coalesce((params ->> 'paev')::INTEGER, 1); -- Start day of the period, defaults to 1
    l_lopp_paev               INTEGER = coalesce((params ->> 'lopp')::INTEGER, day(get_last_day(l_kpv))); -- End day of the period, defaults to last day of month
    l_workday_hours           NUMERIC = (params ->> 'toopaev')::NUMERIC; -- Standard hours in a workday
    l_kas_tahtpaevad          BOOLEAN = coalesce((params ->> 'kas_tahtpaevad')::BOOLEAN, FALSE); -- Flag to include holidays in calculation

    -- Internal variables
    l_params                  JSON; -- JSON object for passing parameters to other functions
    l_rekvid                  INTEGER;
    l_is_main_job_flag        INTEGER; -- Flag indicating if it's a main job (1 for main, 0 otherwise)
    l_holiday_hours_reduction NUMERIC = 0; -- Hours to be reduced due to holidays
BEGIN
    -- If hours are not provided in parameters and a contract ID exists,
    -- try to retrieve hours from the work schedule (palk.cur_toografik).
    IF l_hours_from_grafik IS NULL AND l_lepingid IS NOT NULL
    THEN
        SELECT
            t.tund
        INTO l_hours_from_grafik
        FROM
            palk.cur_toografik t
        WHERE
              lepingid = l_lepingid
          AND kuu = month(l_kpv)
          AND aasta = year(l_kpv);
    END IF;

    -- Retrieve standard workday hours and main job flag from the contract.
    -- This block combines the previous two similar IF/ELSE blocks.
    IF l_lepingid IS NOT NULL THEN
        SELECT
            t.toopaev,
            t.rekvid,
            t.pohikoht
        INTO l_workday_hours, l_rekvid, l_is_main_job_flag
        FROM
            palk.com_toolepingud t
        WHERE
            id = l_lepingid;
    END IF;

    -- If total work hours are still 0 (or NULL, then coalesced to 0),
    -- calculate them based on work days and standard workday hours.
    IF coalesce(l_hours_from_grafik, 0) = 0
    THEN
        -- Prepare parameters for palk.get_work_days function.
        SELECT
            row_to_json(row)
        INTO l_params
        FROM
            (
                SELECT
                    month(l_kpv) AS kuu,
                    year(l_kpv)  AS aasta,
                    l_lepingid   AS lepingid,
                    l_rekvid     AS rekvid,
                    l_start_paev AS paev,
                    l_lopp_paev  AS lopp
            ) row;

        -- Calculate total work hours using palk.get_work_days and default workday hours (8 if not specified).
        l_hours_from_grafik = (
                                  SELECT palk.get_work_days(l_params :: JSON) * coalesce(l_workday_hours, 8)
                              );

        -- If l_kas_tahtpaevad flag is true, calculate reduction due to short holidays.
        IF l_kas_tahtpaevad
        THEN
            -- Calculate holiday hours reduction:
            -- l_is_main_job_flag (1 if main job, 0 otherwise) * count of short holidays * 3 hours reduction per short holiday.
            -- The '3' represents the standard hours reduced for a short holiday.
            l_holiday_hours_reduction = l_is_main_job_flag * (
                                                                 SELECT
                                                                     count(id)
                                                                 FROM
                                                                     cur_tahtpaevad l
                                                                 WHERE
                                                                     make_date(aasta, kuu, paev) >
                                                                     make_date(year(l_kpv), month(l_kpv), 1) -- From the first day of the month
                                                                   AND make_date(aasta, kuu, paev) <= l_kpv -- Up to and including the calculation date
                                                                   AND l.luhipaev = 1 -- Flag for short holiday
--                                                                   and (l.rekvid is null or l.rekvid = coalesce(l_rekvid, 63))
                                                             ) *
                                        3; -- Magic number: 3 hours reduction for a short holiday
        END IF;
    END IF;

    -- Return the total calculated work hours minus any holiday reductions.
    RETURN coalesce(l_hours_from_grafik, 0) - coalesce(l_holiday_hours_reduction, 0);

END;
$$;

/*
select palk.get_work_hours('{"lepingid":4, "kpv":"2018-04-18"}'::jsonb)  -- -> 0
select palk.get_work_hours(null::jsonb)  -- -> 0
select palk.get_work_hours('{"kpv":"2018-04-18","toopaev":4}'::jsonb)  -- -> 0
 */