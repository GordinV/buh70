DROP FUNCTION IF EXISTS palk.sp_calc_umardamine(INTEGER, JSON);
DROP FUNCTION IF EXISTS palk.sp_calc_umardamine_(INTEGER, JSON);

CREATE OR REPLACE FUNCTION palk.sp_calc_umardamine(IN user_id INTEGER, params JSON, OUT result INTEGER,
                                                    OUT error_code INTEGER, OUT error_message TEXT)
    --tnisikid integer, tdkpv date, tnrekvid integer)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_isikid      INTEGER = params ->> 'isikid';
    l_kpv         DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_rekvid      INTEGER = params ->> 'rekvid';
    l_lepingid    INTEGER = params ->> 'lepingid'; --параметры для сохранения операции округления
    l_libid       INTEGER = params ->> 'libid'; --параметры для сохранения операции округления
    v_tululiik    RECORD;
    v_leping      RECORD;
    v_arv         RECORD;
    v_fakt_arv    RECORD;
    v_palk_oper   RECORD;
    ldKpv         DATE    = (date(year(l_kpv), month(l_kpv), 1) + INTERVAL '1 month') :: DATE -
                            1; -- сохраняем расчет последним днем месяца
    l_id          INTEGER;
    tulemus       RECORD;
    l_params      JSON;
    l_save_params JSON;
    v_user        RECORD;
    l_mvt_kokku   NUMERIC;
