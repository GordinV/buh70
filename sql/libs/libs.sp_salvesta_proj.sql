DROP FUNCTION IF EXISTS libs.sp_salvesta_proj(JSON, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS libs.sp_salvesta_proj(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_proj(data JSONB,
                                                 userid INTEGER,
                                                 user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id          INTEGER;
    userName        TEXT;
    doc_id          INTEGER = data ->> 'id';
    doc_data        JSON    = data ->> 'data';
    doc_kood        TEXT    = doc_data ->> 'kood';
    doc_nimetus     TEXT    = doc_data ->> 'nimetus';
    doc_muud        TEXT    = doc_data ->> 'muud';
    doc_library     text    = 'PROJ';
    doc_valid       DATE    = CASE
                                  WHEN empty(doc_data ->> 'valid') THEN NULL::DATE
                                  ELSE (doc_data ->> 'valid')::DATE END;
    doc_proj_alates DATE    = CASE
                                  WHEN empty(doc_data ->> 'proj_alates') THEN NULL::DATE
                                  ELSE (doc_data ->> 'proj_alates')::DATE END;
    doc_proj_kuni   DATE    = CASE
                                  WHEN empty(doc_data ->> 'proj_kuni') THEN NULL::DATE
                                  ELSE (doc_data ->> 'proj_kuni')::DATE END;
    doc_proj_summa  NUMERIC = doc_data ->> 'proj_summa';
    doc_details     JSON    = doc_data ->> 'gridData';
    v_doc           RECORD;
    json_object     JSON;
    json_record     record;
    l_prev_doc      TEXT    = '';
    row_id          integer;
    ids             integer[];
    l_kuu_summa     numeric = 0;
    l_osad          integer;

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    IF (doc_valid IS NULL OR
        doc_valid::DATE >= current_date)
    THEN
        -- ищем двойников в других справочниках
        IF (
               SELECT
                   count(l.id)
               FROM
                   libs.library l
               WHERE
                     l.rekvid = user_rekvid
                 AND l.kood = doc_kood
                 AND (coalesce(doc_id, 0) = 0 OR l.id <> coalesce(doc_id, 0))
                 AND l.status < 3
                 AND l.library = 'PROJ'
                 AND (l.properties::JSONB ->> 'valid' IS NULL OR l.properties::JSONB ->> 'valid' = ''
                   OR (l.properties::JSONB ->> 'valid')::DATE >= current_date)
           ) > 0
        THEN

            RAISE EXCEPTION 'Viga, kood juba kasutusel (PROJEKT) %',doc_kood;

        END IF;
    END IF;


    SELECT
        row_to_json(row)
    INTO json_object
    FROM
        (
            SELECT
                doc_valid       AS valid,
                doc_proj_alates as proj_alates,
                doc_proj_kuni   as proj_kuni,
                doc_proj_summa  as proj_summa
        ) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO
            libs.library (rekvid, kood, nimetus, library, muud, properties)
        VALUES
            (user_rekvid, doc_kood, doc_nimetus, doc_library,
             doc_muud, json_object)
        RETURNING id
            INTO lib_id;

        -- для отдела культуры
        IF user_rekvid = 119 AND doc_library = 'PROJ' AND lib_id IS NOT NULL AND lib_id > 0
        THEN
            --копируем  данные во все под организации
            INSERT INTO
                libs.library (rekvid, kood, nimetus, library, muud, properties)
            SELECT
                rekv.id,
                l.kood,
                l.nimetus,
                l.library,
                l.muud,
                l.properties
            FROM
                libs.library l,
                ou.rekv      rekv
            WHERE
                  l.id = lib_id
              AND rekv.parentid = 119;
        END IF;

    ELSE
        SELECT kood INTO l_prev_doc FROM libs.library WHERE id = doc_id LIMIT 1;

        -- check is this code in use
        -- проверим на использование кода в справочниках
        SELECT * INTO v_doc FROM libs.library l WHERE l.id = doc_id;

        UPDATE libs.library
        SET
            kood       = doc_kood,
            nimetus    = doc_nimetus,
            library    = doc_library,
            muud       = doc_muud,
            properties = json_object
        WHERE
            id = doc_id
        RETURNING id
            INTO lib_id;

        IF user_rekvid = 119 AND doc_library = 'PROJ' AND lib_id IS NOT NULL AND lib_id > 0
        THEN
            UPDATE libs.library
            SET
                kood       = doc_kood,
                nimetus    = doc_nimetus,
                muud       = doc_muud,
                properties = json_object
            WHERE
                  kood = v_doc.kood
              AND library = 'PROJ'
              AND rekvid IN (
                                SELECT
                                    id
                                FROM
                                    ou.rekv
                                WHERE
                                    parentid = 119
                            );

        END IF;

    END IF;

    FOR json_object IN
        SELECT *
        FROM
            jsonb_array_elements(doc_details::jsonb)
        LOOP
            SELECT *
            INTO json_record
            FROM
                jsonb_to_record(
                        json_object::jsonb) AS x(id TEXT, leping_id INTEGER, proj_id INTEGER, summa NUMERIC(14, 2),
                                                 korrigeerimine NUMERIC(14, 2), sm numeric(14, 2), selgitus text);

            l_osad = ((doc_proj_kuni - doc_proj_alates) / 30)::integer;
            if l_osad = 0 then
                l_kuu_summa = 1;
            else
                l_kuu_summa = round((json_record.summa + json_record.korrigeerimine) / l_osad, 2);
            end if;


            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW' OR
               NOT exists
               (
                   SELECT
                       id
                   FROM
                       libs.proj_laiendus
                   WHERE
                       id = json_record.id :: INTEGER
               )
            THEN
                INSERT INTO
                    libs.proj_laiendus (rekvid, proj_id, leping_id, summa, korrigeerimine, sm, kuu_summa, selgitus)
                VALUES
                    (user_rekvid, lib_id, json_record.leping_id, json_record.summa, json_record.korrigeerimine,
                     json_record.sm, l_kuu_summa, json_record.selgitus)
                RETURNING id
                    INTO row_id;

                -- add new id into array of ids
                ids = array_append(ids, row_id);

            ELSE

                UPDATE libs.proj_laiendus
                SET
                    leping_id      = json_record.leping_id,
                    summa          = json_record.summa,
                    sm             = json_record.sm,
                    kuu_summa      = l_kuu_summa,
                    korrigeerimine = json_record.korrigeerimine,
                    selgitus = json_record.selgitus
                WHERE
                    id = json_record.id :: INTEGER
                returning id into row_id;

                -- add existing id into array of ids
                ids = array_append(ids, row_id);

            END IF;

        end loop;
    if doc_details is not null then
        -- delete record which not in json

        DELETE
        FROM
            libs.proj_laiendus
        WHERE
              proj_id = lib_id
          AND id NOT IN (
                            SELECT unnest(ids)
                        );
    end if;

    RETURN lib_id;

END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_proj(JSONB, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_proj(JSONB, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_proj(JSONB, INTEGER, INTEGER) TO taabel;


/*

SELECT libs.sp_salvesta_proj('{"id":0,"data":{"id":0,"kood":"test1","nimetus":"test proj","proj_alates":"2025-01-01","proj_kuni":"2025-12-31", "gridData": [{"id":0, "proj_id":null,"leping_id":24447, "summa":1000}]}}'
,10255, 63)
*/