DROP FUNCTION IF EXISTS docs.sp_salvesta_avans(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_avans(
    data JSON,
    userid INTEGER,
    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    avans1_id     INTEGER;
    avans2_id     INTEGER;
    userName      TEXT;
    doc_id        INTEGER = data ->> 'id';
    doc_data      JSON    = data ->> 'data';
    doc_type_kood TEXT    = 'AVANS';
    doc_type_id   INTEGER = (
                                SELECT
                                    id
                                FROM
                                    libs.library
                                WHERE
                                      ltrim(rtrim(upper(kood))) = ltrim(rtrim(upper(doc_type_kood)))
                                  AND library = 'DOK'
                                LIMIT 1
                            );
    doc_details   JSON    = doc_data ->> 'gridData';
    doc_number    TEXT    = coalesce(doc_data ->> 'number', '1');
    doc_kpv       DATE    = doc_data ->> 'kpv';
    doc_asutusid  INTEGER = doc_data ->> 'asutusid';
    doc_dokpropid INTEGER = doc_data ->> 'dokpropid';
    doc_selg      TEXT    = doc_data ->> 'selg';
    doc_muud      TEXT    = doc_data ->> 'muud';
    doc_lisa_selg TEXT    = doc_data ->> 'lisa_selg';
    json_object   JSON;
    json_record   RECORD;
    new_history   JSONB;
    ids           INTEGER[];
    docs          INTEGER[];
    a_dokvaluuta  TEXT[]  = enum_range(NULL :: DOK_VALUUTA);
    is_import     BOOLEAN = data ->> 'import';
    l_properties  jsonb   = jsonb_build_object('lisa_selg', doc_lisa_selg);
    l_prop        jsonb;
BEGIN

    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
          u.rekvid = user_rekvid
      AND u.id = userId;
    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    RAISE NOTICE 'doc_id %', doc_id;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT
            row_to_json(row)
        INTO new_history
        FROM
            (
                SELECT
                    now()    AS created,
                    userName AS user
            ) row;

        INSERT INTO docs.doc (doc_type_id, history, rekvid)
        VALUES (doc_type_id, '[]' :: JSONB || new_history, user_rekvid)
        RETURNING id
            INTO doc_id;

        INSERT INTO
            docs.avans1 (parentid, rekvid, userid, kpv, asutusid, number, selg, muud, dokpropid, properties)
        VALUES
            (doc_id, user_rekvid, userId, doc_kpv, doc_asutusid, doc_number, doc_selg, doc_muud, doc_dokpropid,
             l_properties)
        RETURNING id
            INTO avans1_id;

    ELSE
        SELECT
            row_to_json(row)
        INTO new_history
        FROM
            (
                SELECT
                    now()    AS updated,
                    userName AS user
            ) row;

        -- устанавливаем связи с документами

        -- получим связи документа
        SELECT
            docs_ids
        INTO docs
        FROM
            docs.doc
        WHERE
            id = doc_id;

        -- will check if arvId exists

        UPDATE docs.doc
        SET
            docs_ids   = docs,
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history
        WHERE
            id = doc_id;


        UPDATE docs.avans1
        SET
            kpv        = doc_kpv,
            asutusid   = doc_asutusid,
            selg       = doc_selg,
            dokpropid  = doc_dokpropid,
            number     = doc_number,
            muud       = doc_muud,
            properties = coalesce(properties, '{}'::jsonb) || l_properties
        WHERE
            parentid = doc_id
        RETURNING id
            INTO avans1_id;

    END IF;
    -- вставка в таблицы документа


    FOR json_object IN
        SELECT *
        FROM
            json_array_elements(doc_details)
        LOOP
            SELECT *
            INTO json_record
            FROM
                json_to_record(
                        json_object) AS x(id TEXT, nomid INTEGER, summa NUMERIC(14, 4), tunnus TEXT, proj TEXT,
                                          objekt text,
                                          konto TEXT, kood1 TEXT, kood2 TEXT, kood3 TEXT, kood4 TEXT, kood5 TEXT,
                                          tp TEXT, valuuta TEXT, kuurs NUMERIC(14, 8), muud TEXT);

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW' OR
               NOT exists
               (
                   SELECT
                       id
                   FROM
                       docs.avans2
                   WHERE
                       id = json_record.id :: INTEGER
               )
            THEN
                INSERT INTO
                    docs.avans2 (parentid, nomid, summa, tunnus, proj, objekt, konto, kood1, kood2, kood3, kood4, kood5,
                                 muud)
                VALUES
                    (avans1_id, json_record.nomid, json_record.summa, json_record.tunnus, json_record.proj,
                     json_record.objekt,
                     json_record.konto,
                     json_record.kood1, json_record.kood2, json_record.kood3, json_record.kood4, json_record.kood5,
                     json_record.muud)

                RETURNING id
                    INTO avans2_id;

                -- add new id into array of ids
                ids = array_append(ids, avans2_id);

                -- valuuta
                json_record.Kuurs = CASE
                                        WHEN empty(json_record.Kuurs)
                                            THEN 1
                                        ELSE json_record.Kuurs END;
                json_record.Valuuta = CASE
                                          WHEN empty(json_record.valuuta)
                                              THEN 'EUR'
                                          ELSE json_record.valuuta END;


            ELSE

                UPDATE docs.avans2
                SET
                    nomid  = json_record.nomid,
                    summa  = json_record.summa,
                    tunnus = json_record.tunnus,
                    proj   = json_record.proj,
                    objekt = json_record.objekt,
                    konto  = json_record.konto,
                    kood1  = json_record.kood1,
                    kood2  = json_record.kood2,
                    kood3  = json_record.kood3,
                    kood4  = json_record.kood4,
                    kood5  = json_record.kood5,
                    muud   = json_record.muud
                WHERE
                    id = json_record.id :: INTEGER;

                avans2_id = json_record.id :: INTEGER;

                -- add existing id into array of ids
                ids = array_append(ids, avans2_id);

            END IF;

            -- delete record which not in json

            DELETE
            FROM
                docs.avans2
            WHERE
                  parentid = avans1_id
              AND id NOT IN (
                                SELECT unnest(ids)
                            );

            -- jaak

            PERFORM docs.get_avans_jaak(doc_id);

        END LOOP;

    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;


GRANT EXECUTE ON FUNCTION docs.sp_salvesta_avans(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_avans(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT docs.sp_salvesta_avans('{"id":8604394,"data": {"asutusid":30839,"bpm":null,"created":"21.09.2026 10:51:48","doc":"Avansiaruanne","docs_ids":"{8604395,4330218}","doc_type_id":"AVANS","dokprop":"lisa selg","dokpropid":2123,"dokpropid1":2123,"id":8604394,"jaak":0,"journalid":8604395,"konto":"202050","koostaja":"relika.tolmatsova","kpv":"20260921","lastupdate":"12.11.2026 01:12:21","lausend":6130,"lisa_selg":"lisa selg","muud":null,"number":"18","rekvid":3,"selg":"pidulike tööriiete soetamine (kleit) Abaout You arve nr AYEE-26-262173","status":"Aktiivne","summa":207.92,"summa1":207.92,"gridData":[{"id":10753,"kbm":0,"kokku":0,"konto":"505099","kood":"erisood.muud","kood1":"01330","kood2":"RE-RT","kood3":"","kood4":"505-muud","kood5":"505","kuurs":1,"muud":"","nimetus":"erisoodustuse muud kulud","nomid":17967,"parentid":5646,"proj":"","summa":167.6800,"tunnus":"Pereregister","userid":4711,"valuuta":"EUR"},{"id":10752,"kbm":0,"kokku":0,"konto":"505099","kood":"erisood.muud","kood1":"01330","kood2":"RE-RT","kood3":"","kood4":"505-muud","kood5":"505","kuurs":1,"muud":"","nimetus":"erisoodustuse muud kulud","nomid":17967,"parentid":5646,"proj":"","summa":40.2400,"tunnus":"Pereregister","userid":4711,"valuuta":"EUR"}]}}', 4711, 3);


select * from libs.nomenklatuur where dok = 'SORDER' limit 10
*/
