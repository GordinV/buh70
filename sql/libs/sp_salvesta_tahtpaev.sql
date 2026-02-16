DROP FUNCTION IF EXISTS libs.sp_salvesta_tahtpaev(JSON, INTEGER, INTEGER);

--tahtpaevad
CREATE OR REPLACE FUNCTION libs.sp_salvesta_tahtpaev(
    data JSON,
    userid INTEGER,
    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    lib_id       INTEGER;
    userName     TEXT;
    -- Явное приведение типов при чтении из JSON
    doc_id       INTEGER = (data ->> 'id')::INTEGER;
    doc_data     JSON    = data ->> 'data';
    doc_kood     TEXT    = doc_data ->> 'kood';
    doc_nimetus  TEXT    = doc_data ->> 'nimetus';
    doc_library  TEXT    = 'TAHTPAEV';
    doc_paev     INTEGER = (doc_data ->> 'paev')::INTEGER;
    doc_kuu      INTEGER = (doc_data ->> 'kuu')::INTEGER;
    doc_aasta    INTEGER = (doc_data ->> 'aasta')::INTEGER;
    doc_luhipaev INTEGER = (doc_data ->> 'luhipaev')::INTEGER;
    doc_muud     TEXT    = doc_data ->> 'muud';
    is_import    BOOLEAN = (data ->> 'import')::BOOLEAN;
    json_object  JSONB;
BEGIN

    IF (doc_id IS NULL) THEN
        doc_id = (doc_data ->> 'id')::INTEGER;
    END IF;

    -- 1. Валидация дня
    -- Исправлен приоритет операций: добавлены скобки вокруг OR
    IF doc_paev IS NOT NULL AND (doc_paev < 1 OR doc_paev > 31) THEN
        RAISE EXCEPTION 'Viga: Vale kuupäev %', doc_paev;
    END IF;

    -- 2. Валидация месяца
    IF doc_kuu IS NOT NULL AND (doc_kuu < 1 OR doc_kuu > 12) THEN
        RAISE EXCEPTION 'Viga: Vale kuu %', doc_kuu;
    END IF;

    -- 3. Валидация года
    -- Исправлено: использовалась переменная doc_kuu вместо doc_aasta
    -- Исправлено: year(date()) заменено на стандартный EXTRACT
    IF doc_aasta IS NOT NULL AND (doc_aasta < 2018 OR doc_aasta > (EXTRACT(YEAR FROM current_date) + 2)) THEN
        RAISE EXCEPTION 'Viga: Vale aasta %', doc_aasta;
    END IF;

    -- Проверка пользователя
    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
          u.rekvid = user_rekvid
      AND u.id = userid;

    -- Исправлено: в сообщении об ошибке использовалась несуществующая переменная "user"
    IF is_import IS NULL AND userName IS NULL THEN
        RAISE EXCEPTION 'Viga: User not found id: %, is_import %', userid, is_import;
    END IF;

    if user_rekvid <> 63 then
        RAISE EXCEPTION 'Viga: Ainult Rahandusameti kasutajad parandavad tähtpäevad';
    end if;

    -- Формирование JSON свойств (оптимизация через jsonb_build_object)
    json_object = jsonb_build_object(
            'luhipaev', doc_luhipaev,
            'paev', doc_paev,
            'kuu', doc_kuu,
            'aasta', doc_aasta
                  );

    -- Вставка или обновление docs.doc
    IF doc_id IS NULL OR doc_id = 0 THEN

        INSERT INTO
            libs.library (rekvid, kood, nimetus, library, muud, properties)
        VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_muud, json_object)
        RETURNING id INTO lib_id;

    ELSE

        UPDATE libs.library
        SET
            kood       = doc_kood,
            nimetus    = doc_nimetus,
            library    = doc_library,
            properties = json_object,
            muud       = doc_muud
        WHERE
            id = doc_id
        RETURNING id INTO lib_id;

    END IF;

    RETURN lib_id;

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_tahtpaev(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_tahtpaev(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*

SELECT libs.sp_salvesta_pv_grupp('{"id":0,"data":{"doc_type_id":"PVGRUPP","id":0,"konto":"5001","kood":"__test3367","kulum_konto":"1901","library":"PVGRUPP","muud":null,"nimetus":"vfp test PVGRUPP","rekvid":1,"status":0,"tun1":null,"tun2":null,"userid":1}}'
,1, 1)

*/