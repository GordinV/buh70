DROP FUNCTION IF EXISTS palk.sp_calc_sots(INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.sp_calc_sots(params JSONB);
DROP FUNCTION IF EXISTS palk.sp_calc_sots(user_id INTEGER, params JSON);

DROP FUNCTION IF EXISTS palk.sp_calc_sots(user_id INTEGER, params JSON);


CREATE OR REPLACE FUNCTION palk.sp_calc_sots(user_id INTEGER, params JSON,
                                             OUT summa NUMERIC,
                                             OUT sm NUMERIC,
                                             out ettemaksu_summa numeric,
                                             out ettemaksu_oper_ids jsonb,
                                             out alus_oper_ids jsonb,
                                             OUT selg TEXT,
                                             OUT error_code INTEGER,
                                             OUT result INTEGER,
                                             OUT error_message TEXT,
                                             OUT data JSONB)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_lepingid                         INTEGER        = params ->> 'lepingid';
    l_libId                            INTEGER        = params ->> 'libid';
    l_kpv                              DATE           = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_pk_summa                         NUMERIC        = coalesce((params ->> 'summa') :: NUMERIC, 33);
    is_percent                         BOOLEAN        = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                                                 TRUE); -- kas pk summa percentis (33%)
    l_min_sots                         INTEGER        = ((coalesce((params ->> 'minsots') :: INTEGER, 0)) :: INTEGER);
    l_alus_summa                       NUMERIC(12, 4) = params ->> 'alus_summa'; -- tulud , milliest arvestame sots.maks
    kas_arvesta_min_sots               BOOLEAN        = coalesce((params ->> 'kas_min_sots')::BOOLEAN, FALSE);
    l_round                            NUMERIC        = 0.01;
    kas_puhkuse_arvestus               boolean        = coalesce((params ->> 'kas_puhkus')::boolean, false); -- kui jah siis teeme 1 sm iga puhkuse operaatsoonile
    l_puhk_oper_id                     integer        = params ->> 'puhk_oper_id'; -- если делаем расчет для конкретной операции , например расчет налона на отпускные
    l_params                           JSON;
    v_tooleping                        RECORD;
    l_min_palk                         NUMERIC(12, 4) = 584; --alus arvestada sots.maks min palgast (2021)

    l_sotsmaks_min_palgast             NUMERIC(14, 4) = 0;
    l_enne_arvestatud_sotsmaks         NUMERIC(14, 4) = 0; -- summa, mis ole arvestatud koos tulu summaga, palk.oper.sotsmaks
    l_enne_arvestatud_sotsmaks_palgast NUMERIC(14, 4) = 0; -- summa, mis ole arvestatud koos tulu summaga, palk.oper.sotsmaks, va puhkus

    l_too_paevad                       INTEGER        = 30;
    l_puudu_paevad                     INTEGER        = 0;
    l_last_paev                        DATE           =
        (date(year(l_kpv), month(l_kpv), 1) + INTERVAL '1 month') :: DATE - 1;
    l_paevad_periodis                  INTEGER        = 30;
    l_min_sotsmaks_alus                NUMERIC(14, 4) = 0; -- основание для до расчет до мин. соц. налога
    l_ettemaksu_summa                  numeric(14, 4) = 0; -- сумма начислений с предоплатой по отпускгым
    l_start_day                        integer ;
    l_finish_day                       integer;
    l_calc_days                        integer;
    l_ettemaksu_oper_ids               jsonb          = '[]'::jsonb;
    l_alus_oper_ids                    jsonb          = '[]'::jsonb;

