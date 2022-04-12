-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_loe_tasu(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.sp_loe_tasu_(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_loe_tasu(IN l_tasu_id INTEGER, IN l_user_id INTEGER,
                                            OUT error_code INTEGER,
                                            OUT result INTEGER,
                                            OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_tasu_jaak NUMERIC; -- остаток оплаты
    l_tasu      NUMERIC; -- сумма оплаты
    v_arv       RECORD;
    v_tasu      RECORD;
BEGIN
    -- расчет сальдо платежа
    l_tasu_jaak = docs.sp_update_mk_jaak(l_tasu_id);

    IF coalesce(l_tasu_jaak, 0) > 0
    THEN

        -- load tasu data
        SELECT mk.id,
               d.rekvid,
               (regexp_replace(viitenr, '[^0-9]', ''))::TEXT                    AS viitenr,
               (SELECT sum(summa) FROM docs.mk1 mk1 WHERE mk1.parentid = mk.id) AS summa,
               jaak,
               case when mk.opt = 1 then 'VM' else 'SM' end as liik
               INTO v_tasu
        FROM docs.doc D
                 INNER JOIN docs.mk mk ON mk.parentid = D.id
                 INNER JOIN lapsed.liidestamine l ON l.docid = d.id
        WHERE d.id = l_tasu_id;

        IF v_tasu IS NULL
        THEN
            -- нет связи, вызодим
            result = 0;
            error_message = 'laps ei leidnud';
            RETURN;
        END IF;

        --l_tasu_jaak = v_tasu.jaak;
        -- иницивлизируем = сумме остатка платежа

        -- ищем неоплаченные счета (по аналогии с выпиской)
        FOR v_arv IN
            SELECT a.id,
                   a.jaak,
                   a.rekvid,
                   a.asutusid,
                   a.asutus AS maksja
            FROM lapsed.cur_laste_arved a
                     INNER JOIN docs.arv arv ON a.id = arv.parentid
            WHERE a.rekvid = v_tasu.rekvid
              AND ltrim(rtrim((regexp_replace(a.viitenr, '[^0-9]', ''))))::TEXT =
                  ltrim(rtrim((regexp_replace(v_tasu.viitenr, '[^0-9]', ''))))::TEXT
              AND a.jaak > 0
--      AND a.jaak = v_tasu.summa
              AND (arv.properties ->> 'ettemaksu_period' IS NULL OR
                   arv.properties ->> 'tyyp' = 'ETTEMAKS') -- только обычные счета или предоплаты
            and liik = case when v_tasu.liik = 'VM' then 1 else 0 end -- при выплате ищем входящие счета или наоборот
            ORDER BY a.kpv, a.id
            LOOP
                -- списываем в оплату сальдо счета (только остаток счета)
                IF v_arv.jaak >= l_tasu_jaak
                THEN
                    -- в оплату пошел остаток платежа
                    l_tasu = l_tasu_jaak;
                ELSE
                    --в оплату пошел сальдо счета
                    l_tasu = v_arv.jaak;
                END IF;

                -- вызывает оплату
                result = docs.sp_tasu_arv(l_tasu_id, v_arv.id, l_user_id, l_tasu);

                IF result IS NOT NULL AND result > 0
                THEN
                    -- минусуем сумму оплаты
                    l_tasu_jaak = l_tasu_jaak - l_tasu;
                END IF;

                if l_tasu_jaak = 0 THEN
                    -- если оплата выбрана, то выходим
                    
                    exit;
                END IF;
            END LOOP;

    END IF;
    raise notice 'l_tasu_jaak  %', l_tasu_jaak;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_loe_tasu(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_tasu(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_tasu(INTEGER, INTEGER) TO arvestaja;

COMMENT ON FUNCTION docs.sp_loe_tasu(INTEGER, INTEGER) IS 'производит поиск неоплаченных счетов и вызывает процедуру их оплаты';

/*
SELECT *
FROM  docs.sp_loe_tasu_(2299754::INTEGER, 28::INTEGER);

select * from ou.userid where id = 70
*/