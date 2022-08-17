-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_viitenr(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_viitenr(IN user_id INTEGER,
                                                    IN doc_id INTEGER,
                                                    OUT error_code INTEGER,
                                                    OUT result INTEGER,
                                                    OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc         RECORD;
    json_ajalugu  JSONB;
    l_old_viitenr TEXT;
    v_teenused    RECORD;

BEGIN

    SELECT v.*,
           u.ametnik::TEXT                       AS kasutaja,
           (u.roles ->> 'is_arvestaja')::BOOLEAN AS is_arvestaja
    INTO v_doc
    FROM lapsed.viitenr v
             JOIN ou.userid u ON u.id = user_id
    WHERE v.id = doc_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF (v_doc.kasutaja IS NULL
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud: ' || ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


    --	ids =  v_doc.rigths->'delete';
    IF (v_doc.is_arvestaja IS NULL OR NOT v_doc.is_arvestaja)
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление %, doc_id %, user_id %',v_doc.is_arvestaja , doc_id, user_id;
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;

    -- запоминаем старый (прежний) код
    l_old_viitenr = (SELECT viitenumber FROM lapsed.viitenr WHERE id = doc_id LIMIT 1);

    DELETE
    FROM lapsed.viitenr
    WHERE id = doc_id;

    -- проверить в карточках услуг витенумберов
    FOR v_teenused IN
        SELECT lk.id
        FROM lapsed.lapse_kaart lk
                 INNER JOIN lapsed.laps l ON l.id = lk.parentid
        WHERE lk.rekvid = v_doc.rekv_id
          AND l.isikukood = v_doc.isikukood
          AND lk.staatus < 3
          AND (lk.properties ->> 'viitenr' IS NOT NULL AND (lk.properties ->> 'viitenr')::TEXT = l_old_viitenr)
        LOOP
            UPDATE lapsed.lapse_kaart
            SET properties = properties::JSONB || jsonb_build_object('viitenr', NULL)
            WHERE id = v_teenused.id;

        END LOOP;


    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_viitenr(INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_viitenr(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_viitenr(INTEGER, INTEGER) TO dbpeakasutaja;


/*
select lapsed.sp_delete_laps(70,1)

select * from lapsed.laps
 */