BEGIN

    IF l_alus_summa IS NULL
    THEN
        -- meil ei ole alus summa, vaja arvestada alus

        -- select lepinguandmed
        SELECT
            t.pohikoht,
            t.rekvid,
            t.algab,
            t.lopp,
            t.parentid
        INTO v_tooleping
        FROM
            palk.tooleping t
        WHERE
            t.id = l_lepingid;


        SELECT
            pk.summa,
            empty(pk.percent_ :: INTEGER),
            coalesce(pk.minsots, 0) AS minsots,
            coalesce(pc.minpalk, 0) AS minpalk,
            l.round
        INTO l_pk_summa, is_percent, l_min_sots, l_min_palk, l_round
        FROM
            palk.palk_kaart                       pk
                LEFT OUTER JOIN palk.palk_config  pc ON pc.rekvid = v_tooleping.rekvid
                INNER JOIN      palk.com_palk_lib l ON pk.libid = l.id
        WHERE
              pk.lepingid = l_lepingid
          AND libId = l_libId;


        IF coalesce(l_min_sots, 0) > 0 AND kas_arvesta_min_sots
        THEN
            -- расчет СН с мин. ЗП
            -- kontrollime enne arvestatud sotsmaks

            SELECT
                        sum(po.summa)
                        FILTER ( WHERE po.palk_liik :: TEXT = 'SOTSMAKS' AND (po.sotsmaks IS NULL OR po.sotsmaks = 0)),
                        sum(po.summa) FILTER ( WHERE po.palk_liik :: TEXT = 'ARVESTUSED' AND po.is_sotsmaks AND
                                                     right(rtrim(po.konto), 2) NOT IN ('21', '23', '24', '25')),
                        sum(po.sotsmaks) FILTER ( WHERE po.palk_liik :: TEXT = 'ARVESTUSED' AND po.is_sotsmaks AND
                                                        right(rtrim(po.konto), 2) NOT IN ('21', '23', '24', '25')),
                        sum(po.sotsmaks) FILTER ( WHERE po.palk_liik :: TEXT = 'ARVESTUSED'
                            AND po.is_sotsmaks
                            AND right(rtrim(po.konto), 2) NOT IN ('21', '23', '24', '25')
                            and coalesce(po.kas_ettemaks, false)
                            ),
                        jsonb_agg(po.doc_id) FILTER ( WHERE po.palk_liik :: TEXT = 'ARVESTUSED'
                            AND po.is_sotsmaks
                            AND right(rtrim(po.konto), 2) NOT IN ('21', '23', '24', '25')
                            and coalesce(po.kas_ettemaks, false)
                            ),
                        jsonb_agg(po.doc_id) FILTER ( WHERE po.palk_liik :: TEXT = 'ARVESTUSED'
                            AND po.is_sotsmaks
                            AND right(rtrim(po.konto), 2) NOT IN ('21', '23', '24', '25')
                            )
            INTO l_enne_arvestatud_sotsmaks, l_min_sotsmaks_alus, l_enne_arvestatud_sotsmaks_palgast, l_ettemaksu_summa, l_ettemaksu_oper_ids, l_alus_oper_ids
            FROM
                (
                    SELECT
                        p.summa,
                        p.sotsmaks,
                        p.konto,
                        p.kpv,
                        p.period,
                        (lib.properties :: JSONB ->> 'sots') :: BOOLEAN                                            AS is_sotsmaks,
                        ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT AS palk_liik,
                        p.lepingid,
                        (p.properties ->> 'kas_ettemaks')::boolean                                                 as kas_ettemaks,
                        p.parentid                                                                                 as doc_id
                    FROM
                        docs.doc                      d
                            INNER JOIN palk.palk_oper p ON p.parentid = d.id
                            INNER JOIN libs.library   lib ON p.libid = lib.id AND lib.library = 'PALK'
                            INNER JOIN palk.tooleping t ON p.lepingid = t.id
                ) po
            WHERE
                  year(po.kpv) = year(l_kpv)
              AND month(po.kpv) = month(l_kpv)
              AND po.period IS NULL
              AND po.lepingid IN (
                                     SELECT
                                         t.id
                                     FROM
                                         palk.tooleping t
                                     WHERE
                                           t.parentid = v_tooleping.parentid
                                       AND t.rekvid = v_tooleping.rekvId
                                 )
                  -- если задано ид операции
              and (po.doc_id = l_puhk_oper_id or l_puhk_oper_id is null);

            l_enne_arvestatud_sotsmaks = coalesce(l_enne_arvestatud_sotsmaks, 0);
            l_enne_arvestatud_sotsmaks_palgast = coalesce(l_enne_arvestatud_sotsmaks_palgast, 0);

            -- отсутствие на раб.месте
            -- params
            SELECT
                row_to_json(row)
            INTO l_params
            FROM
                (
                    SELECT
                        month(l_kpv) AS kuu,
                        year(l_kpv)  AS aasta,
                        TRUE         AS kas_kalendripaevad,
                        TRUE         AS puudumised,
                        l_lepingid   AS lepingid
                ) row;

            l_puudu_paevad = palk.get_puudumine(l_params :: JSONB);

            IF coalesce(l_puudu_paevad, 0) > 0
            THEN
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


            END IF;

            -- считаем календарные дни
            l_paevad_periodis =
                    palk.get_days_of_month_in_period(month(l_kpv), year(l_kpv), date(year(l_kpv), month(l_kpv), 01),
                                                     l_kpv);
            -- за вычитом отпуска и больничного
            l_paevad_periodis = l_paevad_periodis - l_puudu_paevad;
            IF l_puudu_paevad = 0
            THEN
                l_paevad_periodis = 30;
            END IF;

