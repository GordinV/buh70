DROP FUNCTION IF EXISTS docs.sp_salvesta_leping(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_leping(data JSON,
                                                   userid INTEGER,
                                                   user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    leping_id     INTEGER;
    leping2_id    INTEGER;
    userName      TEXT;
    doc_id        INTEGER = data ->> 'id';
    doc_type_kood TEXT    = 'LEPING'/*data->>'doc_type_id'*/;
    doc_type_id   INTEGER = (SELECT id
                             FROM libs.library
                             WHERE kood = doc_type_kood
                               AND library = 'DOK'
                             LIMIT 1);
    doc_data      JSON    = data ->> 'data';
    doc_details   JSON    = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');
    doc_number    TEXT    = doc_data ->> 'number';
    doc_asutusid  INTEGER = doc_data ->> 'asutusid';
    doc_selgitus  TEXT    = doc_data ->> 'selgitus';
    doc_kpv       DATE    = doc_data ->> 'kpv';
    doc_tahtaeg   DATE    = doc_data ->> 'tahtaeg';
    doc_muud      TEXT    = doc_data ->> 'muud';
    doc_objektid  INTEGER = doc_data ->> 'objektid';
    doc_pakettid  INTEGER = doc_data ->> 'pakettid';
    doc_doklausid INTEGER = doc_data ->> 'doklausid';
    json_object   JSON;
    json_record   RECORD;
    new_history   JSONB;
    new_rights    JSONB;
    ids           INTEGER[];
    is_import     BOOLEAN = data ->> 'import';
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    RAISE NOTICE 'doc_id: %', doc_id;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        SELECT row_to_json(row) INTO new_rights
        FROM (SELECT ARRAY [userId] AS "select",
                     ARRAY [userId] AS "update",
                     ARRAY [userId] AS "delete") row;


        INSERT INTO docs.doc (doc_type_id, history, rigths, rekvId, status)
        VALUES (doc_type_id, '[]' :: JSONB || new_history, new_rights, user_rekvid, 1) RETURNING id
            INTO doc_id;

        RAISE NOTICE 'doc_id %', doc_id;

        INSERT INTO docs.leping1 (parentid, rekvid, number, kpv, asutusid, selgitus, tahtaeg, muud, objektid, pakettid,
                                  doklausid)
        VALUES (doc_id, user_rekvid, doc_number, doc_kpv, doc_asutusid, doc_selgitus, doc_tahtaeg,
                doc_muud, doc_objektid, doc_pakettid, doc_doklausid) RETURNING id
                   INTO leping_id;

        raise notice 'leping_id %', leping_id;

    ELSE
        -- history
        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        UPDATE docs.doc
        SET lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history,
            rekvid     = user_rekvid
        WHERE id = doc_id;

        UPDATE docs.leping1
        SET number    = doc_number,
            kpv       = doc_kpv,
            asutusid  = doc_asutusid,
            selgitus  = doc_selgitus,
            tahtaeg   = doc_tahtaeg,
            muud      = doc_muud,
            objektid  = doc_objektid,
            pakettid  = doc_pakettid,
            doklausid = doc_doklausid
        WHERE parentid = doc_id RETURNING id
            INTO leping_id;

    END IF;
    -- вставка в таблицы документа


    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details)
        LOOP
            SELECT * INTO json_record
            FROM json_to_record(
                         json_object) AS x(id TEXT, nomId INTEGER, kogus NUMERIC(14, 4), hind NUMERIC(14, 4),
                                           summa NUMERIC(14, 4),
                                           muud TEXT, formula TEXT, kbm INTEGER,
                                           soodus INTEGER);

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN
                INSERT INTO docs.leping2 (parentid, nomid, kogus, hind, kbm, summa, soodus,
                                          muud, formula)
                VALUES (leping_id, json_record.nomid,
                        coalesce(json_record.kogus, 0),
                        coalesce(json_record.hind, 0),
                        coalesce(json_record.kbm, 0),
                        coalesce(json_record.summa, 0),
                        json_record.soodus, json_record.muud,
                        json_record.formula) RETURNING id
                           INTO leping2_id;

                -- add new id into array of ids
                ids = array_append(ids, leping2_id);

            ELSE
                UPDATE docs.leping2
                SET parentid = leping_id,
                    nomid    = json_record.nomid,
                    kogus    = coalesce(json_record.kogus, 0),
                    hind     = coalesce(json_record.hind, 0),
                    kbm      = coalesce(json_record.kbm, 0),
                    summa    = coalesce(json_record.summa, kogus * hind),
                    soodus   = json_record.soodus,
                    muud     = json_record.muud,
                    formula  = json_record.formula
                WHERE id = json_record.id :: INTEGER RETURNING id
                    INTO leping2_id;

                -- add new id into array of ids
                ids = array_append(ids, leping2_id);

            END IF;

        END LOOP;

    -- delete record which not in json

    DELETE
    FROM docs.leping2
    WHERE parentid = leping_id
      AND id NOT IN (SELECT unnest(ids));

    RETURN doc_id;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_leping(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_leping(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
select docs.sp_salvesta_leping('{"id":297260,"data": {"asutusid":1,"bpm":null,"created":"10.08.2018 11:08:13","doc":"Lepingud","doc_status":0,"doc_type_id":"LEPING","dok":null,"doklausid":null,"id":297260,"kpv":"2018-08-10","lastupdate":"10.08.2018 11:08:13","number":"001","objektid":null,"pakettid":null,"rekvid":1,"selgitus":"test 123","status":"????????","tahtaeg":"2018-08-10","userid":1,"gridData":[{"hind":100,"id":4,"kbm":0,"kogus":1,"kood":"TEENUS18","nimetus":"Teenuse selgitus   18%","nomid":2,"soodus":0,"soodusalg":"        ","sooduslopp":"        ","status":1,"summa":100,"userid":1}]}}'
, 1, 1);
*/
