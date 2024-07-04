DROP FUNCTION IF EXISTS docs.pv_umberklassifitseerimine(INTEGER);

CREATE OR REPLACE FUNCTION docs.pv_umberklassifitseerimine(
    pv_oper_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_pv_oper      RECORD;
    l_params       JSONB;
    l_uus_grupp_id INTEGER;
    l_vea_teatis   TEXT;
    l_kulum_konto  TEXT;
BEGIN

    SELECT po.*,
           l.properties::JSONB ->> 'konto'      AS pv_kaart_konto,
           l.properties::JSONB ->> 'korr_konto' AS korr_konto,
           l.properties::JSONB ->> 'gruppid'    AS gruppid,
           po.properties ->> 'korr_konto'       AS po_korr_konto,
           po.properties ->> 'kulum_konto'      AS po_kulum_konto,
           d.rekvid
    INTO v_pv_oper
    FROM docs.pv_oper po
             INNER JOIN docs.doc d ON d.id = po.parentid
             INNER JOIN libs.library l ON l.id = po.pv_kaart_id
    WHERE d.id = pv_oper_id;

    -- ищем группу ОС, в которую переходим
    IF v_pv_oper.konto = '154000'
    THEN
        l_uus_grupp_id = (SELECT l.id
                          FROM libs.library l
                          WHERE rekvid = v_pv_oper.rekvid
                            AND library = 'PVGRUPP'
                            AND status < 3
                            AND properties::JSONB ->> 'konto' = ltrim(rtrim(v_pv_oper.konto))
                            AND l.nimetus ILIKE
                                CASE
                                    WHEN coalesce(v_pv_oper.pv_kaart_konto, '') = '155000' THEN '%maa%'
                                    WHEN coalesce(v_pv_oper.pv_kaart_konto, '') = '155101' THEN '%korterid%'
                                    WHEN coalesce(v_pv_oper.pv_kaart_konto, '') = '155100' THEN '%hoone%'
                                    ELSE '%'
                                    END
                            AND (l.properties::JSONB ->> 'valid' IS NULL OR
                                 (l.properties::JSONB ->> 'valid')::DATE > current_date)
                          ORDER BY l.id DESC
                          LIMIT 1);
    ELSE
        l_uus_grupp_id = (SELECT l.id
                          FROM libs.library l
                          WHERE rekvid = v_pv_oper.rekvid
                            AND library = 'PVGRUPP'
                            AND status < 3
                            AND properties::JSONB ->> 'konto' = ltrim(rtrim(v_pv_oper.konto))
                            AND (l.properties::JSONB ->> 'valid' IS NULL OR
                                 (l.properties::JSONB ->> 'valid')::DATE > current_date)
                          ORDER BY l.id DESC
                          LIMIT 1);

    END IF;


    IF l_uus_grupp_id IS NULL
    THEN
        l_vea_teatis = 'PV grupp, kus konto on ' || v_pv_oper.konto || ' ei leidnud';
        RAISE EXCEPTION 'Viga %',l_vea_teatis;
    END IF;

    -- параметры
    l_params =
            jsonb_build_object('konto', v_pv_oper.konto, 'gruppid', l_uus_grupp_id, 'prev_gruppid', v_pv_oper.gruppid,
                               'prev_konto', v_pv_oper.pv_kaart_konto);


    --kor_konto
    IF v_pv_oper.konto = '154000'
    THEN
        v_pv_oper.korr_konto = v_pv_oper.pv_kaart_konto;
        -- переводим из инвестиций
        -- ищем конто износа
        l_kulum_konto = (SELECT (grupp.properties :: JSONB ->> 'kulum_konto') :: TEXT AS kulum_konto
                         FROM libs.library grupp
                         WHERE grupp.id = v_pv_oper.gruppid :: INTEGER);


    ELSE
        v_pv_oper.korr_konto = v_pv_oper.konto;
        l_kulum_konto = (SELECT (grupp.properties :: JSONB ->> 'kulum_konto') :: TEXT AS kulum_konto
                         FROM libs.library grupp
                         WHERE grupp.id = l_uus_grupp_id :: INTEGER);

    END IF;

    -- сохраняем корр счет
    l_params = l_params ||
               jsonb_build_object('korr_konto', v_pv_oper.korr_konto, 'konto', v_pv_oper.konto, 'kulum_konto',
                                  l_kulum_konto);

    -- меняем кор.счет учрета карточки ОС

    UPDATE libs.library
    SET properties = properties::JSONB || l_params
    WHERE id = v_pv_oper.pv_kaart_id;

    -- сохраним кор.счета в операции
    IF v_pv_oper.po_korr_konto IS NULL
    THEN
        -- новая операция, сохраняем параметры
        UPDATE docs.pv_oper
        SET properties = coalesce(properties, '{}'::JSONB)::JSONB ||
                         jsonb_build_object('korr_konto', v_pv_oper.korr_konto, 'prev_grupp_id', v_pv_oper.gruppid,
                                            'grupp_id', l_uus_grupp_id, 'kulum_konto', l_kulum_konto, 'konto',
                                            v_pv_oper.pv_kaart_konto)
        WHERE parentid = pv_oper_id;
    END IF;

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