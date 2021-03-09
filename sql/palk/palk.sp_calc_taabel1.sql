DROP FUNCTION IF EXISTS sp_calc_taabel1(INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.sp_calc_taabel1(params JSONB);
DROP FUNCTION IF EXISTS palk.sp_calc_taabel1_(params JSONB);

CREATE FUNCTION palk.sp_calc_taabel1(params JSONB)
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_lepingid         INTEGER        = params ->> 'lepingid';
    l_kuu              INTEGER        = params ->> 'kuu';
    l_aasta            INTEGER        = params ->> 'aasta';
    l_toograf          INTEGER        = params ->> 'toograf';

    l_hours            NUMERIC(18, 4) = 0;
    v_tooleping        RECORD;
    l_puhkus           NUMERIC(16, 8) = 0;
    l_haigus           NUMERIC(16, 8) = 0;
    l_muud             NUMERIC(16, 8) = 0;
    l_tunnid           NUMERIC        = 0;
    l_toopaevad        INT            = 0;
    l_alg_paev         INTEGER        = 1;
    l_maxdays          INTEGER;
    l_lopp_paev        INTEGER;

    l_kpv              DATE;
    l_params           JSONB;
    l_tahtpaeva_tunnid NUMERIC(12, 4) = 0;

BEGIN
    l_maxdays = DAY(((make_date(l_aasta, l_kuu, 1) + INTERVAL '1 month') - INTERVAL '1 day')::DATE);
    l_kpv = make_date(l_aasta, l_kuu, l_maxdays);
    l_lopp_paev = l_maxdays;

    SELECT t.* INTO v_tooleping
    FROM palk.tooleping t
    WHERE t.id = l_lepingid;

    -- calculate start day
    IF month(v_Tooleping.algab) = l_kuu AND year(v_Tooleping.algab) = l_aasta
    THEN
        l_alg_paev = day(v_Tooleping.algab);
    END IF;

    -- calculate finish day
    IF v_Tooleping.lopp IS NOT NULL AND month(v_Tooleping.lopp) = l_kuu AND year(v_Tooleping.lopp) = l_aasta
    THEN
        l_lopp_paev = day(v_Tooleping.lopp);
    END IF;

    -- arv puhkuse paevad
    SELECT row_to_json(row) INTO l_params
    FROM (SELECT l_kuu      AS kuu,
                 l_aasta    AS aasta,
                 l_kpv      AS kpv,
                 l_lepingid AS lepingid,
                 'PUHKUS'   AS pohjus) row;

    l_puhkus = palk.get_puudumine(l_params :: JSONB);

    -- arv haiguse paevad
    SELECT row_to_json(row) INTO l_params
    FROM (SELECT l_kuu      AS kuu,
                 l_aasta    AS aasta,
                 l_kpv      AS kpv,
                 l_lepingid AS lepingid,
                 'HAIGUS'   AS pohjus) row;

    -- arv haiguse paevad
    l_haigus := palk.get_puudumine(l_params :: JSONB);

    -- arv muu paevad
    SELECT row_to_json(row) INTO l_params
    FROM (SELECT l_kuu      AS kuu,
                 l_aasta    AS aasta,
                 l_kpv      AS kpv,
                 l_lepingid AS lepingid,
                 'MUU'      AS pohjus) row;

    -- arv muud paevad
    l_muud := palk.get_puudumine(l_params :: JSONB);

    -- tunnid
    l_tunnid = (l_muud - floor(l_muud)) * 10 ^ (position('.' IN l_muud :: TEXT) - 1);

    l_muud = floor(l_muud);

    IF l_tunnid > 0
    THEN
        -- vottame tunnid
        l_muud = 0;
    END IF;


    -- check work table
    SELECT t.tund INTO l_hours
    FROM palk.Toograf t
    WHERE t.lepingid = l_lepingid
      AND status <> 'deleted'
      AND t.kuu = l_kuu
      AND t.aasta = l_aasta;

-- есть раб. график, считаем табель
    IF coalesce(l_toograf, 0) = 0 AND coalesce(l_hours, 0) > 0
    THEN
        -- calculate hours
        l_hours = (l_hours - (coalesce(l_puhkus, 0) + coalesce(l_haigus, 0) + l_muud) * v_Tooleping.toopaev -
                   l_tunnid);

    ELSE
        -- töögraafik
        -- график не установлен, считаем по календарным дням
        SELECT row_to_json(row) INTO l_params
        FROM (SELECT l_kuu       AS kuu,
                     l_aasta     AS aasta,
                     l_kpv       AS kpv,
                     NULL        AS lepingid,
                     l_alg_paev  AS paev,
                     l_lopp_paev AS lopp) row;

        l_tahtpaeva_tunnid = v_tooleping.pohikoht * (SELECT count(id)
                                                     FROM cur_tahtpaevad l
                                                     WHERE (l.rekvid = v_Tooleping.rekvid OR l.rekvid IS NULL)
                                                       AND kuu = l_kuu
                                                       AND l.luhipaev = 1) * 3;

        l_toopaevad = (SELECT palk.get_work_days(l_params::JSON));

        l_hours = l_toopaevad * v_Tooleping.toopaev - l_tahtpaeva_tunnid;

        IF l_hours < 0
        THEN
            l_hours = 0;
        END IF;

        -- если не задан тип расчета для графика, то считаем табель
        IF coalesce(l_toograf, 0) = 0
        THEN
            l_hours = (l_toopaevad - (coalesce(l_puhkus, 0) + coalesce(l_haigus, 0) + l_muud)) * v_Tooleping.toopaev -
                      l_tunnid;

            -- tähtpäeva parandus (lühipäev)
            l_tahtpaeva_tunnid = (SELECT count(id)
                                  FROM cur_tahtpaevad l
                                  WHERE (l.rekvid = v_Tooleping.rekvid OR l.rekvid IS NULL)
                                    AND kuu = l_kuu
                                    AND aasta = year(l_kpv)
                                    AND l.luhipaev = 1) * 3;

            l_hours := l_hours - l_tahtpaeva_tunnid;

        END IF;


    END IF;


    RETURN coalesce(l_hours, 0);
END;
$$;



GRANT EXECUTE ON FUNCTION palk.sp_calc_taabel1(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_calc_taabel1(JSONB) TO dbpeakasutaja;


/*
SELECT palk.sp_calc_taabel1('{
  "aasta": 2021,
  "kuu": 2,
  "lepingid": 28609,
  "toograf": 1
}'::JSONB);
-- -> 145 ?
-- lep 35222, 28609, 20026 (GZ)

select palk.sp_calc_taabel1(null::JSONB); -- -> 0


select * from palk.tooleping where parentid in (select id from libs.asutus where regkood in ('48509243716'))
*/