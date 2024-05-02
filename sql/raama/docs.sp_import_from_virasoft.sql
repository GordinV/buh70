DROP FUNCTION IF EXISTS docs.sp_import_from_virasoft(JSONB);

CREATE OR REPLACE FUNCTION docs.sp_import_from_virasoft(IN import_data JSONB,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName          TEXT;
    doc_data          JSON        = import_data ->> 'data';
    doc_user_id       INTEGER     = import_data ->> 'userId';
    doc_file_id       TEXT        = import_data ->> 'fileId';
    doc_summa         NUMERIC     = doc_data ->> 'summa';
    doc_kpv           DATE        = doc_data ->> 'kpv';
    doc_selg          TEXT        = doc_data ->> 'selg';
    doc_isikukood     TEXT        = doc_data ->> 'isikukood';
    json_object       JSON;
    count             INTEGER     = 0;
    user_id           INTEGER     = 0;
    json_lausend      JSONB;
    json_lausend_read JSONB       = '[]'::JSONB;
    l_check_lausend   TEXT;
    l_rekv_id         INTEGER;
    l_user_id         INTEGER;
    l_asutus_id       INTEGER;
    l_tp_db           VARCHAR(20) = '800699';
    l_tp_kr           VARCHAR(20) = '800699';
    l_oma_tp          TEXT;
    l_json            JSONB;
    doc_id            INTEGER;
BEGIN

    RAISE NOTICE 'doc_data %',doc_data;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.id = doc_user_id;

    IF userName IS NULL
    THEN
        error_message = 'User not found ';
        json_object = to_jsonb(row.*)
                      FROM (
                               SELECT NULL::INTEGER AS doc_id,
                                      error_message AS error_message,
                                      TRUE          AS kas_vigane,
                                      1::INTEGER    AS error_code
                           ) row;

        RETURN;
    END IF;

    -- Коетроль уникальности файла
    IF doc_file_id IS NULL OR empty(doc_file_id) OR
       exists(SELECT id FROM ou.paringud WHERE changes ->> 'fileId' = doc_file_id)
    THEN
        RAISE EXCEPTION 'Viga, vale fileId või fail juba impoteeritud % ',doc_file_id;
    END IF;

    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_data)
        LOOP
            RAISE NOTICE 'json_object %',json_object;

            -- определяем учреждение
            l_rekv_id = (SELECT id FROM ou.rekv WHERE regkood = json_object ->> 'regkood' LIMIT 1);
            l_user_id =
                    (SELECT id FROM ou.userid WHERE rekvid = l_rekv_id AND kasutaja = userName AND status < 3 LIMIT 1);

            IF l_rekv_id IS NULL OR l_user_id IS NULL
            THEN
                RAISE EXCEPTION 'Viga, vale asutus või puudub õigused % , rowId %',json_object ->> 'regkood', json_object ->> 'rowId';
            END IF;

            -- ищем работника
            SELECT t.id, a.tp AS tp_d, a.tp AS tp_k
            INTO l_asutus_id, l_tp_db, l_tp_kr
            FROM palk.cur_tootajad t
                     INNER JOIN libs.asutus a ON a.id = t.id
            WHERE t.isikukood = json_object ->> 'isikukood'
              AND t.rekvid = l_rekv_id
            LIMIT 1;

            IF l_asutus_id IS NULL
            THEN
                RAISE EXCEPTION 'Viga, vale isikukood % , rowId %',json_object ->> 'isikukood', json_object ->> 'rowId';
            END IF;

            -- проверка на признак
            IF NOT empty(coalesce(json_object ->> 'tunnus', '')) AND NOT exists(SELECT id
                          FROM libs.library
                          WHERE kood = ltrim(rtrim(json_object ->> 'tunnus'))
                            AND rekvid = l_rekv_id
                            AND library = 'TUNNUS'
                            AND status < 3)
            THEN
                RAISE EXCEPTION 'Viga, vale tunnus % , rowId %',json_object ->> 'tunnus', json_object ->> 'rowId';
            END IF;

            -- проверка на проект
            IF NOT empty(coalesce(json_object ->> 'projekt', '')) AND NOT exists(SELECT id
                                                                                 FROM libs.library
                                                                                 WHERE kood = ltrim(rtrim(json_object ->> 'projekt'))
                                                                                   AND rekvid = l_rekv_id
                                                                                   AND library = 'PROJ'
                                                                                   AND status < 3)
            THEN
                RAISE EXCEPTION 'Viga, vale projekt % , rowId %',json_object ->> 'projekt', json_object ->> 'rowId';
            END IF;

            -- проверка на objekt
            IF NOT empty(coalesce(json_object ->> 'objekt', '')) AND NOT exists(SELECT id
                                                                                 FROM libs.library
                                                                                 WHERE kood = ltrim(rtrim(json_object ->> 'objekt'))
                                                                                   AND rekvid = l_rekv_id
                                                                                   AND library = 'OBJEKT'
                                                                                   AND status < 3)
            THEN
                RAISE EXCEPTION 'Viga, vale objekt % , rowId %',json_object ->> 'objekt', json_object ->> 'rowId';
            END IF;

            -- проверка на uritus
            IF NOT empty(coalesce(json_object ->> 'uritus', '')) AND NOT exists(SELECT id
                                                                                FROM libs.library
                                                                                WHERE kood = ltrim(rtrim(json_object ->> 'uritus'))
                                                                                  AND rekvid = l_rekv_id
                                                                                  AND library = 'URITUS'
                                                                                  AND status < 3)
            THEN
                RAISE EXCEPTION 'Viga, vale uritus % , rowId %',json_object ->> 'uritus', json_object ->> 'rowId';
            END IF;

            -- корректируем Тп код
            IF left(json_object ->> 'kreedit', 6) = '100100'
            THEN
                SELECT tp
                INTO l_tp_kr
                FROM ou.aa
                WHERE parentid = l_rekv_id
                  AND kassa = 1
                  AND konto = ltrim(rtrim(json_object ->> 'kreedit'))
                ORDER BY default_ DESC
                LIMIT 1;

            END IF;

            -- ищем свой Тп код
            l_oma_tp = (SELECT tp
                        FROM ou.aa
                        WHERE parentid = l_rekv_id
                          AND kassa = 2
                        LIMIT 1);

