DROP FUNCTION IF EXISTS palk.sp_calc_sots(INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.sp_calc_sots(params JSONB);
--DROP FUNCTION IF EXISTS palk.sp_calc_sots(user_id INTEGER, params JSON);

DROP FUNCTION IF EXISTS palk.sp_calc_sots_(user_id INTEGER, params JSON);


CREATE OR REPLACE FUNCTION palk.sp_calc_sots(user_id INTEGER, params JSON,
                                             OUT summa NUMERIC,
                                             OUT sm NUMERIC,
                                             OUT selg TEXT,
                                             OUT error_code INTEGER,
                                             OUT result INTEGER,
                                             OUT error_message TEXT,
                                             OUT data JSONB)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_lepingid                       INTEGER        = params ->> 'lepingid';
    l_libId                          INTEGER        = params ->> 'libid';
    l_kpv                            DATE           = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_pk_summa                       NUMERIC        = coalesce((params ->> 'summa') :: NUMERIC, 33);
    is_percent                       BOOLEAN        = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                                               TRUE); -- kas pk summa percentis (33%)
    l_min_sots                       INTEGER        = ((coalesce((params ->> 'minsots') :: INTEGER, 0)) :: INTEGER);
    l_alus_summa                     NUMERIC(12, 4) = params ->> 'alus_summa'; -- tulud , milliest arvestame sots.maks
    l_round                          NUMERIC        = 0.01;
    l_params                         JSON;

    v_tooleping                      RECORD;
    l_min_palk                       NUMERIC(12, 4) = 584; --alus arvestada sots.maks min palgast (2021)

    ln_umardamine                    NUMERIC(14, 4) = 0;
    l_sotsmaks_min_palgast           NUMERIC(14, 4) = 0;
    l_enne_sotsmaks_min_palgast_alus NUMERIC(14, 4) = 0;
    l_enne_arvestatud_sotsmaks       NUMERIC(14, 4) = 0; -- summa, mis ole arvestatud koos tulu summaga, palk.oper.sotsmaks

    l_enne_koostatud_sotsmaks        NUMERIC(14, 4) = 0; -- sotsmaks, arvestatus selles kuues enne kaesolev arvestus
    l_too_paevad                     INTEGER        = 30;
    l_puudu_paevad                   INTEGER        = 0;
    l_last_paev                      DATE           =
            (date(year(l_kpv), month(l_kpv), 1) + INTERVAL '1 month') :: DATE - 1;
    l_paevad_periodis                INTEGER        = 30;
    l_min_sotsmaks_alus              NUMERIC(14, 4) = 0; -- основание для до расчет до мин. соц. налога
    l_lisa_sm                        NUMERIC(14, 4) = 0; -- до начисленные соц. налог
    l_1090_isik                      NUMERIC(14, 4) = 0; -- до начисленные соц. налог? итого по работнику
    l_selg                           TEXT = '';


BEGIN

    IF l_alus_summa IS NULL
    THEN
        -- meil ei ole alus summa, vaja arvestada alus

        -- select lepinguandmed
        SELECT t.pohikoht,
               t.rekvid,
               t.algab,
               t.lopp,
               t.parentid
               INTO v_tooleping
        FROM palk.tooleping t
        WHERE t.id = l_lepingid;


        SELECT pk.summa,
               empty(pk.percent_ :: INTEGER),
               coalesce(pk.minsots, 0) AS minsots,
               coalesce(pc.minpalk, 0) AS minpalk,
               l.round
               --    INTO v_palk_kaart
               INTO l_pk_summa, is_percent, l_min_sots, l_min_palk, l_round
        FROM palk.palk_kaart pk
                 LEFT OUTER JOIN palk.palk_config pc ON pc.rekvid = v_tooleping.rekvid
                 INNER JOIN palk.com_palk_lib l ON pk.libid = l.id
        WHERE pk.lepingid = l_lepingid
          AND libId = l_libId;

        SELECT sum(po.sotsmaks) AS sotsmaks,
               sum(po.summa),
               sum(po.summa) FILTER ( WHERE right(rtrim(po.konto), 2) NOT IN ('21', '23', '24', '25'))
               INTO summa, l_alus_summa, l_min_sotsmaks_alus
        FROM palk.cur_palkoper po
                 INNER JOIN libs.library l ON l.id = po.libid
        WHERE po.kpv = l_kpv
          AND po.rekvid = v_tooleping.rekvId
          AND po.lepingId = l_lepingid
          AND po.palk_liik = 'ARVESTUSED'
          AND po.period IS NULL
          AND po.sotsmaks IS NOT NULL;

        IF coalesce(l_min_sots, 0) > 0
        THEN
            -- считает отсутствие на раб. месте

