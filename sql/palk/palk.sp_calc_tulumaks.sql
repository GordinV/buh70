DROP FUNCTION IF EXISTS palk.sp_calc_tulumaks( INTEGER, INTEGER, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS palk.sp_calc_tulumaks(params JSONB );
DROP FUNCTION IF EXISTS palk.sp_calc_tulumaks(user_id INTEGER, params JSON );

CREATE FUNCTION palk.sp_calc_tulumaks(user_id       INTEGER, params JSON,
  OUT                                 summa         NUMERIC,
  OUT                                 mvt           NUMERIC,
  OUT                                 selg          TEXT,
  OUT                                 error_code    INTEGER,
  OUT                                 result        INTEGER,
  OUT                                 error_message TEXT)
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
  v_tooleping           RECORD;

BEGIN
  mvt = l_mvt;
  -- kustutame vana info
  IF l_alus_summa IS NULL
  THEN
    selg = 'ennearvestatud TM ' || '(r)';
    SELECT
      pk.percent_,
      pk.summa,
      l.round
    INTO is_percent, l_pk_summa, l_round
    FROM palk.palk_kaart pk
      INNER JOIN palk.com_palk_lib l ON pk.libid = l.id
    WHERE pk.lepingid = l_lepingid AND pk.libId = l_libId;

    selg = coalesce(selg, '') || 'pk summa:' || l_pk_summa :: TEXT || CASE WHEN is_percent
      THEN '%'
                                                                      ELSE ' EUR' END || '(r)';

    SELECT
      rekvid,
      parentid
    INTO v_tooleping
    FROM palk.tooleping t
    WHERE t.id = l_lepingid;

    SELECT
      sum(coalesce(po.tulubaas, 0)),
      sum(coalesce(po.tulumaks, 0))
        FILTER (WHERE lepingid = l_lepingid) AS tulumaks,
      sum(po.summa)
        FILTER (WHERE lepingid = l_lepingid) AS tulud
    INTO l_kasutatud_mvt_summa, summa, l_alus_summa
    FROM palk.cur_palkoper po
    WHERE po.kpv = l_kpv
          AND po.rekvid = v_tooleping.rekvid
          AND po.palk_liik = 'ARVESTUSED'
          AND po.lepingId IN (SELECT t.id
                              FROM palk.tooleping t
                              WHERE t.parentid = v_tooleping.parentId);

    mvt = l_kasutatud_mvt_summa;

    selg = coalesce(selg, '') || 'mvt arvestus: kasutatud mvt summa: ' || '(r)' ||
           coalesce(l_kasutatud_mvt_summa, 0) :: TEXT || '(r)' ||
           'TM enne arvestatud:' || coalesce(summa, 0) :: TEXT || '(r)' ||
           'Tulud: ' || coalesce(l_alus_summa, 0) :: TEXT || '(r)';

    IF coalesce(summa, 0) = 0
    THEN
      -- puudub tm arvestus,

      l_mvt = coalesce((SELECT sum(mvt.summa)
                        FROM palk.taotlus_mvt mvt
                          INNER JOIN palk.tooleping t ON t.id = mvt.lepingId
                        WHERE t.parentId = v_tooleping.parentId
                              AND mvt.status = 'active'
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

      selg = coalesce(selg, '') || 'puudub tm arvestus, arvestan TM. MVT: ' || l_mvt :: TEXT || '(r)' ||
             'kasutatud mvt: ' || l_kasutatud_mvt_summa :: TEXT || '(r)' ||
             'kulud: ' || l_tm_miinus_summa :: TEXT || '(r)';

      mvt = l_kasutatud_mvt_summa;

    END IF;

  END IF;

  -- arvestame
  IF coalesce(summa, 0) = 0
  THEN
    IF NOT is_percent
    THEN
      -- summa
      summa = l_pk_summa;
      selg = coalesce(selg, '') || 'kasutame pk summa: ' || coalesce(summa, 0) :: TEXT || '(r)';
    ELSE
      IF l_kasutatud_mvt_summa > l_mvt -- mvt kasutatud kokku
      THEN
        l_mvt = 0;
        l_kasutatud_mvt_summa = 0;
      ELSE
        l_mvt = l_mvt - l_kasutatud_mvt_summa;
      END IF;

      summa = f_round(palk.fnc_calc_tm(l_alus_summa, l_mvt, l_tm_miinus_summa, 0,
                                       NULL :: TEXT, l_pk_summa), l_round);

      selg = coalesce(selg, '') || 'arvestatud TM:' || coalesce(summa, 0) :: TEXT || '(r)';

      selg = coalesce(selg, '') || '( Tulud kokku ' || coalesce(l_alus_summa, 0) :: TEXT || ' - MVT ' ||
             coalesce(l_mvt, 0) :: TEXT || ' - Kulud ' ||
             coalesce(l_tm_miinus_summa, 0) :: TEXT || ' * ' ||
             coalesce(l_pk_summa, 0) :: TEXT || '%)';

      IF summa < 0
      THEN
        summa = 0;
      END IF;
      mvt = l_mvt;

    END IF;

  END IF;
  result = 1;
  summa = coalesce(summa, 0);
  RETURN;
END;
$$;

/*
select palk.sp_calc_tulumaks(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSON)
select palk.sp_calc_tulumaks(1, '{"alus_summa":100}'::JSON)
select palk.sp_calc_tulumaks(1, '{"alus_summa":0, "is_percent":false, "summa":100}'::JSON)
select palk.sp_calc_tulumaks(1, '{"alus_summa":1000, "is_percent":true, "summa":20, "mvt":500}'::JSON)
select palk.sp_calc_tulumaks(1, '{"alus_summa":1000, "is_percent":true, "mvt":500, "kulud":36}'::JSON)
select selg, * from palk.sp_calc_tulumaks(1,	'{"lepingid":4,"libid":525,"kpv":20180407}')

 */