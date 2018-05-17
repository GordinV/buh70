DROP FUNCTION IF EXISTS palk.sp_update_palk_jaak( DATE, INTEGER );

CREATE OR REPLACE FUNCTION palk.sp_update_palk_jaak(l_kpv DATE, l_lepingid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  v_palk_jaak     RECORD;
  l_palk_jaak_id  INTEGER;
  l_kuu           INTEGER = month(l_kpv);
  l_aasta         INTEGER = year(l_kpv);

  l_jaak          NUMERIC(12, 4) = 0;
  l_eelmine_jaak  NUMERIC(12, 4) = 0;
  l_eelmine_kuu   INTEGER = CASE WHEN (l_kuu - 1) < 1
    THEN 12
                            ELSE l_kuu - 1 END;
  l_eelmine_aasta INTEGER = CASE WHEN l_eelmine_kuu = 12
    THEN l_aasta - 1
                            ELSE l_aasta END;
BEGIN
  -- суммируем опреации за текущий месяц
  SELECT
    sum(po.summa)
      FILTER (WHERE po.palk_liik = 'ARVESTUSED') AS arvestatud,
    sum(coalesce(po.tulubaas, 0))
      FILTER (WHERE po.palk_liik = 'ARVESTUSED') AS mvt,
    sum(coalesce(po.summa, 0))
      FILTER (WHERE po.palk_liik = 'ARVESTUSED' AND po.tululiik =
                                                     '22') AS tulud_pm,
  sum( COALESCE (po.summa, 0))
  FILTER ( WHERE po.palk_liik = 'KINNIPIDAMISED') AS kinni,
  sum( COALESCE (po.summa, 0))
  FILTER ( WHERE po.palk_liik = 'MUUD') AS muud,
  sum( COALESCE (po.summa, 0))
  FILTER ( WHERE po.palk_liik = 'TULUMAKS') AS tm,
  sum( COALESCE (po.summa, 0))
  FILTER ( WHERE po.palk_liik = 'SOTSMAKS') AS sm,
  sum( COALESCE (po.summa, 0))
  FILTER ( WHERE po.palk_liik = 'TASU') AS tasu,
  sum( COALESCE (po.summa, 0))
  FILTER ( WHERE po.palk_liik = 'TÖÖTUSKINDLUSTUSMAKS' AND
  po.is_asutusest) AS tka,
  sum( COALESCE (po.summa, 0))
  FILTER ( WHERE po.palk_liik =  'TÖÖTUSKINDLUSTUSMAKS' AND
  NOT po.is_asutusest) AS tki,
  sum( COALESCE (po.summa, 0))
  FILTER ( WHERE po.palk_liik = 'PENSIONIMAKS') AS pm

  INTO v_palk_jaak
  FROM palk.cur_palkoper po
  WHERE MONTH (po.kpv) = l_kuu
  AND YEAR (kpv) = l_aasta
  AND po.lepingId = l_lepingid;

  -- поправка в сальдо за счет 3 пенсионной ступени

  IF coalesce(v_palk_jaak.tulud_pm, 0) > 0
  THEN
    v_palk_jaak.arvestatud = v_palk_jaak.arvestatud - v_palk_jaak.tulud_pm;
  END IF;

  -- ищем запись текущего периода

  SELECT id
  INTO l_palk_jaak_id
  FROM palk.palk_jaak pj
  WHERE lepingid = l_lepingid
        AND kuu = l_kuu
        AND aasta = l_aasta;

  -- calc saldo
  -- 1. prev. saldo

  SELECT pj.jaak
  INTO l_eelmine_jaak
  FROM palk.palk_jaak pj
  WHERE pj.lepingId = l_lepingid
        AND pj.kuu = l_eelmine_kuu
        AND pj.aasta = l_eelmine_aasta;

  -- расчет сальдо
  l_jaak = coalesce(l_eelmine_jaak, 0) + coalesce(v_palk_jaak.arvestatud, 0) - coalesce(v_palk_jaak.kinni, 0) -
           coalesce(v_palk_jaak.tki, 0) - coalesce(v_palk_jaak.pm, 0) -
           coalesce(v_palk_jaak.tasu, 0) - coalesce(v_palk_jaak.tm, 0);

  IF l_palk_jaak_id IS NULL
  THEN
    INSERT INTO palk.palk_jaak (lepingId, kuu, aasta, arvestatud, kinni, tulumaks, sotsmaks, tka, tki, pm, g31, jaak)
    VALUES (l_lepingid, l_kuu, l_aasta, coalesce(v_palk_jaak.arvestatud, 0),
                        (coalesce(v_palk_jaak.kinni, 0) + coalesce(v_palk_jaak.tki, 0) + coalesce(v_palk_jaak.pm, 0) +
                         coalesce(v_palk_jaak.tasu, 0)),
                        coalesce(v_palk_jaak.tm, 0), coalesce(v_palk_jaak.sm, 0), coalesce(v_palk_jaak.tka, 0),
                        coalesce(v_palk_jaak.tki, 0), coalesce(v_palk_jaak.pm, 0),
                        coalesce(v_palk_jaak.mvt, 0), l_jaak);

  ELSE
    UPDATE palk.palk_jaak
    SET
      arvestatud = coalesce(v_palk_jaak.arvestatud,0),
      kinni      = (coalesce(v_palk_jaak.kinni, 0) + coalesce(v_palk_jaak.tki, 0) + coalesce(v_palk_jaak.pm, 0) +
                    coalesce(v_palk_jaak.tasu, 0)),
      tulumaks   = coalesce(v_palk_jaak.tm, 0),
      sotsmaks   = coalesce(v_palk_jaak.sm, 0),
      tka        = coalesce(v_palk_jaak.tka, 0),
      tki        = coalesce(v_palk_jaak.tki, 0),
      pm         = coalesce(v_palk_jaak.pm, 0),
      g31        = coalesce(v_palk_jaak.mvt, 0),
      jaak       = l_jaak
    WHERE id = l_palk_jaak_id;
  END IF;

  RETURN 1;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;


END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.sp_update_palk_jaak(DATE, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_update_palk_jaak(DATE, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_update_palk_jaak(DATE, INTEGER) TO taabel;


SELECT palk.sp_update_palk_jaak(DATE(), 4);