DROP FUNCTION IF EXISTS eelarve.sp_taotlus_tagastada(INTEGER, JSON);

CREATE OR REPLACE FUNCTION eelarve.sp_taotlus_tagastada(IN user_id INTEGER,
                                                        IN params JSON,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD
    LANGUAGE plpgsql
AS
$$
DECLARE
    doc_id      INTEGER = coalesce((params ->> 'doc_id') :: INTEGER, 0);
    tcMuud      TEXT    = params ->> 'muud'; -- Примечание, добавляемое при возврате
    tmpTaotlus  RECORD;
    new_history JSON;
    v_user      RECORD;
BEGIN

    -- 1. Проверка наличия пользователя и прав на выполнение операции
    SELECT
        u.roles,
        u.kasutaja
    INTO v_user
    FROM
        ou.userid u
    WHERE
        u.id = user_id;

    IF v_user IS NULL OR coalesce((v_user.roles ->> 'is_eel_aktsepterja') :: BOOLEAN, FALSE) = FALSE THEN
        error_code = 5;
        error_message = 'Viga, kasutaja ei leitud või puuduvad õigused';
        result = 0;
        RETURN;
    END IF;

    -- 2. Поиск документа (taotlus)
    SELECT
        t.*
    INTO tmpTaotlus
    FROM
        eelarve.taotlus t
    WHERE
        t.parentid = doc_id;

    IF tmpTaotlus IS NULL THEN
        error_code = 6;
        error_message = 'Viga, dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;
    END IF;

    -- 3. Контроль периода для модуля Eelarve
    IF NOT (ou.fnc_aasta_eelarve_kontrol(tmpTaotlus.rekvid, tmpTaotlus.kpv)) THEN
        RAISE EXCEPTION 'Viga, periood on suletud (Eelarve kinni).';
    END IF;

    -- 4. Обновление статуса ходатайства на "tagastatud" (возвращено)
    UPDATE eelarve.taotlus
    SET
        status    = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'tagastatud'), -- Получаем порядковый номер статуса из ENUM
        aktseptID = user_id,
        muud      = coalesce(muud, '') || E'\n' || coalesce(tcMuud, '')                  -- Добавляем новое примечание к существующим
    WHERE
        parentid = doc_id;

    -- 5. Формирование записи в историю документа
    SELECT
        row_to_json(row)
    INTO new_history
    FROM
        (
            SELECT
                now()           AS updated,
                v_user.kasutaja AS user,
                'tagastatud'    AS status
        ) row;

    -- 6. Обновление основной записи документа в docs.doc
    UPDATE docs.doc
    SET
        lastupdate = now(),
        history    = coalesce(history, '[]') :: JSONB || new_history :: JSONB
    WHERE
        id = doc_id;

    result = 1;
    RETURN;
END;
$$;


GRANT EXECUTE ON FUNCTION eelarve.sp_taotlus_tagastada(INTEGER, JSON) TO eelaktsepterja;