-- params
            SELECT row_to_json(row) INTO l_params
            FROM (SELECT month(l_kpv) AS kuu,
                         year(l_kpv)  AS aasta,
                         l_lepingid   AS lepingid) row;


            l_puudu_paevad = palk.get_puudumine(l_params :: JSONB);


            --parandame tööpäevad, kui töötaja töötas mitte täis kuu
            l_too_paevad = CASE
                               WHEN COALESCE(v_tooleping.lopp, l_last_paev) < l_last_paev
                                   THEN v_tooleping.lopp
                               ELSE l_last_paev END -
                           CASE
                               WHEN v_tooleping.algab > date(YEAR(l_kpv), MONTH(l_kpv), 1)
                                   THEN v_tooleping.algab
                               ELSE date(YEAR(l_kpv), MONTH(l_kpv), 1) END +
                           1 - l_puudu_paevad;


            -- kontrollime enne arvestatud sotsmaks

            SELECT sum(po.summa) FILTER ( WHERE po.palk_liik :: TEXT = 'SOTSMAKS'),
                   sum(po.sotsmaks) FILTER ( WHERE po.palk_liik :: TEXT = 'SOTSMAKS'),
                   sum(po.summa) FILTER ( WHERE po.palk_liik :: TEXT = 'ARVESTUSED' and po.is_sotsmaks AND
                                                right(rtrim(po.konto), 2) NOT IN ('21', '23', '24', '25'))
                   INTO l_enne_arvestatud_sotsmaks, l_enne_sotsmaks_min_palgast_alus, l_min_sotsmaks_alus
            FROM palk.cur_palkoper po
            WHERE year(po.kpv) = year(l_kpv)
              AND month(po.kpv) = month(l_kpv)
              AND po.period IS NULL
              AND po.lepingid IN (SELECT t.id
                                  FROM palk.tooleping t
                                  WHERE t.parentid = v_tooleping.parentid
                                    AND t.rekvid = v_tooleping.rekvId)
              AND po.id NOT IN (SELECT p.id
                                FROM palk.cur_palkoper p
                                WHERE p.lepingId = l_lepingid
                                  AND libId = l_libId
                                  AND kpv = l_kpv);

            l_enne_arvestatud_sotsmaks = coalesce(l_enne_arvestatud_sotsmaks, 0);


        END IF;

        -- считаем календарные дни
        l_paevad_periodis =
                palk.get_days_of_month_in_period(month(l_kpv), year(l_kpv), date(year(l_kpv), month(l_kpv), 01),
                                                 l_kpv);

        -- вычитаем отпуск в календарных днях
        SELECT row_to_json(row) INTO l_params
        FROM (SELECT month(l_kpv) AS kuu,
                     year(l_kpv)  AS aasta,
                     TRUE         AS kas_kalendripaevad,
                     TRUE         AS puudumised,
                     l_lepingid   AS lepingid) row;


        l_puudu_paevad = palk.get_puudumine(l_params :: JSONB);

        -- за вычитом отпуска и больничного
        l_paevad_periodis = l_paevad_periodis - l_puudu_paevad;


        IF NOT empty(l_min_sots) AND NOT empty(l_min_palk) AND
           (l_min_sotsmaks_alus * l_pk_summa * 0.01) <
           (l_min_palk * l_min_sots * l_pk_summa * 0.01) --arvetsame sotsmaks min.palgast
        THEN

            -- 584* 0.33 с поправкой на дни
            l_sotsmaks_min_palgast = ((l_min_palk * l_min_sots * l_pk_summa * 0.01) / 30 * (l_paevad_periodis));


            -- не может быть больше мин. соц. налога
            IF l_sotsmaks_min_palgast > (l_min_palk * l_min_sots * l_pk_summa * 0.01)
            THEN
                l_sotsmaks_min_palgast = (l_min_palk * l_min_sots * l_pk_summa * 0.01);

                IF l_sotsmaks_min_palgast > coalesce(l_enne_arvestatud_sotsmaks, 0)
                THEN
                    l_sotsmaks_min_palgast = l_sotsmaks_min_palgast - coalesce(l_enne_arvestatud_sotsmaks, 0);
                ELSE
                    -- не используем см с мин. ЗП
                    l_sotsmaks_min_palgast = 0;
                END IF;

                -- основа начисления соц. налога
                sm = f_round(l_min_palk - l_min_sotsmaks_alus, l_round);


                -- считаем доп. налог с поправленной суммы
                l_lisa_sm = f_round(sm * l_pk_summa * 0.01, l_round);

            END IF;


        END IF;

        IF coalesce(l_enne_sotsmaks_min_palgast_alus, 0) > 0
        THEN
            -- был расчет с мин. соц. налогом
        END IF;

        IF coalesce(summa, 0) < l_sotsmaks_min_palgast AND (l_alus_summa = 0 OR summa > 0) OR
           coalesce(l_enne_sotsmaks_min_palgast_alus, 0) > 0

        THEN
            -- расчет основания для миню соц. налога
            -- 584/30*24=467.20-399,08=68,12 евро
            IF sm IS NULL OR empty(sm)
            THEN
                sm = f_round(l_min_palk / 30 * l_paevad_periodis - l_min_sotsmaks_alus, l_round);
                if l_min_palk < l_min_sotsmaks_alus and l_enne_sotsmaks_min_palgast_alus > 0 THEN
                    -- правим ранее расчитанный мин. соц. налог
                    sm = -1 * l_enne_sotsmaks_min_palgast_alus;
                    l_selg = 'min. SM parandus -1 * ' || l_enne_sotsmaks_min_palgast_alus::text;
                END IF;
                l_lisa_sm = f_round(sm * l_pk_summa * 0.01, l_round);
            END IF;
            -- доп.ю соц. налог равен мин. соц минус начисленный

