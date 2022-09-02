-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_lapse_kaart(IN user_id INTEGER,
                                                        IN doc_id INTEGER,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc        RECORD;
    json_ajalugu JSONB;
    DOC_STATUS   INTEGER = 3; -- документ удален
    l_count      INTEGER;
BEGIN

    SELECT lk.*,
           u.ametnik::TEXT                       AS kasutaja,
           (u.roles ->> 'is_arvestaja')::BOOLEAN AS is_arvestaja,
           (lk.properties ->> 'lopp_kpv')::DATE  AS lopp_kpv,
           (lk.properties ->> 'alg_kpv')::DATE   AS alg_kpv,
           (lk.properties ->> 'yksus')           AS yksus
    INTO v_doc
    FROM lapsed.lapse_kaart lk
             JOIN ou.userid u ON u.id = user_id
    WHERE lk.id = doc_id;

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
        RAISE NOTICE 'У пользователя нет прав на удаление';
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;

    --удаление - нельзя удалять услугу, если на нее оформлены дневные табеля
    SELECT count(id)
    INTO l_count
    FROM lapsed.lapse_kaart lk
    WHERE lk.parentid = v_doc.parentid
      AND lk.nomid = v_doc.nomid
      AND lk.properties ->> 'yksus' = v_doc.yksus
      AND lk.staatus < 3;

-- если услуг более 1, проверка не осуществляется
    IF coalesce(l_count, 0) < 2 AND exists((SELECT dt.id
                                            FROM lapsed.day_taabel dt
                                                     INNER JOIN lapsed.day_taabel1 dt1 ON dt.id = dt1.parent_id
                                                     INNER JOIN libs.library l ON l.id = dt.grupp_id
                                            WHERE dt1.laps_id = v_doc.parentid
                                              AND dt1.nom_id = v_doc.nomid
                                              AND ltrim(rtrim(v_doc.yksus)) = ltrim(rtrim(l.kood))
                                              AND dt.staatus < 3))
    THEN

        RAISE NOTICE 'нельзя удалять услугу, если на нее оформлены дневные табеля';
        error_code = 4;
        error_message = 'Ei saa kustuta teenus, enne kustuta ära kõik päevatabelid';
        result = 0;
        RETURN;

    END IF;

    -- Логгирование удаленного документа

    SELECT to_jsonb(row)
    INTO json_ajalugu
    FROM (SELECT now()          AS deleted,
                 v_doc.kasutaja AS user) row;

    UPDATE lapsed.lapse_kaart
    SET staatus = DOC_STATUS,
        ajalugu = coalesce(ajalugu, '[]')::JSONB || json_ajalugu
    WHERE id = doc_id;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER) TO dbpeakasutaja;

DROP RULE IF EXISTS lapsed_lapse_kaart_delete_rule ON lapsed.lapse_kaart;

CREATE RULE lapsed_lapse_kaart_delete_rule AS
    ON DELETE TO lapsed.lapse_kaart
    DO INSTEAD NOTHING;
/*
select lapsed.sp_delete_lapse_kaart(70,3)

select * from lapsed.lapse_kaart
 */