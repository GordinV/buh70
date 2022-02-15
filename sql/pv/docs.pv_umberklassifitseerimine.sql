DROP FUNCTION IF EXISTS docs.pv_umberklassifitseerimine(INTEGER);

CREATE OR REPLACE FUNCTION docs.pv_umberklassifitseerimine(
    pv_oper_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_pv_oper  RECORD;
    l_params   JSONB;
    l_pv_konto TEXT;
BEGIN

    SELECT po.*, l.properties::JSONB ->> 'konto' AS korr_konto
    INTO v_pv_oper
    FROM docs.pv_oper po
             INNER JOIN docs.doc d ON d.id = po.parentid
             INNER JOIN libs.library l ON l.id = po.pv_kaart_id
    WHERE d.id = pv_oper_id;
    -- параметры
    l_params = jsonb_build_object('konto', v_pv_oper.konto);

    IF v_pv_oper.konto = '154000'
    THEN
        -- сохраняем корр счет
        l_params = l_params || jsonb_build_object('korr_konto', v_pv_oper.korr_konto);
    END IF;

    -- меняем кор.счет учрета карточки ОС

    UPDATE libs.library
    SET properties = properties::JSONB || l_params
    WHERE id = v_pv_oper.pv_kaart_id;

    RETURN 1;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.pv_umberklassifitseerimine(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.pv_umberklassifitseerimine(INTEGER) TO dbpeakasutaja;

/*
SELECT docs.pv_umberklassifitseerimine(2362123);

*/