-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_lapse_taabel(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_lapse_taabel(IN user_id INTEGER,
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
    is_ok        BOOLEAN = FALSE;
BEGIN

    SELECT l.*,
           u.ametnik::TEXT                               AS kasutaja,
           (u.roles ->> 'is_arvestaja')::BOOLEAN         AS is_arvestaja,
           (u.roles ->> 'is_tabeli_korraldaja')::BOOLEAN AS is_tabeli_korraldaja,
           (u.roles ->> 'is_kasutaja')::BOOLEAN          AS is_kasutaja,
           (l.properties ->> 'kas_asendus')::BOOLEAN     AS kas_asendus,
           (l.properties ->> 'asendus_id')::INTEGER      AS asendus_id
    INTO v_doc
    FROM lapsed.lapse_taabel l
             JOIN ou.userid u ON u.id = user_id
    WHERE l.id = doc_id
      AND l.staatus = 1;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF (coalesce(v_doc.kasutaja, FALSE) IS NULL OR v_doc.is_tabeli_korraldaja
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

    is_ok = CASE
                WHEN coalesce(v_doc.is_tabeli_korraldaja, FALSE) THEN TRUE
                WHEN coalesce(v_doc.is_kasutaja, FALSE) THEN TRUE
                ELSE FALSE END;
    
    IF NOT is_ok
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление ';
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;

    -- снять ограничения с дневного табеля
    UPDATE lapsed.day_taabel
    SET staatus = 1
    WHERE staatus = 2
      AND rekv_id = v_doc.rekvid
      AND month(kpv) = v_doc.kuu
      AND year(kpv) = v_doc.aasta
      AND id IN (
        SELECT t.id
        FROM lapsed.day_taabel t
                 INNER JOIN lapsed.day_taabel1 t1 ON t.id = t1.parent_id
        WHERE rekv_id = v_doc.rekvid
          AND month(kpv) = v_doc.kuu
          AND year(kpv) = v_doc.aasta
          AND t1.laps_id = v_doc.parentid
          AND t1.nom_id = v_doc.nomid
    );

    -- если табель импортирован, снять ограничение там
    IF (v_doc.kas_asendus IS NOT NULL AND coalesce(v_doc.asendus_id, 0) > 0)
    THEN
        UPDATE lapsed.asendus_taabel SET staatus = 1 WHERE id = v_doc.asendus_id AND staatus = 2;
    END IF;

    -- Логгирование удаленного документа

    SELECT to_jsonb(row)
    INTO json_ajalugu
    FROM (SELECT now()          AS deleted,
                 v_doc.kasutaja AS user) row;

    UPDATE lapsed.lapse_taabel
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

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_taabel(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_taabel(INTEGER, INTEGER) TO dbpeakasutaja;


/*
select lapsed.sp_delete_lapse_taabel(70,24)

select * from ou.userid where id =  70

update ou.userid set roles = roles || '{"is_arvestaja":true}' where id = 70
 */