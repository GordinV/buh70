DROP FUNCTION IF EXISTS palk.calc_mvt( NUMERIC, NUMERIC);

CREATE OR REPLACE FUNCTION palk.calc_mvt(tulu NUMERIC, mvt NUMERIC)
  RETURNS NUMERIC AS
$BODY$

DECLARE
  l_MVT               NUMERIC(14, 4) = 0;
  l_max_lubatatud_MVT NUMERIC(14, 4) = 500;
  l_tulu_max_piir     NUMERIC(14, 4) = 1200;
  l_tulu_min_piir     NUMERIC(14, 4) = 900;
  l_max_MVT            NUMERIC(14, 4) = l_max_lubatatud_MVT - l_max_lubatatud_MVT / l_tulu_min_piir *
                                                              (tulu -
                                                               l_tulu_max_piir); --500 - 500 / 900 × 	(tulu - 1200)
  l_arvestatud_MVT     NUMERIC(14, 4) = l_max_MVT; -- расчетная льгота

BEGIN

  IF l_max_MVT > mvt
  THEN
    --vottame nii palju kui lubatatud
    l_arvestatud_MVT = mvt;
  END IF;

  IF l_max_MVT < mvt AND l_arvestatud_MVT < l_max_MVT
  THEN
    -- vottame max lubatatud MVT
    l_arvestatud_MVT = l_max_MVT;
  END IF;

  IF l_arvestatud_MVT < mvt
  THEN
    l_MVT = l_arvestatud_MVT;
  ELSE
    l_MVT = mvt;
  END IF;

  -- juhl kui «tulu – PM – TKI» < 500 EUR, siis kasutame teine arvestus ja võrdleme tulemus ja taotletud MVT

  IF l_MVT >= tulu
  THEN
    l_MVT = tulu;
  END IF;

  IF (l_MVT > mvt)
  THEN
    l_MVT = mvt;
  END IF;

  IF (l_MVT < 0)
  THEN
    l_MVT = 0;
  END IF;

  if l_MVT > l_max_lubatatud_MVT THEN
    l_MVT = l_max_lubatatud_MVT;
  END IF;
  RETURN f_round(l_MVT,0.01);
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.calc_mvt(NUMERIC, NUMERIC) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.calc_mvt(NUMERIC, NUMERIC) TO dbpeakasutaja;
/*
select  palk.calc_mvt(1200, 500)
select  palk.calc_mvt(1200, 0)
select  palk.calc_mvt(2000, 500)
select  palk.calc_mvt(200, 500)

*/