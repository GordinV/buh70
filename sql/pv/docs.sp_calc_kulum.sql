DROP FUNCTION IF EXISTS docs.sp_calc_kulum(INTEGER);
DROP FUNCTION IF EXISTS docs.sp_calc_kulum(INTEGER, DATE);

CREATE FUNCTION docs.sp_calc_kulum(IN tnId INTEGER, IN l_kpv DATE default current_date, OUT error_code INTEGER,
                                   OUT result INTEGER,
                                   OUT error_message TEXT,
                                   OUT selgitus TEXT,
                                   OUT summa NUMERIC(14, 2))
  RETURNS RECORD AS
$BODY$
DECLARE
  v_pv_kaart        RECORD;
BEGIN
  -- select meta data

  SELECT
    pv_jaak.jaak                                                                            AS hind,
    pv_jaak.kulum_maar                                                                      AS kulum,
    pv_jaak.jaak                                                                            AS jaak,
    pv_jaak.kulum                                                                           AS kulum_kokku,
         pv_jaak.kuu_kulum
    INTO v_pv_kaart
  FROM libs.library l,
       (SELECT * FROM libs.get_pv_kaart_jaak(tnId, l_kpv)) pv_jaak
  WHERE l.id = tnId;

  selgitus = 'Hind: ' || v_pv_kaart.hind :: TEXT;


  Selgitus = Selgitus || ' kulum kokku:' || v_pv_kaart.kulum_kokku :: TEXT;

  -- calculations
  IF v_pv_kaart.Jaak > 0
  THEN
    -- month summa
    summa = v_pv_kaart.kuu_kulum;
    Selgitus = Selgitus || 'arvestatud summa:' || v_pv_kaart.kuu_kulum :: TEXT;

    IF summa > (v_pv_kaart.Jaak)
    THEN

      summa = v_pv_kaart.Jaak;
      Selgitus = Selgitus || ' parandus, sest jaak oli vaiksem:' + summa :: TEXT;

    END IF;
  ELSE
    Selgitus = Selgitus || 'Jaak = 0, siis summa = 0';
    summa = 0;
  END IF;

  result = 1;
  RETURN;

END;
$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;


GRANT EXECUTE ON FUNCTION docs.sp_calc_kulum(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_calc_kulum(INTEGER, date) TO dbpeakasutaja;


COMMENT ON FUNCTION docs.sp_calc_kulum(INTEGER, date) IS 'расчет суммы износа';

/*
SELECT result, selgitus, summa from docs.sp_calc_kulum(447, current_date)
SELECT docs.sp_calc_kulum(451);

*/