DROP FUNCTION IF EXISTS palk.fnc_calc_tm( NUMERIC, NUMERIC, NUMERIC, NUMERIC, CHARACTER VARYING );
DROP FUNCTION IF EXISTS palk.fnc_calc_tm( NUMERIC, NUMERIC, NUMERIC, NUMERIC, TEXT );

CREATE OR REPLACE FUNCTION palk.fnc_calc_tm(l_summa    NUMERIC, l_mvt NUMERIC, l_tki NUMERIC, l_pm NUMERIC,
                                            l_tululiik TEXT, l_tm_maar numeric DEFAULT 20)
  RETURNS NUMERIC AS
$BODY$


DECLARE
  l_TM      NUMERIC = 0;
  l_tm_maar NUMERIC(14, 2) = coalesce((SELECT tun1
                                       FROM libs.library
                                       WHERE kood = l_tululiik :: VARCHAR(20) AND library = 'MAKSUKOOD' limit 1), l_tm_maar) :: NUMERIC
                             / 100;
BEGIN


  l_TM = round((coalesce(l_summa, 0) - coalesce(l_mvt, 0) - coalesce(l_tki, 0) - coalesce(l_pm, 0)) * l_tm_maar, 2);


  IF l_summa > 0 AND l_TM < 0
  THEN
    -- check for minus
    l_TM = 0;
  END IF;

  RETURN l_TM;


END;

$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.fnc_calc_tm(NUMERIC, NUMERIC, NUMERIC, NUMERIC, TEXT, NUMERIC) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.fnc_calc_tm(NUMERIC, NUMERIC, NUMERIC, NUMERIC, TEXT, NUMERIC) TO dbpeakasutaja;

/*
select palk.fnc_calc_tm(1000, 500, 0, 0, '10');
select palk.fnc_calc_tm(1000, 0, 0, 0, '10');
select palk.fnc_calc_tm(1000, 500, 16, 20, '10');
select palk.fnc_calc_tm(200, 500, 3.2, 4, '10');
select palk.fnc_calc_tm(200, 500, 3.2, 4, null, 20);


SELECT tun1
                                       FROM libs.library
                                       WHERE kood = '10' :: VARCHAR(20) AND library = 'MAKSUKOOD'
*/