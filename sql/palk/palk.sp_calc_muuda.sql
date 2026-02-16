DROP FUNCTION IF EXISTS sp_calc_muuda(INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.sp_calc_muuda(params JSONB);
DROP FUNCTION IF EXISTS palk.sp_calc_muuda(user_id INTEGER, params JSONB);
DROP FUNCTION IF EXISTS palk.sp_calc_muuda(user_id INTEGER, params JSON);

CREATE FUNCTION palk.sp_calc_muuda(user_id INTEGER, params JSON,
                                   OUT summa NUMERIC,
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
    l_lepingid           INTEGER = params ->> 'lepingid';
    l_libId              INTEGER = params ->> 'libid';
    l_kpv                DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_alus_summa         NUMERIC = params ->> 'alus_summa';
    l_pk_summa           NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, 0.8); -- default TKA
    is_percent           BOOLEAN = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                            TRUE); -- kas pk summa percentis (33%)
    l_asutusest          INTEGER = coalesce((params ->> 'asutusest') :: INTEGER, 1);
    l_liik               INTEGER = coalesce((params ->> 'liik') :: INTEGER,
                                            array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS'));
    kas_puhkuse_arvestus boolean = coalesce((params ->> 'kas_puhkus')::boolean, false); -- kui jah siis teeme 1 sm iga puhkuse operaatsoonile
    l_puhk_oper_id       integer = params ->> 'puhk_oper_id'; -- если делаем расчет для конкретной операции , например расчет налона на отпускные

    l_round              NUMERIC = 0.01;
    v_tulemus            RECORD;
    l_enter              TEXT    = '(r)';
    l_params             JSONB;
BEGIN

    IF l_alus_summa IS NULL
    THEN
        selg = coalesce(selg, '') || 'sql' || l_enter;
        --load metadata
        SELECT
            p.summa,
            p.asutusest,
            p.liik,
            l.round,
            NOT empty(p.percent_ :: INTEGER)
        INTO l_pk_summa, l_asutusest, l_liik, l_round, is_percent
        FROM
            palk.com_palk_kaart              p
                INNER JOIN palk.com_palk_lib l ON p.libid = l.id
        WHERE
              p.lepingid = l_lepingid
          AND p.libId = l_libId;

    END IF;

    IF l_alus_summa IS NULL
    THEN
        IF is_percent
        THEN -- считаем в процентах от брутто зп
            SELECT
                sum(coalesce(tka, 0))                                               AS tka,
                sum(coalesce(tootumaks, 0))                                         AS tki,
                sum(coalesce(pensmaks, 0))                                          AS pm,
                sum(po.tka) filter (where coalesce(po.kas_ettemaks, false))         as tka_ettemaks,
                json_agg(po.doc_id) filter (where coalesce(po.kas_ettemaks, false)) as ettemaksu_oper_ids,
                jsonb_agg(po.doc_id)                                                as alus_oper_ids

            INTO v_tulemus
            FROM
                (
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
                                        AND po.lepingId = l_lepingid
                                        and coalesce((po.properties ->> 'kas_eri_arvestus')::boolean, false)
                                        and (l_puhk_oper_id is null or po.parentid <> l_puhk_oper_id)
                                  )

                    SELECT
                        p.summa,
                        d.id                                                                  as doc_id,
                        p.tka,
                        p.tootumaks,
                        p.pensmaks,
                        p.sotsmaks,
                        p.konto,
                        p.kpv,
                        p.tulubaas,
                        p.period,
                        p.lepingid,
                        p.id,
                        ((enum_range(NULL :: PALK_OPER_LIIK))[CASE ((lib.properties :: JSONB ->> 'liik') ||
                                                                    (lib.properties :: JSONB ->> 'asutusest')) :: TEXT
                                                                  WHEN '10'
                                                                      THEN 1
                                                                  WHEN '20'
                                                                      THEN 2
                                                                  WHEN '40'
                                                                      THEN 2
                                                                  WHEN '70'
                                                                      THEN 2
                                                                  WHEN '71'
                                                                      THEN 3
                                                                  WHEN '80'
                                                                      THEN 2
                                                                  WHEN '60'
                                                                      THEN 2
                                                                  ELSE 3 END]) :: VARCHAR(20) AS liik,
                        (p.properties ->> 'kas_ettemaks')::boolean                            as kas_ettemaks
                    FROM
                        docs.doc                      d
                            INNER JOIN palk.palk_oper p ON p.parentid = d.id
                            INNER JOIN libs.library   lib ON p.libid = lib.id AND lib.library = 'PALK'
                            INNER JOIN palk.tooleping t ON p.lepingid = t.id
                    WHERE
                          lepingid = l_lepingid
                      AND kpv = l_kpv
                          -- оставим только нужные операции (отпусные или зарплатные)
                      and coalesce(p.konto, 'tyhi_konto') in (
                                                                 select
                                                                     konto
                                                                 from
                                                                     kontod
                                                             )
/*                          -- за исключение отдельного расчета
                      and p.parentid not in (
                                                select
                                                    jsonb_array_elements(eri.alus_oper_ids)::integer
                                                from
                                                    eri_po_ids eri
                                            )
*/
                ) po
            WHERE
                  liik = '+'
                  -- если задано ид операции
              and (po.doc_id = l_puhk_oper_id or coalesce(l_puhk_oper_id, 0) = 0);

            CASE
                WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
                    AND empty(l_asutusest)
                    THEN summa = v_tulemus.tki;
                WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
                    AND NOT empty(l_asutusest)
                    THEN summa = v_tulemus.tka;
                WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'PENSIONIMAKS')
                    THEN summa = f_round(v_tulemus.pm, l_round);
                END CASE;

            selg = coalesce(selg, '') || 'ennearvestatud maksud ' || summa::TEXT || l_enter;
            ettemaksu_summa = v_tulemus.tka_ettemaks;
            ettemaksu_oper_ids = v_tulemus.ettemaksu_oper_ids;
            alus_oper_ids = v_tulemus.alus_oper_ids;

        END IF;
    ELSE
        IF is_percent
        THEN
            summa = f_round(l_alus_summa * 0.01 * l_pk_summa, l_round);
            selg = coalesce(selg, '') || 'arvestus ' || l_alus_summa :: TEXT || '* 0.01 * ' || l_pk_summa :: TEXT ||
                   '%' || l_enter;
        END IF;
    END IF;

    IF NOT is_percent
    THEN
        summa = f_round(l_pk_summa, l_round);
        selg = coalesce(selg, '') || 'pk summa ' || l_pk_summa :: TEXT || l_enter;
    END IF;
    summa = coalesce(summa, 0);

    result = 1;
    l_params = to_jsonb(row.*)
               FROM
                   (
                       SELECT
                           NULL       AS doc_id,
                           'Õnnestus' AS error_message,
                           0::INTEGER AS error_code,
                           summa      AS summa,
                           selg       AS selg
                   ) row;
    data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

    RETURN;
END;
$$;

/*

select *
from
    palk.sp_calc_muuda(2477, jsonb_build_object('kpv', '2025-07-31', 'rekvid', 63, 'lepingid', 27377, 'libid', 145915,
                                                'puhk_oper_id', 7208725, 'kas_puhkus', true)::json)
select * from palk.sp_calc_muuda(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSON)
select * from palk.sp_calc_muuda(1, '{"alus_summa":100}'::JSON)
select * from palk.sp_calc_muuda(1, '{"alus_summa":100, "summa":2}'::JSON)
select * from palk.sp_calc_muuda(1, '{"alus_summa":0, "summa":100, "is_percent":false}'::JSON)
select * from palk.sp_calc_muuda(1, '{"lepingid":4,"libid":529,"kpv":20180501}'::JSON)

 */