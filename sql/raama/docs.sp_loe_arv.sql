DROP FUNCTION IF EXISTS docs.sp_loe_arv(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_loe_arv(IN l_arv_id INTEGER, IN l_user_id INTEGER,
                                           OUT error_code INTEGER,
                                           OUT result INTEGER,
                                           OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_arv_jaak NUMERIC; -- остаток оплаты
    l_tasu     NUMERIC; -- сумма оплаты
    v_mk       RECORD;
    v_arve     RECORD;
BEGIN
    -- расчет сальдо счета
    l_arv_jaak = docs.sp_update_arv_jaak(l_arv_id);

    IF coalesce(l_arv_jaak, 0) > 0
    THEN

        -- load tasu data
        SELECT d.id,
               d.rekvid,
               arv.summa  AS summa,
               arv.jaak,
               l.parentid AS laps_id,
               arv.liik
               INTO v_arve
        FROM docs.doc D
                 INNER JOIN docs.arv arv ON arv.parentid = D.id
                 INNER JOIN lapsed.liidestamine l ON l.docid = d.id
        WHERE d.id = l_arv_id;

        IF v_arve IS NULL
        THEN
            -- нет связи, вызодим
            result = 0;
            error_message = 'laps ei leidnud';
            RETURN;
        END IF;

        -- ищем не распределенные оплаты
        FOR v_mk IN
            SELECT mk.id,
                   mk.jaak,
                   mk.rekvid,
                   mk,
                   maksja_id,
                   mk.asutus AS maksja
            FROM lapsed.cur_lapsed_mk mk
            WHERE mk.rekvid = v_arve.rekvid
              AND mk.laps_id = v_arve.laps_id
              AND mk.jaak > 0
            ORDER BY MK.kpv ASC
            LOOP
                -- списываем в оплату сальдо счета (только остаток счета)
                IF l_arv_jaak >= v_mk.jaak
                THEN
                    -- в оплату пошел остаток платежа
                    l_tasu = v_mk.jaak;
                ELSE
                    --в оплату пошел сальдо счета
                    l_tasu = l_arv_jaak;
                END IF;

                -- вызывает оплату
                -- l_tasu_id integer, l_arv_id integer,
                result = docs.sp_tasu_arv(v_mk.id, v_arve.id, l_user_id, l_tasu);

                IF result IS NOT NULL AND result > 0
                THEN
                    -- минусуем сумму оплаты
                    l_arv_jaak = l_arv_jaak - l_tasu;
                END IF;
                
                -- если оплата счета списана, но выходим из цикла
                IF l_arv_jaak = 0
                THEN
                    EXIT;
                END IF;
            END LOOP;

    END IF;
    
    return;
    
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_loe_arv(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_arv(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_arv(INTEGER, INTEGER) TO arvestaja;

COMMENT ON FUNCTION docs.sp_loe_arv(INTEGER, INTEGER) IS 'производит поиск неоплаченных счетов и вызывает процедуру их оплаты';

/*
SELECT *
FROM  docs.sp_loe_tasu_(2299754::INTEGER, 28::INTEGER);

select * from ou.userid where id = 70
*/