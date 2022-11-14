DROP FUNCTION IF EXISTS palk.sp_calc_tulumaks(INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.sp_calc_tulumaks(params JSONB);
DROP FUNCTION IF EXISTS palk.sp_calc_tulumaks(user_id INTEGER, params JSON);

CREATE FUNCTION palk.sp_calc_tulumaks(user_id INTEGER, params JSON,
                                      OUT summa NUMERIC,
                                      OUT mvt NUMERIC,
                                      OUT selg TEXT,
                                      OUT error_code INTEGER,
                                      OUT result INTEGER,
                                      OUT error_message TEXT)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_lepingid            INTEGER        = params ->> 'lepingid';
    l_libId               INTEGER        = params ->> 'libid';
    l_kpv                 DATE           = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_pk_summa            NUMERIC        = coalesce((params ->> 'summa') :: NUMERIC, 20);
    is_percent            BOOLEAN        = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                                    TRUE); -- kas pk summa percentis (20%)
    l_alus_summa          NUMERIC(12, 4) = params ->> 'alus_summa'; -- tulud , milliest arvestame tulumaks
    l_kasutatud_mvt_summa NUMERIC(12, 4) = coalesce((params ->> 'kasutatud_mvt_summa') :: NUMERIC, 0); -- kasutatud mvt
    l_mvt                 NUMERIC(12, 4) = coalesce((params ->> 'mvt') :: NUMERIC, 0); -- mvt
    l_tm_miinus_summa     NUMERIC(12, 4) = coalesce((params ->> 'kulud') :: NUMERIC, 0); -- tm miinus summad
    l_round               NUMERIC        = 0.01;
    v_tooleping           RECORD;

BEGIN
    mvt = l_mvt;
    -- kustutame vana info
        raise notice 'l_alus_summa %', l_alus_summa;
    IF l_alus_summa IS NULL
    THEN
        selg = 'ennearvestatud TM ' || '(r)';
        SELECT pk.percent_,
               pk.summa,
               l.round
               INTO is_percent, l_pk_summa, l_round
        FROM palk.palk_kaart pk
                 INNER JOIN palk.com_palk_lib l ON pk.libid = l.id
        WHERE pk.lepingid = l_lepingid
          AND pk.libId = l_libId;

        selg = coalesce(selg, '') || 'pk summa:' || l_pk_summa :: TEXT || CASE
                                                                              WHEN is_percent
                                                                                  THEN '%'
                                                                              ELSE ' EUR' END || '(r)';

        SELECT rekvid,
               parentid
               INTO v_tooleping
        FROM palk.tooleping t
        WHERE t.id = l_lepingid;

        SELECT sum(coalesce(po.tulubaas, 0)),
               sum(coalesce(po.tulumaks, 0))
                   FILTER (WHERE lepingid = l_lepingid) AS tulumaks,
               sum(po.summa)
                   FILTER (WHERE lepingid = l_lepingid) AS tulud
               INTO l_kasutatud_mvt_summa, summa, l_alus_summa
        FROM (SELECT p.summa,
                     p.sotsmaks,
                     p.tulubaas,
                     p.tulumaks,
                     p.konto,
                     p.kpv,
                     p.rekvid,
                     p.libid,
                     p.period,
                     ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT AS palk_liik,
                     p.lepingid
              FROM docs.doc d
                       INNER JOIN palk.palk_oper p ON p.parentid = d.id
                       INNER JOIN libs.library lib ON p.libid = lib.id AND lib.library = 'PALK'
                       INNER JOIN palk.tooleping t ON p.lepingid = t.id
             ) po
        WHERE po.kpv = l_kpv
          AND po.rekvid = v_tooleping.rekvid
          AND po.palk_liik = 'ARVESTUSED'
          AND po.period IS NULL
          AND po.lepingId IN (SELECT t.id
                              FROM palk.tooleping t
                              WHERE t.parentid = v_tooleping.parentId);

        mvt = l_kasutatud_mvt_summa;

        selg = coalesce(selg, '') || 'mvt arvestus: kasutatud mvt summa: ' || '(r)' ||
               coalesce(l_kasutatud_mvt_summa, 0) :: TEXT || '(r)' ||
               'TM enne arvestatud:' || coalesce(summa, 0) :: TEXT || '(r)' ||
               'Tulud: ' || coalesce(l_alus_summa, 0) :: TEXT || '(r)';

    END IF;

    result = 1;
    summa = coalesce(summa, 0);
    RETURN;
END;
$$;

/*
select * from palk.sp_calc_tulumaks(1, '{"lepingid":20016, "libid":145459, "kpv":"2021-01-31"}'::JSON)

select palk.sp_calc_tulumaks(1, '{"alus_summa":100}'::JSON)
select palk.sp_calc_tulumaks(1, '{"alus_summa":0, "is_percent":false, "summa":100}'::JSON)
select palk.sp_calc_tulumaks(1, '{"alus_summa":1000, "is_percent":true, "summa":20, "mvt":500}'::JSON)
select palk.sp_calc_tulumaks(1, '{"alus_summa":1000, "is_percent":true, "mvt":500, "kulud":36}'::JSON)
select selg, * from palk.sp_calc_tulumaks(1,	'{"lepingid":4,"libid":525,"kpv":20180407}')

 */