--            l_sotsmaks_min_palgast = l_sotsmaks_min_palgast - summa;
        ELSE
            l_sotsmaks_min_palgast = 0;
        END IF;
raise notice 'l_min_sotsmaks_alus %', l_min_sotsmaks_alus;
        IF sm IS NOT NULL
        THEN

            l_selg = '(' || 'lisa SM (' + case when not empty(l_selg) then l_selg else l_min_palk::TEXT + '/30 * ' ||
                     l_paevad_periodis::TEXT || '-' + l_min_sotsmaks_alus::TEXT  END + ') ' + coalesce(sm, 0)::TEXT ||
                     '* 0.33 = SM MIN.palgast ';
        ELSE
            l_selg = '';
        END IF;

        selg = '(' + l_alus_summa::TEXT + ' * 0.33)' + coalesce(summa, 0) :: TEXT || l_selg || l_lisa_sm :: TEXT ||
               ')' || CASE WHEN ln_umardamine <> 0 THEN ' +  (umardamine) ' || ln_umardamine :: TEXT ELSE '' END;

        summa = f_round(coalesce(summa, 0) + l_lisa_sm + ln_umardamine, l_round);

    ELSE
        -- arvestus
        summa = l_alus_summa * l_pk_summa * 0.01;
        selg = l_alus_summa :: TEXT || ' * ' || (l_pk_summa * 0.01) :: TEXT;

    END IF;

    result = 1;
    summa = coalesce(f_round(summa, l_round), 0);
    l_params = to_jsonb(row.*)
               FROM (
                        SELECT NULL                   AS doc_id,
                               'Õnnestus'             AS error_message,
                               0::INTEGER             AS error_code,
                               summa                  AS summa,
                               selg                   AS selg,
                               sm:: NUMERIC           AS sm,
                               l_sotsmaks_min_palgast AS sotsmaks_min_palgast
                    ) row;
    data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

    RETURN;

END;

$$;


SELECT *
FROM palk.sp_calc_sots(1, '{
  "lepingid": 35756,
  "libid": 236702,
  "kpv": "2021-01-31"
}'::JSON)


    {"lepingid":35756,"libid":236702,"kpv":20210128}

select * from palk.puudumine
where lepingid = 35756

/*

select * from ou.rekv where nimetus ilike '%paju%'



select * from palk.tooleping where  parentid in (select id from libs.asutus where regkood = '48211153720')
select * from palk.palk_oper where lepingid = 35756

select * from palk.sp_calc_sots(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09", "alus_summa":100, "summa":33}'::JSON)
select * from palk.sp_calc_sots(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09", "alus_summa":0, "summa":50, "is_percent":false}'::JSON)
select * from  palk.sp_calc_sots(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09", "alus_summa":100, "summa":33, "is_percent":true,"minsots":1}'::JSON)
select * from palk.sp_calc_sots(1, '{"alus_summa":100, "summa":33, "is_percent":true,"minsots":1}'::JSON)
select * from palk.sp_calc_sots(1,'{"lepingid":4,"libid":524,"kpv":20180407}'::JSON)

select * from libs.asutus where regkood = '45911143728'
-- 2947

select * from palk.tooleping where parentid =  41923 and rekvid in (select id from ou.rekv where nimetus ilike '%keel%')
32857

select * from palk.palk_oper where lepingid = 35124 and kpv = '2021-01-31'

select * from palk.sp_calc_sots(70, '{"lepingid":26028, "libid":149418, "kpv":"2019-11-20"}'::JSON)

 */