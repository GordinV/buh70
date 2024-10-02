DROP FUNCTION IF EXISTS docs.makse_umber_jaotada(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.makse_umber_jaotada_(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.makse_umber_jaotada(IN user_id INTEGER,
                                                     IN doc_id INTEGER,
                                                     IN liik INTEGER DEFAULT 0,
                                                     OUT error_code INTEGER,
                                                     OUT result INTEGER,
                                                     OUT doc_type_id TEXT,
                                                     OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    v_tulemus RECORD;
    v_tasud   RECORD;
    l_summa   NUMERIC = 0;
    l_opt     INTEGER;
BEGIN
    doc_type_id = 'SMK';

    -- удаляем старые оплаты
    FOR v_tasud IN
        SELECT * FROM docs.arvtasu WHERE doc_tasu_id = doc_id
        LOOP
            DELETE FROM docs.arvtasu WHERE id = v_tasud.id;
            IF v_tasud.pankkassa = 4
            THEN
                -- пересчет сальдо платежа возврата
                PERFORM docs.sp_update_mk_jaak(v_tasud.doc_arv_id);
            END IF;
        END LOOP;

    IF empty(liik)
    THEN
        SELECT sum(mk1.summa) AS summa, mk.opt
        INTO l_summa, l_opt
        FROM docs.mk mk
                 INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
        WHERE mk.parentid = doc_id
        GROUP BY opt;

        -- ищем счета

        IF coalesce(l_summa, 0) < 0 AND l_opt <> 1
        THEN
            -- перенос платежа
raise notice 'start перенос платежа l_summa %, l_opt %', l_summa, l_opt;
            SELECT *
            INTO v_tulemus
            FROM docs.sp_loe_tagasimakse(doc_id, user_id);
        ELSIF l_opt = 1 AND coalesce(l_summa, 0) > 0
        THEN
            -- возврат
            SELECT *
            INTO v_tulemus
            FROM docs.sp_loe_tagasimakse(doc_id, user_id);
        ELSE
            SELECT *
            INTO v_tulemus
            FROM docs.sp_loe_tasu(doc_id, user_id) t;

        END IF;

        result = coalesce(v_tulemus.result, doc_id);
    ELSE
        result = 1;
    END IF;
    RAISE NOTICE 'error_code %, result %, error_message %',error_code,result, error_message;

    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.makse_umber_jaotada(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.makse_umber_jaotada(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;


/*
SELECT * from docs.makse_umber_jaotada(5422, 5956146, 1)

select * FROM docs.arvtasu WHERE doc_tasu_id in( 5426570)
or doc_arv_id in ( 5157151, 5213784)
;

delete from docs.arvtasu where doc_tasu_id = 5426570

id
296313
296314

select * from docs.arvtasu where doc_tasu_id < 5410
*/