-- если не полный раб. месяц
            IF make_date(year(l_kpv), month(l_kpv), 01) < v_tooleping.algab OR
               l_kpv > coalesce(v_tooleping.lopp, l_kpv)
            THEN
                l_start_day = CASE
                                  WHEN make_date(year(l_kpv), month(l_kpv), 01) < v_tooleping.algab
                                      THEN day(v_tooleping.algab)
                                  else 1 end;

                l_finish_day = CASE
                                   WHEN l_kpv > coalesce(v_tooleping.lopp, l_kpv) THEN day(v_tooleping.lopp)
                                   ELSE day(l_kpv) END;

                l_calc_days = l_finish_day - l_start_day + 1;

                l_paevad_periodis = l_calc_days - l_puudu_paevad;

            END IF;

            IF NOT empty(l_min_sots) OR NOT empty(l_min_palk) AND
                                        (coalesce(l_min_sotsmaks_alus, 0) * l_pk_summa * 0.01) <
                                        (l_min_palk * l_min_sots * l_pk_summa * 0.01) --arvetsame sotsmaks min.palgast
            THEN

                -- 584* 0.33 с поправкой на дни
                IF (coalesce(l_puudu_paevad, 0) > 0 OR make_date(year(l_kpv), month(l_kpv), 01) < v_tooleping.algab OR
                    l_kpv > coalesce(v_tooleping.lopp, l_kpv)) AND NOT empty(l_min_palk) AND
                   (coalesce(l_min_sotsmaks_alus, 0) * l_pk_summa * 0.01) <
                   (l_min_palk * l_min_sots * l_pk_summa * 0.01)
                THEN
                    l_sotsmaks_min_palgast = ((l_min_palk * l_min_sots * l_pk_summa * 0.01) / 30 * (l_paevad_periodis));
                ELSE
                    l_sotsmaks_min_palgast = ((l_min_palk * l_min_sots * l_pk_summa * 0.01));
                END IF;

            ELSE
                -- отсутствий нет (Если работник не отсутствовал ни дня на работе, то не должно быть никаких расчетов по дням. Просто 192,72.)
                l_sotsmaks_min_palgast = ((l_min_palk * l_min_sots * l_pk_summa * 0.01));

            END IF;

            -- не может быть больше мин. соц. налога
            IF l_sotsmaks_min_palgast > (l_min_palk * l_min_sots * l_pk_summa * 0.01)
            THEN
                l_sotsmaks_min_palgast = (l_min_palk * l_min_sots * l_pk_summa * 0.01);
            END IF;

            IF l_sotsmaks_min_palgast > l_enne_arvestatud_sotsmaks_palgast -- Поправка 17.06.2022 . Берем в зачет только соц. налог без учета отпускных
            THEN

                -- считаем необходимую для до начисления сумму налога
                summa = l_sotsmaks_min_palgast - coalesce(l_enne_arvestatud_sotsmaks_palgast, 0);
                -- основа начисления соц. налога

                IF coalesce(l_puudu_paevad, 0) > 0 OR make_date(year(l_kpv), month(l_kpv), 01) < v_tooleping.algab OR
                   l_kpv > coalesce(v_tooleping.lopp, l_kpv)
                THEN
                    sm = f_round(l_min_palk / 30 * coalesce(l_paevad_periodis, 30) - coalesce(l_min_sotsmaks_alus, 0),
                                 l_round);
                ELSE
                    sm = f_round(l_min_palk - coalesce(l_min_sotsmaks_alus, 0), l_round);
                END IF;

                selg = 'lisa SM (' + l_min_palk::TEXT + '/30 * ' ||
                       coalesce(l_paevad_periodis, 30)::TEXT || '-' + coalesce(l_min_sotsmaks_alus, 0)::TEXT +
                                                                ') = ' + coalesce(sm, 0)::TEXT ||
                       '* 0.33 = ' || coalesce(summa, 0)::TEXT;

            ELSE
                -- не используем см с мин. ЗП
                summa = 0;
                sm = 0;
            END IF;


        ELSE

            -- обычный соц. налог
            with
                kontod as (
                              select
                                  unnest(pk.puhkused_kontod) as konto
                              from
                                  palk.palk_kulu_kontod pk
                              where
                                  kas_puhkuse_arvestus
                              union all
                              select
                                  unnest(pk.pohi_palk_kontod) as konto
                              from
                                  palk.palk_kulu_kontod pk
                              where
                                  not kas_puhkuse_arvestus
                              union all
                              select
                                  unnest(pk.huvitised_kontod) as konto
                              from
                                  palk.palk_kulu_kontod pk
                              where
                                  not kas_puhkuse_arvestus
                              union all
                              select
                                  unnest(pk.koolitus_kontod) as konto
                              from
                                  palk.palk_kulu_kontod pk
                              where
                                  not kas_puhkuse_arvestus
                              union all
                              select
                                  unnest(pk.lisa_tasud_kontod) as konto
                              from
                                  palk.palk_kulu_kontod pk
                              where
                                  not kas_puhkuse_arvestus
                              union all
                              select
                                  unnest(pk.muud_lisa_tasud_kontod) as konto
                              from
                                  palk.palk_kulu_kontod pk
                              where
                                  not kas_puhkuse_arvestus
                              union all
                              select
                                  unnest(pk.preemiad_kontod) as konto
                              from
                                  palk.palk_kulu_kontod pk
                              where
                                  not kas_puhkuse_arvestus
                              union all
                              select
                                  unnest(pk.vola_kontod) as konto
                              from
                                  palk.palk_kulu_kontod pk
                              where
                                  not kas_puhkuse_arvestus
                              union all
                              select
                                  'tyhi_konto' as konto
                              from
                                  palk.palk_kulu_kontod pk
                              where
                                  not kas_puhkuse_arvestus
                          ),
                eri_po_ids as (
                              select
                                  po.properties -> 'alus_oper_ids' as alus_oper_ids
                              from
                                  palk.palk_oper po
                              where
                                    po.kpv = l_kpv
                                AND po.rekvid = v_tooleping.rekvid
                                AND po.lepingId = l_lepingid
                                and coalesce((po.properties ->> 'kas_eri_arvestus')::boolean, false)
                          )


            SELECT
                sum(po.sotsmaks)                                                 AS sotsmaks,
                sum(po.summa),
                sum(po.sotsmaks) filter (where coalesce(po.kas_ettemaks, false)) as ettemaks,
                json_agg(po.doc_id) filter (where coalesce(po.kas_ettemaks, false)),
                jsonb_agg(po.doc_id)                                             as alus_oper_ids
            INTO summa, l_alus_summa, l_ettemaksu_summa, l_ettemaksu_oper_ids, l_alus_oper_ids
            FROM
                (
                    SELECT
                        p.summa,
                        p.sotsmaks,
                        p.konto,
                        p.kpv,
                        p.rekvid,
                        p.libid,
                        p.period,
                        (lib.properties :: JSONB ->> 'sots') :: BOOLEAN                                            AS is_sotsmaks,
                        ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT AS palk_liik,
                        p.lepingid,
                        (p.properties ->> 'kas_ettemaks')::boolean                                                 as kas_ettemaks,
                        d.id                                                                                       as doc_id
                    FROM
                        docs.doc                      d
                            INNER JOIN palk.palk_oper p ON p.parentid = d.id
                            INNER JOIN libs.library   lib ON p.libid = lib.id AND lib.library = 'PALK'
                            INNER JOIN palk.tooleping t ON p.lepingid = t.id
                )                           po
                    INNER JOIN libs.library l ON l.id = po.libid
            WHERE
                  po.kpv = l_kpv
              AND po.rekvid = v_tooleping.rekvId
              AND po.lepingId = l_lepingid
              AND po.palk_liik = 'ARVESTUSED'
                  -- оставим только нужные операции (отпусные или зарплатные)
              and coalesce(po.konto, 'tyhi_konto') in (
                                                          select
                                                              konto
                                                          from
                                                              kontod
                                                      )
              AND po.period IS NULL
              AND po.sotsmaks IS NOT NULL
                  -- за исключение отдельного расчета
              and po.doc_id not in (
                                       select
                                           jsonb_array_elements(eri.alus_oper_ids)::integer
                                       from
                                           eri_po_ids eri
                                       where eri.alus_oper_ids is not null
                                   )
            -- если задано ид операции
            and (po.doc_id = l_puhk_oper_id or l_puhk_oper_id is null);


            selg = 'Enne arvestatud SM ' || summa::TEXT || ', alus ' || l_alus_summa::TEXT;

        END IF;

    ELSE
        -- arvestus
        summa = l_alus_summa * l_pk_summa * 0.01;
        selg = l_alus_summa :: TEXT || ' * ' || (l_pk_summa * 0.01) :: TEXT;

    END IF;

    summa = coalesce(f_round(summa, l_round), 0);
    ettemaksu_summa = l_ettemaksu_summa;
    ettemaksu_oper_ids = l_ettemaksu_oper_ids;
    alus_oper_ids = l_alus_oper_ids;

    l_params = to_jsonb(row.*)
               FROM
                   (
                       SELECT
                           NULL                   AS doc_id,
                           'Õnnestus'             AS error_message,
                           0::INTEGER             AS error_code,
                           summa                  AS summa,
                           selg                   AS selg,
                           sm:: NUMERIC           AS sm,
                           l_sotsmaks_min_palgast AS sotsmaks_min_palgast,
                           l_ettemaksu_summa      as ettemaksu_summa
                   ) row;
    data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

    RETURN;

END;

$$;

/*select *
from palk.sp_calc_sots(2477, '{
  "lepingid": 27377,
  "libid": 145911,
  "kpv": "2025-07-31",
  "kas_min_sots": false,
  "kas_puhkus": true,
  "puhk_oper_id": 7208725
}'::JSON)
*/


/*
SELECT *
FROM palk.sp_calc_sots_(70, '        {
  "lepingid": 31001,
  "libid": 146704,
  "kpv": 20210531,
  "kas_min_sots": true
}'::JSON)



 */