BEGIN
    SELECT kasutaja,
           rekvid
    INTO v_user
    FROM ou.userid u
    WHERE u.id = user_Id;

    IF v_user.kasutaja IS NULL
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;
    END IF;

    IF l_isikid IS NULL AND l_lepingid IS NOT NULL
    THEN
        -- найдем isikId по ИД договора
        l_isikid = (SELECT parentid
                    FROM palk.tooleping
                    WHERE id = l_lepingid);
    END IF;

    IF l_isikid IS NULL OR l_lepingid IS NULL OR l_libid IS NULL
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad';
        result = 0;
        RETURN;

    END IF;

    IF l_rekvid IS NULL AND l_lepingid IS NOT NULL
    THEN
        -- найдем rekvId по договору
        l_rekvid = (SELECT rekvid
                    FROM palk.tooleping t
                    WHERE id = l_lepingid);
    END IF;

    --assign default value to v_leping
    v_leping = ROW (NULL);

    -- kustutame eelamise umardamine arvestus

    DELETE
    FROM docs.doc
    WHERE id IN (
        SELECT parentid
        FROM palk.palk_oper po
        WHERE lepingId IN (
            SELECT t.id
            FROM palk.tooleping t
            WHERE t.parentId = l_isikid
        )
          AND lepingid = l_lepingid -- поправка из-за ошибки на величину округдения
          AND kpv = l_kpv
          AND rekvId = l_rekvid
          AND summa = 0);

    DELETE
    FROM palk.palk_oper po
    WHERE lepingId IN (
        SELECT t.id
        FROM palk.tooleping t
        WHERE t.parentId = l_isikid
    )
      AND lepingid = l_lepingid -- поправка из-за ошибки на величину округдения
      AND kpv = l_kpv
      AND rekvId = l_rekvid
      AND summa = 0;


    -- arvestame, loop for each tululiik
    FOR v_tululiik IN
        SELECT po.tululiik,
               sum(po.summa)       AS summa,
               count(po.id)        AS arv_count,
               sum(po.tulubaas)    AS mvt,
               sum(po.tootumaks)   AS tki,
               sum(po.pensmaks)    AS pm,
               sum(po.tulumaks)    AS tm,
               count(*) OVER ()    AS tululiigi_arv,
               max(l.sm_maksustav) AS sm_maksustav,
               max(l.tk_maksustav) AS tk_maksustav,
               max(l.pm_maksustav) AS pm_maksustav
        FROM palk.cur_palkoper po
                 LEFT OUTER JOIN (SELECT l.kood,
                                         l.tun1 AS tm_maar,
                                         l.tun2 AS sm_maksustav,
                                         l.tun4 AS tk_maksustav,
                                         l.tun5 AS pm_maksustav
                                  FROM libs.library l
                                  WHERE LIBRARY = 'MAKSUKOOD'
                                    AND l.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')) l
                                 ON l.kood = po.tululiik
        WHERE po.lepingId IN (
            SELECT t.id
            FROM palk.tooleping t
            WHERE t.parentId = l_isikid
        )
          AND po.kpv >= date(year(l_kpv), month(l_kpv), 1)
          AND po.kpv <= ldKpv
          AND po.period IS NULL
          --and po.kpv = tdKpv
          AND po.rekvId = l_rekvid
          AND po.palk_liik = 'ARVESTUSED'
        GROUP BY po.tululiik, po.palk_liik
        ORDER BY po.palk_liik
        LOOP
            IF v_tululiik.arv_count > 1
            THEN
                -- есть необходимость в округлении
                SELECT sum(summa) OVER () AS summa,
                       lepingid,
                       libid
                INTO v_leping
                FROM palk.cur_palkoper po
                         INNER JOIN palk.tooleping t ON t.id = po.lepingId
                WHERE t.parentId = l_isikid
                  AND po.kpv = l_kpv
                  AND po.period IS NULL
                  AND po.rekvId = l_rekvid
                  AND po.palk_liik = 'ARVESTUSED'
                  AND po.tululiik = v_tululiik.tululiik
                  AND po.summa <> 0
                ORDER BY t.pohikoht DESC, po.summa DESC
                LIMIT 1;

                IF v_leping.lepingId IS NOT NULL
                THEN
                    --calculate full summa for this tululiik
                    -- Готовим параметры для расчета

                    SELECT row_to_json(row)
                    INTO l_params
                    FROM (SELECT l_kpv             AS kpv,
                                 v_leping.lepingId AS lepingid,
                                 v_leping.libId    AS libid,
                                 v_tululiik.summa  AS alus_summa,
                                 v_tululiik.mvt    AS mvt,
                                 TRUE              AS umardamine
                         ) row;

                    -- вызов процедура расчета

                    SELECT *
                    FROM palk.sp_calc_arv(user_id, l_params)
                    INTO STRICT v_arv;


-- get mvt from taotlus
                    l_mvt_kokku = coalesce((SELECT sum(mvt.summa)
                                            FROM palk.taotlus_mvt mvt
                                                     INNER JOIN palk.com_toolepingud t ON t.id = mvt.lepingId
                                            WHERE t.parentId = l_isikid
                                              AND mvt.status <> 'deleted'
                                              AND (l_rekvid IS NULL OR t.rekvid = l_rekvid)
                                              AND alg_kpv <= l_kpv
                                              AND lopp_kpv >= l_kpv), 0);


                    -- get fact summa done before
                    SELECT sum(po.tulubaas)                                 AS mvt,
                           sum(po.summa)
                           FILTER (WHERE po.tululiik = v_tululiik.tululiik) AS arv,
                           sum(po.tulumaks)
                           FILTER (WHERE po.tululiik = v_tululiik.tululiik) AS tm,
                           sum(po.sotsmaks)
                           FILTER (WHERE po.tululiik = v_tululiik.tululiik) AS sm,
                           sum(po.tootumaks)
                           FILTER (WHERE po.tululiik = v_tululiik.tululiik) AS tki,
                           sum(po.pensmaks)
                           FILTER (WHERE po.tululiik = v_tululiik.tululiik) AS pm,
                           sum(po.tka)
                           FILTER (WHERE po.tululiik = v_tululiik.tululiik) AS tka

                    INTO v_fakt_arv
                    FROM palk.cur_palkoper po
                    WHERE po.lepingId IN (
                        SELECT t.id
                        FROM palk.tooleping t
                        WHERE t.parentId = l_isikid
                    )
                      --	and po.kpv = tdKpv
                      AND po.kpv >= date(year(l_kpv), month(l_kpv), 1)
                      AND kpv <= ldKpv
                      AND po.period IS NULL
                      AND po.rekvId = l_rekvid
                      AND po.palk_liik = 'ARVESTUSED';

                    -- check if we need to round taxes
                    IF coalesce(v_arv.tm, 0) - round(coalesce(v_fakt_arv.tm, 0), 2) <> 0 OR
                       (coalesce(v_arv.sm, 0) - round(coalesce(v_fakt_arv.sm, 0), 2)) * v_tululiik.sm_maksustav <> 0 OR
                       (coalesce(v_arv.tki, 0) - round(coalesce(v_fakt_arv.tki, 0), 2)) * v_tululiik.tk_maksustav <>
                       0 OR
                       (coalesce(v_arv.tka, 0) - round(coalesce(v_fakt_arv.tka, 0), 2)) * v_tululiik.tk_maksustav <>
                       0 OR
                       (coalesce(v_arv.pm, 0) - round(coalesce(v_fakt_arv.pm, 0), 2)) * v_tululiik.pm_maksustav <> 0 OR
                       (CASE
                            WHEN v_tululiik.tululiigi_arv > 1 THEN 0
                            WHEN (v_tululiik.tululiik::INTEGER < 20 OR v_tululiik.tululiik = '24') THEN 1
                            ELSE 0 END) * coalesce(v_arv.mvt, 0) -
                       (CASE
                            WHEN v_tululiik.tululiigi_arv > 1 THEN 0
                            WHEN (v_tululiik.tululiik::INTEGER < 20 OR v_tululiik.tululiik = '24') THEN 1
                            ELSE 0 END) *
                       round(coalesce(v_fakt_arv.mvt, 0), 2) <> 0
                    THEN
                        --saving diff
                        -- will find last arvestus

                        IF l_lepingid IS NULL
                        THEN

                            SELECT libid,
                                   lepingid
                            INTO l_libId, l_lepingId
                            FROM palk.cur_palkoper po
                            WHERE po.lepingid IN (SELECT t.id
                                                  FROM palk.tooleping t
                                                  WHERE t.parentid = l_isikid
                                                    AND t.rekvid = l_rekvid)
                              AND po.period IS NULL
                              AND po.kpv = l_kpv
                              AND po.tululiik = v_tululiik.tululiik :: INTEGER
                              AND po.summa <> 0
                            ORDER BY po.id DESC
                            LIMIT 1;
                        END IF;
                        -- если не переданны параметры

                        --готовим параметры для сохранения операции
                        SELECT NULL :: INTEGER                                              AS id,
                               l_kpv                                                        AS kpv,
                               l_lepingid                                                   AS lepingid,
                               l_libid                                                      AS libid,
                               0                                                            AS summa,
                               NULL :: INTEGER                                              AS dokpropid,
                               coalesce(v_arv.tm - round(v_fakt_arv.tm, 2), 0) :: NUMERIC   AS tulumaks,
                               coalesce(v_arv.sm - round(v_fakt_arv.sm, 2), 0) *
                               v_tululiik.sm_maksustav :: NUMERIC                           AS sotsmaks,
                               coalesce(v_arv.tki - round(v_fakt_arv.tki, 2), 0) *
                               v_tululiik.tk_maksustav:: NUMERIC                            AS tootumaks,
                               coalesce(v_arv.tka - round(v_fakt_arv.tka, 2), 0) *
                               v_tululiik.tk_maksustav :: NUMERIC                           AS tka,
                               coalesce(v_arv.pm - round(v_fakt_arv.pm, 2), 0) *
                               v_tululiik.pm_maksustav :: NUMERIC                           AS pensmaks,
                               (CASE
                                    WHEN v_fakt_arv.mvt < v_arv.mvt_kokku THEN 1 -- если меньше 500 то округляем
                                    WHEN v_tululiik.tululiigi_arv > 1 THEN 0
                                    WHEN v_tululiik.tululiik ::INTEGER < 20 THEN 1
                                    ELSE 0 END) *
                               CASE
                                   WHEN v_tululiik.tululiigi_arv > 1
                                       -- дала ошибку в расчете мвт 27.03.2024
                                       --     AND v_fakt_arv.mvt > v_arv.mvt_kokku
                                       THEN 0
                                   WHEN v_tululiik.tululiik::INTEGER < 20 THEN 1
                                   ELSE 0 END *
                               coalesce(v_arv.mvt - round(v_fakt_arv.mvt, 2), 0) :: NUMERIC AS tulubaas,
                               v_tululiik.tululiik                                          AS tululiik,
                               'Umardamine' :: TEXT || v_arv.selg                           AS selg
                        INTO v_palk_oper;

                        l_save_params = row_to_json(v_palk_oper);

                        IF v_palk_oper.summa <> 0 OR v_palk_oper.tulumaks <> 0 OR v_palk_oper.sotsmaks <> 0 OR
                           v_palk_oper.tulumaks <> 0
                            OR v_palk_oper.tootumaks <> 0
                            OR v_palk_oper.tka <> 0 OR v_palk_oper.pensmaks <> 0 OR v_palk_oper.tulubaas <> 0
                        THEN
                            -- save results
                            l_id = palk.sp_salvesta_palk_oper(('{"data":' || l_save_params || '}') :: JSON, user_id,
                                                              l_rekvid);

                        END IF;
                    END IF;

                END IF;

            END IF; -- arv count peaks rohkem kui 1

        END LOOP;
    result = 1;

    RETURN;
END;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.sp_calc_umardamine(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_calc_umardamine(INTEGER, JSON) TO dbpeakasutaja;


/*

SELECT * FROM palk.sp_calc_umardamine(4711, '{"kpv":"2022-02-01","rekvid":3,"lepingid":19394,"libid":230114}')


 */