-- проверка проводки
            json_lausend = jsonb_build_object(
                    'db', json_object ->> 'deebet',
                    'kr', json_object ->> 'kreedit',
                    'tpd', l_tp_db,
                    'tpk', l_tp_kr,
                    'tt', json_object ->> 'tegevusala',
                    'allikas', json_object ->> 'allikas',
                    'rahavoog', '',
                    'eelarve', json_object ->> 'artikkel',
                    'kpv', json_object ->> 'kpv',
                    'oma_tp', l_oma_tp);

            l_check_lausend = docs.sp_lausendikontrol(json_lausend::JSONB);

            RAISE NOTICE 'json_record %, l_check_lausend %', json_object ->> 'rowId', l_check_lausend;

            IF NOT empty(l_check_lausend) AND l_check_lausend ILIKE '%viga%'
            THEN
                -- error
                RAISE EXCEPTION '%, rowId %',l_check_lausend, json_object ->> 'rowId';
            END IF;

            -- сохранение
            -- параметры

            json_lausend_read = '[]'::JSONB || jsonb_build_object(
                    'id', 0,
                    'deebet', json_object ->> 'deebet',
                    'lisa_d', l_tp_db,
                    'kreedit', json_object ->> 'kreedit',
                    'lisa_k', l_tp_kr,
                    'summa', json_object ->> 'summa',
                    'tunnus', json_object ->> 'tunnus',
                    'proj', json_object ->> 'projekt',
                    'kood1', json_object ->> 'tegevusala',
                    'kood2', json_object ->> 'allikas',
                    'kood3', '',
                    'kood4', json_object ->> 'uritus',
                    'kood5', json_object ->> 'artikkel',
                    'objekt', json_object ->> 'objekt');

            json_lausend = jsonb_build_object(
                    'id', 0,
                    'doc_type_id', 'JOURNAL',
                    'kpv', (json_object ->> 'kpv')::DATE,
                    'selg', json_object ->> 'selgitus',
                    'muud', 'VIROSOFT IMPORT',
                    'asutusid', l_asutus_id,
                    'gridData', json_lausend_read);

            /* salvestan lausend */
            doc_id = docs.sp_salvesta_journal(jsonb_build_object('data', json_lausend):: JSON, l_user_id, l_rekv_id);
            IF coalesce(doc_id, 0) = 0 OR NOT exists(SELECT 1 FROM cur_journal WHERE id = doc_id)
            THEN
                RAISE EXCEPTION 'lausendi koostamine viga , rowId %, doc_id %', json_object ->> 'rowId', doc_id;
            END IF;

            count = count + 1;
        END LOOP;

    IF count > 0
    THEN
        -- успешно, сохраняем ид файла
        INSERT INTO ou.paringud (user_id, sql, params, tulemused, changes)
        VALUES (doc_user_id, 'docs.sp_import_from_virasoft', import_data, jsonb_build_object('result', count),
                jsonb_build_object('fileId', doc_file_id));
    END IF;

    result = count;
    RETURN;


END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_import_from_virasoft (JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_import_from_virasoft (JSONB) TO dbpeakasutaja;


/*SELECT docs.sp_import_from_virasoft('{
  "userId": 9587,
  "fileId": 1,
  "data": [
    {
      "rowId": "1",
      "regkood": "75008427",
      "kpv": "2024-05-30",
      "isikukood": "47102122229",
      "deebet": "50025001",
      "kreedit": "202000",
      "summa": "100",
      "artikkel": "5002",
      "allikas": "LE-P",
      "tegevusala": "01112",
      "tunnus": "OSAK",
      "projekt": "",
      "uritus": "",
      "objekt": "",
      "selgitus": "Palgarvestus"
    },
    {
      "rowId": "2",
      "regkood": "75008427",
      "kpv": "2024-05-30",
      "isikukood": "47102122229",
      "deebet": "202000",
      "kreedit": "10010002",
      "summa": "100",
      "artikkel": "5002",
      "allikas": "LE-P",
      "tegevusala": "01112",
      "tunnus": "OSAK",
      "projekt": "",
      "uritus": "",
      "objekt": "",
      "selgitus": "Palk, väljamaks"
    }
  ]
}'::JSONB)
*/
