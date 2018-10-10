DROP FUNCTION IF EXISTS docs.sp_calc_kulum( INTEGER );

CREATE FUNCTION docs.sp_calc_kulum(IN  tnId          INTEGER, OUT error_code INTEGER,
                                   OUT result        INTEGER,
                                   OUT error_message TEXT,
                                   OUT selgitus      TEXT,
                                   OUT summa         NUMERIC(14, 2))
  RETURNS RECORD AS
$BODY$
DECLARE
  v_pv_kaart        RECORD;
  v_pv_oper         RECORD;
  lnSummaKulum      NUMERIC(18, 2);
  umberHindamiseKpv DATE;
  a_pv_opers        TEXT [] = enum_range(NULL :: PV_OPERATSIOONID);

BEGIN
  -- select meta data

  SELECT
    coalesce((l.properties :: JSONB ->> 'soetkpv') :: DATE, now() :: DATE)                  AS soetkpv,
    coalesce((l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2) AS algkulum,
    coalesce((l.properties :: JSONB ->> 'parhind') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2)  AS hind,
    coalesce((l.properties :: JSONB ->> 'kulum') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2)    AS kulum,
    coalesce((l.properties :: JSONB ->> 'jaak') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2)     AS jaak,
    l.properties,
    1 :: NUMERIC                                                                            AS kuurs,
    l.rekvid
  INTO v_pv_kaart
  FROM libs.library l
  WHERE l.id = tnId;


  IF exists(SELECT id
            FROM docs.pv_oper
            WHERE liik = array_position(a_pv_opers, 'umberhindamine') --5
                  AND pv_kaart_id = tnId)
  THEN
    -- otsime umberhindamine
    SELECT max(kpv)
    INTO umberHindamiseKpv
    FROM docs.pv_oper
    WHERE liik = array_position(a_pv_opers, 'umberhindamine')
          AND pv_kaart_id = tnId;

    v_pv_kaart.soetkpv = umberHindamiseKpv;

  END IF;


  -- kulum kokku

  SELECT
    sum(po.summa)
      FILTER (WHERE liik = array_position(a_pv_opers, 'paigutus'))       AS soetmaks,
    sum(po.summa)
      FILTER (WHERE liik = array_position(a_pv_opers, 'kulum'))          AS kulum,
    sum(po.summa)
      FILTER (WHERE liik = array_position(a_pv_opers, 'parandus'))       AS parandus,
    sum(po.summa)
      FILTER (WHERE liik = array_position(a_pv_opers, 'umberhindamine')) AS umberhind
  INTO v_pv_oper
  FROM docs.pv_oper po
  WHERE po.pv_kaart_id = tnId;
  --        AND po.kpv >= v_pv_kaart.soetkpv;

  v_pv_kaart.hind = case when empty( v_pv_kaart.hind) or v_pv_kaart.hind is null THEN  coalesce(v_pv_oper.soetmaks,0) + coalesce(v_pv_oper.parandus,0) else v_pv_kaart.hind end;

  selgitus = 'Hind: ' || v_pv_kaart.hind :: TEXT;


  lnSummaKulum = coalesce(v_pv_oper.kulum, 0) + coalesce(v_pv_kaart.algkulum, 0);

  Selgitus = Selgitus || ' kulum kokku:' + lnSummaKulum :: TEXT;

  -- calculations
  IF v_pv_kaart.Jaak > 0
  THEN
    -- month summa
    Summa = ((v_pv_kaart.kulum * 0.01 * v_pv_kaart.hind) :: NUMERIC(12, 2) / 12) :: NUMERIC(12, 2);

    Selgitus = Selgitus || 'arvestatud summa:' || Summa :: TEXT;

    IF summa > (v_pv_kaart.Jaak )
    THEN

      summa = v_pv_kaart.Jaak ;
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
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION docs.sp_calc_kulum(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_calc_kulum(INTEGER) TO dbpeakasutaja;


COMMENT ON FUNCTION docs.sp_calc_kulum(INTEGER) IS 'расчет суммы износа';

/*
SELECT result, selgitus, summa from docs.sp_calc_kulum(447)
SELECT docs.sp_calc_kulum(451);

*/