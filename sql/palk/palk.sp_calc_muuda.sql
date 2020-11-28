DROP FUNCTION IF EXISTS sp_calc_muuda(INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.sp_calc_muuda(params JSONB);
DROP FUNCTION IF EXISTS palk.sp_calc_muuda(user_id INTEGER, params JSONB);
DROP FUNCTION IF EXISTS palk.sp_calc_muuda(user_id INTEGER, params JSON);

CREATE FUNCTION palk.sp_calc_muuda(user_id INTEGER, params JSON,
                                   OUT summa NUMERIC,
                                   OUT selg TEXT,
                                   OUT error_code INTEGER,
                                   OUT result INTEGER,
                                   OUT error_message TEXT,
                                   OUT data JSONB)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_lepingid   INTEGER = params ->> 'lepingid';
    l_libId      INTEGER = params ->> 'libid';
    l_kpv        DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_alus_summa NUMERIC = params ->> 'alus_summa';
    l_pk_summa   NUMERIC = coalesce((params ->> 'summa') :: NUMERIC, 0.8); -- default TKA
    is_percent   BOOLEAN = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                    TRUE); -- kas pk summa percentis (33%)
    l_asutusest  INTEGER = coalesce((params ->> 'asutusest') :: INTEGER, 1);
    l_liik       INTEGER = coalesce((params ->> 'liik') :: INTEGER,
                                    array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS'));
    l_round      NUMERIC = 0.01;

    v_tulemus    RECORD;
    l_enter      TEXT    = '(r)';
    l_params     JSONB;
BEGIN

    IF l_alus_summa IS NULL
    THEN
        selg = coalesce(selg, '') || 'sql' || l_enter;
        --load metadata
        SELECT p.summa,
               p.asutusest,
               p.liik,
               l.round,
               NOT empty(p.percent_ :: INTEGER)
               INTO l_pk_summa, l_asutusest, l_liik, l_round, is_percent
        FROM palk.com_palk_kaart p
                 INNER JOIN palk.com_palk_lib l ON p.libid = l.id
            WHERE p.lepingid = l_lepingid
                 AND p.libId = l_libId;

    END IF;

    IF l_alus_summa IS NULL
    THEN
        IF is_percent
        THEN -- считаем в процентах от брутто зп
            SELECT sum(coalesce(tka, 0))       AS tka,
                   sum(coalesce(tootumaks, 0)) AS tki,
                   sum(coalesce(pensmaks, 0))  AS pm
                   INTO v_tulemus
            FROM palk.cur_palkoper po
                WHERE lepingid = l_lepingid
                     AND kpv = l_kpv
                     AND liik = '+';
            CASE
                WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
                    AND empty(l_asutusest)
                    THEN
                        summa = v_tulemus.tki;
                WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'TÖÖTUSKINDLUSTUSMAKS')
                    AND NOT empty(l_asutusest)
                    THEN
                        summa = v_tulemus.tka;
                WHEN l_liik = array_position((enum_range(NULL :: PALK_LIIK)), 'PENSIONIMAKS')
                    THEN
                        summa = f_round(v_tulemus.pm, l_round);
                END CASE;

            selg = coalesce(selg, '') || 'ennearvestatud maksud ' || summa::TEXT || l_enter;
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
               FROM (
                        SELECT NULL       AS doc_id,
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
select * from palk.sp_calc_muuda(1, '{"lepingid":4, "libid":386, "kpv":"2018-04-09"}'::JSON)
select * from palk.sp_calc_muuda(1, '{"alus_summa":100}'::JSON)
select * from palk.sp_calc_muuda(1, '{"alus_summa":100, "summa":2}'::JSON)
select * from palk.sp_calc_muuda(1, '{"alus_summa":0, "summa":100, "is_percent":false}'::JSON)
select * from palk.sp_calc_muuda(1, '{"lepingid":4,"libid":529,"kpv":20180501}'::JSON)

 */