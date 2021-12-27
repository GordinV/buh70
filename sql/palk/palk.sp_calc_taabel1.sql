DROP FUNCTION IF EXISTS sp_calc_taabel1(INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.sp_calc_taabel1(params JSONB);

CREATE FUNCTION palk.sp_calc_taabel1(params JSONB)
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_hours            NUMERIC(18, 4) = 0;
    l_lopp_paev        INTEGER        = params ->> 'lopp_paev';
BEGIN
    l_hours = (SELECT t.result FROM palk.sp_calc_taabel2(params::JSONB) t);
    RETURN coalesce(l_hours, 0);
END;
$$;



GRANT EXECUTE ON FUNCTION palk.sp_calc_taabel1(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_calc_taabel1(JSONB) TO dbpeakasutaja;


/*
SELECT palk.sp_calc_taabel1('{"aasta":2021,"kuu":3,"lepingid":26416}'::JSONB);
-- -> 145 ?
-- lep 35222, 28609, 20026 (GZ)

select palk.sp_calc_taabel1(null::JSONB); -- -> 0


select * from palk.tooleping where parentid in (select id from libs.asutus where regkood in ('48509243716'))
*/