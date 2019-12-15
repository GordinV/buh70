DROP FUNCTION IF EXISTS docs.sp_salvesta_teatis(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_teatis(data JSONB,
                                                   user_id INTEGER,
                                                   user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName     TEXT;
    doc_data     JSON    = data ->> 'data';
    doc_id       INTEGER = doc_data ->> 'id';
    doc_asutusid INTEGER = doc_data ->> 'asutusid';
    doc_arved    TEXT    = doc_data ->> 'docs';
    doc_number   TEXT    = doc_data ->> 'number';
    doc_sisu     TEXT    = doc_data ->> 'sisu';
    doc_muud     TEXT    = doc_data ->> 'muud';
    doc_kpv      DATE    = coalesce((doc_data ->> 'kpv')::DATE, current_date);
    json_props   JSONB;
    json_ajalugu JSONB;
    new_rights   JSONB;
    ids          INTEGER[];
    doc_type_id  INTEGER = (SELECT id
                            FROM libs.library
                            WHERE library.library = 'DOK'
                              AND kood = 'TEATIS'
                            LIMIT 1);

BEGIN

    IF doc_arved IS NOT NULL
    THEN
        ids = string_to_array(doc_arved, ',')::INTEGER[];
    END IF;

    RAISE NOTICE 'ids %',ids;
    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_Id;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    json_props = to_jsonb(row)
                 FROM (SELECT 'VOLG' AS tyyp) row;

    IF doc_number IS NULL OR doc_number = ''
    THEN
        -- присвоим новый номер
        doc_number = docs.sp_get_number(user_rekvid, 'TEATIS', YEAR(doc_kpv), NULL);
    END IF;

    RAISE NOTICE 'doc_id %', doc_id;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        SELECT row_to_json(row) INTO new_rights
        FROM (SELECT ARRAY [user_id] AS "select",
                     ARRAY [user_id] AS "update",
                     ARRAY [user_id] AS "delete") row;


        INSERT INTO docs.doc (doc_type_id, history, rigths, rekvid, docs_ids)
        VALUES (doc_type_id, '[]' :: JSONB || json_ajalugu, new_rights, user_rekvid, ids) RETURNING id
            INTO doc_id;


        INSERT INTO docs.teatis (parentid, asutusid, docs, kpv, number, sisu, muud, properties, ajalugu)
        VALUES (doc_id, doc_asutusid, ids, doc_kpv, doc_number, doc_sisu, doc_muud,
                json_props, '[]' :: JSONB || json_ajalugu);

        -- add ids to ref. docs

        RAISE NOTICE 'add docs_ids %', ids;

        UPDATE docs.doc
        SET docs_ids = array_append(docs_ids, doc_id)
        WHERE id IN (SELECT unnest(ids));

        ids = NULL;
    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user
                            ) row;

        UPDATE docs.doc
        SET status   = 1,
            docs_ids = ids,
            history  = json_ajalugu
        WHERE id = doc_id;

        UPDATE docs.teatis
        SET asutusid   = doc_asutusid,
            properties = coalesce(properties, '{}'::JSONB)::JSONB || json_props,
            number     = doc_number,
            kpv        = doc_kpv,
            muud       = doc_muud,
            sisu       = doc_sisu,
            docs       = ids
        WHERE parentid = doc_id;

    END IF;

    RETURN doc_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_teatis(JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_teatis(JSONB, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_teatis(JSONB, INTEGER, INTEGER) TO dbpeakasutaja;


/*

select docs.sp_salvesta_teatis('{ "data":
      { "number": "1",
        "kpv": "2019-12-14",
        "asutusid": 30978,
        "sisu": "Test" ,
        "muud":""
        } }'::jsonb, 70::integer, 63::integer) as id

*/