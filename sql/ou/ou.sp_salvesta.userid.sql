DROP FUNCTION IF EXISTS ou.sp_salvesta_userid(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION ou.sp_salvesta_userid(data JSON,
                                                 user_id INTEGER,
                                                 user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    new_user_id  INTEGER;
    userName     TEXT;
    doc_id       INTEGER = data ->> 'id';
    doc_data     JSON    = data ->> 'data';
    doc_kasutaja TEXT    = doc_data ->> 'kasutaja';
    doc_parool   TEXT    = doc_data ->> 'parool';
    doc_ametnik  TEXT    = doc_data ->> 'ametnik';
    doc_muud     TEXT    = doc_data ->> 'muud';


    new_history  JSON;
    props_json   JSONB   = (SELECT to_jsonb(row)
                            FROM (
                                     SELECT (doc_data ->> 'email') :: TEXT              AS email,
                                            doc_data ->> 'pass'::TEXT                   AS pass,
                                            doc_data ->> 'port'::TEXT                   AS port,
                                            doc_data ->> 'smtp'::TEXT                   AS smtp,
                                            doc_data ->> 'user'::TEXT                   AS user,
                                            doc_data ->> 'earved'::TEXT                 AS earved,
                                            coalesce((doc_data ->> 'keel')::INTEGER, 2) AS keel
                                 ) row);

    roles_json   JSONB   = (SELECT to_jsonb(row)
                            FROM (SELECT coalesce((doc_data ->> 'is_kasutaja') :: BOOLEAN, FALSE)     AS is_kasutaja,
                                         coalesce((doc_data ->> 'is_peakasutaja') :: BOOLEAN, FALSE)  AS is_peakasutaja,
                                         coalesce((doc_data ->> 'is_admin') :: BOOLEAN, FALSE)        AS is_admin,
                                         coalesce((doc_data ->> 'is_eel_koostaja') :: BOOLEAN, FALSE) AS is_eel_koostaja,
                                         coalesce((doc_data ->> 'is_eel_allkirjastaja') :: BOOLEAN,
                                                  FALSE)                                              AS is_eel_allkirjastaja,
                                         coalesce((doc_data ->> 'is_eel_esitaja') :: BOOLEAN, FALSE)  AS is_eel_esitaja,
                                         coalesce((doc_data ->> 'is_eel_aktsepterja') :: BOOLEAN,
                                                  FALSE)                                              AS is_eel_aktsepterja,
                                         coalesce((doc_data ->> 'is_asutuste_korraldaja') :: BOOLEAN,
                                                  FALSE)                                              AS is_asutuste_korraldaja,
                                         coalesce((doc_data ->> 'is_rekl_administraator') :: BOOLEAN,
                                                  FALSE)                                              AS is_rekl_administraator,
                                         coalesce((doc_data ->> 'is_rekl_maksuhaldur') :: BOOLEAN,
                                                  FALSE)                                              AS is_rekl_maksuhaldur,
                                         coalesce((doc_data ->> 'is_ladu_kasutaja') :: BOOLEAN,
                                                  FALSE)                                              AS is_ladu_kasutaja,
                                      coalesce((doc_data ->> 'is_arvestaja') :: BOOLEAN,
                                               FALSE)                                              AS is_arvestaja,
                                      coalesce((doc_data ->> 'is_palga_kasutaja') :: BOOLEAN,
                                               FALSE)                                              AS is_palga_kasutaja,
                                      coalesce((doc_data ->> 'is_pohivara_kasutaja') :: BOOLEAN,
                                               FALSE)                                              AS is_pohivara_kasutaja
                                 ) row);

    is_import    BOOLEAN = data ->> 'import';
    roles_list   TEXT    = 'dbvaatleja';
    l_string     TEXT;
BEGIN

    raise notice 'start';
    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.id = user_id
      AND roles ->> 'is_admin' IS NOT NULL
      AND (roles ->> 'is_admin')::BOOLEAN;


    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE EXCEPTION 'kasutaja ei leidnud või puudub õigused %', user;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- проверка наличия учетной записи
        IF is_import IS NULL AND NOT exists(
                SELECT 1
                FROM pg_roles
                WHERE rolname = doc_kasutaja)
        THEN

            IF exists(SELECT id
                      FROM ou.cur_userid
                      WHERE id = user_id
                        AND coalesce(is_admin :: BOOLEAN, FALSE))
            THEN
                l_string = 'CREATE USER "' || doc_kasutaja ||
                           '" WITH PASSWORD ' || quote_literal(doc_parool) ||
                           ' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION ';
                RAISE NOTICE 'create user %', l_string;
                EXECUTE (l_string);
                IF (roles_json ->> 'is_kasutaja')::boolean or (roles_json ->> 'is_palga_kasutaja')::boolean or (roles_json ->> 'is_pohivara_kasutaja')::boolean
                THEN
                    EXECUTE 'GRANT dbkasutaja TO "' || doc_kasutaja || '"';
                END IF;

            ELSE

                RAISE EXCEPTION 'System role for user is not esists, kasutaja %, import %', doc_kasutaja, is_import;
            END IF;
        END IF;

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        INSERT INTO ou.userid (rekvid, kasutaja, ametnik, muud, roles, properties, ajalugu, status)
        VALUES (user_rekvid, doc_kasutaja, doc_ametnik, doc_muud, roles_json,
                props_json,
                new_history, array_position((enum_range(NULL :: DOK_STATUS)), 'active')) RETURNING id
                   INTO new_user_id;
    ELSE

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user,
                     u.kasutaja,
                     u.properties,
                     u.roles,
                     u.ametnik
              FROM ou.userid u
              WHERE u.id = doc_id) row;


        UPDATE ou.userid
        SET ametnik    = doc_ametnik,
            roles      = roles_json,
            muud       = doc_muud,
            properties = props_json,
            ajalugu    = new_history
        WHERE id = doc_id RETURNING id
            INTO new_user_id;
    END IF;

    -- roles
--    EXECUTE 'revoke eelkoostaja, dbkasutaja, dbpeakasutaja, arvestaja, eelaktsepterja, eelallkirjastaja, eelesitaja, ladukasutaja to' ||
--            doc_kasutaja;

    IF roles_json ->> 'is_kasutaja'
    THEN
        roles_list = roles_list || ',dbkasutaja';
    END IF;
    IF roles_json ->> 'is_peakasutaja'
    THEN
        roles_list = roles_list || ',dbpeakasutaja';
    END IF;
    IF roles_json ->> 'is_ladu_kasutaja'
    THEN
        roles_list = roles_list || ',ladukasutaja';
    END IF;

    IF roles_json ->> 'is_eel_koostaja'
    THEN
        roles_list = roles_list || ',eelkoostaja';
    END IF;

    IF roles_json ->> 'is_eel_allkirjastaja'
    THEN
        roles_list = roles_list || ',eelallkirjastaja';
    END IF;

    IF roles_json ->> 'is_eel_aktsepterja'
    THEN
        roles_list = roles_list || ',eelaktsepterja';
    END IF;

    IF roles_json ->> 'is_eel_esitaja'
    THEN
        roles_list = roles_list || ',eelesitaja';
    END IF;

    if roles_json ->>'is_arvestaja' THEN
        roles_list = roles_list || ',arvestaja';
    END IF;

    l_string = 'GRANT ' || roles_list || ' TO ' || quote_ident(doc_kasutaja);
    raise notice '%', l_string;
    EXECUTE (l_string);


    RETURN new_user_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION ou.sp_salvesta_userid(JSON, INTEGER, INTEGER) TO dbadmin;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_userid(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_userid(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
select ou.sp_salvesta_userid('{"id":0,"data":{"ametnik":"Olga Agapova","doc_type_id":"","id":0,"is_admin":0,"is_arvestaja":1,"is_asutuste_korraldaja":0,"is_eel_aktsepterja":0,"is_eel_allkirjastaja":0,"is_eel_esitaja":0,"is_eel_koostaja":0,"is_kasutaja":0,"is_ladu_kasutaja":0,"is_peakasutaja":0,"is_rekl_administraator":0,"is_rekl_maksuhaldur":0,"kasutaja":"olga.agapova","muud":"","parool":"olga","rekvid":0}}'::json, 5155::integer, 85::integer) as id


SELECT ou.sp_salvesta_userid('{"id":0,"data":{"rekvid":1, "kasutaja":"temp_2","ametnik":"test1","is_kasutaja":true}}', 1, 1);

select * from ou.userid where id = 5693

update ou.userid set roles = '{"is_admin":true}' where id = 1

SELECT *
        FROM pg_roles
        WHERE rolname = 'test_2'
*/
