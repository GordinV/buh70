DROP FUNCTION IF EXISTS palk.fnc_calc_mvt( JSONB );

CREATE OR REPLACE FUNCTION palk.fnc_calc_mvt(params JSONB)
  RETURNS NUMERIC AS
$BODY$

-- tnMVT_kokku personal taotluse summa
DECLARE
  l_alus_summa          NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, 0); -- tulu
  l_mvt_kokku           NUMERIC = coalesce((params ->> 'mvt_kokku') :: NUMERIC, 0); -- taotluse summa
  l_kokku_kasutatud_mvt NUMERIC = coalesce((params ->> 'kokku_kasutatud_mvt') :: NUMERIC,
                                           0); -- kokku kasutatud mvt kuues
  l_tki                 NUMERIC = coalesce((params ->> 'tki') :: NUMERIC, 0);
  l_pm                  NUMERIC = coalesce((params ->> 'pm') :: NUMERIC, 0);

  l_isiku_MVT           NUMERIC = palk.calc_mvt(l_alus_summa, l_mvt_kokku);
  l_MVT                 NUMERIC = l_isiku_MVT;

BEGIN
  IF l_isiku_MVT > l_alus_summa
  THEN
    -- if tulu summa more then MVT
    l_MVT = l_alus_summa;
  END IF;

  IF l_kokku_kasutatud_mvt > 0
  THEN
    l_MVT = l_isiku_MVT - l_kokku_kasutatud_mvt;
  END IF;


  IF l_MVT > (l_alus_summa - l_tki - l_pm)
  THEN
    l_MVT = l_alus_summa - l_tki - l_pm;
  END IF;


  IF l_alus_summa < 0
  THEN
    -- if summa < 0 then returning 0
    l_MVT = 0;
  END IF;

  IF l_isiku_MVT > l_kokku_kasutatud_mvt
  THEN
    -- umardamine, miinus summa
    l_MVT = l_isiku_MVT - l_kokku_kasutatud_mvt;
  END IF;

  l_MVT = round(l_MVT, 2);
  RETURN l_MVT;


END;

$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.fnc_calc_mvt(JSONB) TO dbkasutaja;

/*
select palk.fnc_calc_mvt('{"summa":1000}'::jsonb)
select palk.fnc_calc_mvt('{"summa":1000, "mvt_kokku":500}'::jsonb)
select palk.fnc_calc_mvt('{"summa":1000, "mvt_kokku":500, "kokku_kasutatud_mvt":300}'::jsonb)
select palk.fnc_calc_mvt('{"summa":200, "mvt_kokku":500, "tki":3.2, "pm":4}'::jsonb)

*/