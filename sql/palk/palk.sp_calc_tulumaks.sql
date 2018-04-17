DROP FUNCTION IF EXISTS palk.sp_calc_tulumaks( INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS palk.sp_calc_tulumaks(params JSONB );

CREATE FUNCTION palk.sp_calc_tulumaks(params JSONB)
  RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
  l_lepingid            INTEGER = params ->> 'lepingid';
  l_libId               INTEGER = params ->> 'libid';
  l_kpv                 DATE = coalesce((params ->> 'kpv') :: DATE, current_date);
  l_pk_summa            NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, 20);
  is_percent            BOOLEAN = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                           TRUE); -- kas pk summa percentis (20%)
  l_alus_summa          NUMERIC(12, 4) = params ->> 'alus_summa'; -- tulud , milliest arvestame tulumaks
  l_kasutatud_mvt_summa NUMERIC(12, 4) = coalesce((params ->> 'kasutatud_mvt_summa') :: NUMERIC, 0); -- kasutatud mvt
  l_mvt                 NUMERIC(12, 4) = coalesce((params ->> 'mvt') :: NUMERIC, 0); -- mvt
  l_tm_miinus_summa     NUMERIC(12, 4) = coalesce((params ->> 'kulud') :: NUMERIC, 0); -- tm miinus summad
  l_round               NUMERIC = 0.01;
  l_params              JSON;

  l_tm_summa            NUMERIC(12, 4);
  v_tooleping           RECORD;

  lnTuludPm             NUMERIC(14, 4);
  lnKulud               NUMERIC(14, 4);

  /*
    ltSelgitus    TEXT = '';
    ltEnter       CHARACTER;
    lcTimestamp   VARCHAR(20);
  */

  lnTkiPm               NUMERIC(14, 4);
  lnPMPm                NUMERIC(14, 4);
BEGIN
  -- kustutame vana info
  IF l_alus_summa IS NULL
  THEN
    SELECT
      pk.percent_,
      pk.summa,
      l.round
    INTO is_percent, l_pk_summa, l_round
    FROM palk.palk_kaart pk
      INNER JOIN palk.com_palk_lib l ON pk.libid = l.id
    WHERE pk.lepingid = l_lepingid AND pk.libId = l_libId;

    SELECT
      rekvid,
      parentid
    INTO v_tooleping
    FROM palk.tooleping t
    WHERE t.id = l_lepingid;

    SELECT
      sum(coalesce(po.tulubaas, 0)),
      sum(coalesce(po.tulumaks, 0))
        FILTER (WHERE lepingid = v_tooleping.rekvid) AS tulumaks,
      sum(po.summa)
        FILTER (WHERE lepingid = v_tooleping.rekvid) AS tulud
    INTO l_kasutatud_mvt_summa, l_tm_summa, l_alus_summa
    FROM palk.cur_palkoper po
    WHERE po.kpv = l_kpv
          AND po.rekvid = v_tooleping.rekvid
          AND po.palk_liik = 'ARVESTUSED'
          AND po.lepingId IN (SELECT t.id
                              FROM palk.tooleping t
                              WHERE t.parentid = v_tooleping.parentId);

    IF coalesce(l_tm_summa, 0) = 0
    THEN
      -- puudub tm arvestus,
      l_mvt = coalesce((SELECT sum(mvt.summa)
                        FROM palk.taotlus_mvt mvt
                          INNER JOIN palk.tooleping t ON t.id = mvt.lepingId
                        WHERE t.parentId = v_tooleping.parentId
                              AND t.rekvid = v_tooleping.rekvid
                              AND alg_kpv <= l_kpv
                              AND lopp_kpv >= l_kpv), 0);


      l_kasutatud_mvt_summa = (SELECT sum(coalesce(po.tulubaas, 0))
                               FROM palk.cur_palkoper po
                                 INNER JOIN palk.tooleping t ON t.id = po.lepingId
                               WHERE t.parentid = v_tooleping.parentId
                                     AND t.rekvid = v_tooleping.rekvid
                                     AND po.period IS NULL
                                     AND po.palk_liik = 'ARVESTUSED'
                                     AND year(po.kpv) = year(l_kpv) AND month(po.kpv) = month(l_kpv));


      l_tm_miinus_summa = (SELECT sum(coalesce(po.tootumaks, 0) + coalesce(po.pensmaks, 0))
                           FROM palk.cur_palkoper po
                             INNER JOIN palk.tooleping t ON t.id = po.lepingId
                           WHERE t.parentid = v_tooleping.parentId
                                 AND t.rekvid = v_tooleping.rekvid
                                 AND po.period IS NULL
                                 AND po.palk_liik = 'ARVESTUSED'
                                 AND year(po.kpv) = year(l_kpv) AND month(po.kpv) = month(l_kpv));

    END IF;

  END IF;

  raise notice 'l_tm_summa %',l_tm_summa;
  -- arvestame
  IF coalesce(l_tm_summa, 0) = 0
  THEN
    IF NOT is_percent
    THEN
      -- summa
      l_tm_summa = l_pk_summa;
    ELSE
      IF l_kasutatud_mvt_summa > l_mvt -- mvt kasutatud kokku
      THEN
        l_mvt = 0;
        l_kasutatud_mvt_summa = 0;
      ELSE
        l_mvt = l_mvt - l_kasutatud_mvt_summa;
      END IF;
      l_tm_summa = f_round(((l_alus_summa - l_mvt - l_tm_miinus_summa) * l_pk_summa * 0.01), l_round);
    END IF;

  END IF;

  RETURN coalesce(l_tm_summa, 0);
END;
$$;

/*
select palk.sp_calc_tulumaks('{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSONB)
select palk.sp_calc_tulumaks('{"alus_summa":100}'::JSONB)
select palk.sp_calc_tulumaks('{"alus_summa":0, "is_percent":false, "summa":100}'::JSONB)
select palk.sp_calc_tulumaks('{"alus_summa":1000, "is_percent":true, "summa":20, "mvt":500}'::JSONB)
select palk.sp_calc_tulumaks('{"alus_summa":1000, "is_percent":true, "mvt":500, "kulud":36}'::JSONB)

 */