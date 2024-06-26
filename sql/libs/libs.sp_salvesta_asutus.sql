﻿DROP FUNCTION IF EXISTS docs.sp_salvesta_asutus(JSON, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS libs.sp_salvesta_asutus(JSON, INTEGER, INTEGER);
-- FUNCTION: libs.sp_salvesta_asutus(json, integer, integer)

-- DROP FUNCTION libs.sp_salvesta_asutus(json, integer, integer);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_asutus(data JSON,
                                                   user_id INTEGER,
                                                   user_rekvid INTEGER)
    RETURNS INTEGER
    LANGUAGE 'plpgsql'
AS
$BODY$

DECLARE
    asutus_id          INTEGER;
    userName           TEXT;
    doc_id             INTEGER = data ->> 'id';
    doc_data           JSON    = data ->> 'data';
    doc_regkood        TEXT    = doc_data ->> 'regkood';
    doc_nimetus        TEXT    = doc_data ->> 'nimetus';
    doc_omvorm         TEXT    = doc_data ->> 'omvorm';
    doc_kontakt        TEXT    = doc_data ->> 'kontakt';
    doc_aadress        TEXT    = doc_data ->> 'aadress';
    doc_tp             TEXT    = doc_data ->> 'tp';
    doc_tel            TEXT    = doc_data ->> 'tel';
    doc_email          TEXT    = doc_data ->> 'email';
    doc_mark           TEXT    = doc_data ->> 'mark';
    doc_muud           TEXT    = doc_data ->> 'muud';
    doc_pank           TEXT    = doc_data ->> 'pank';
    doc_kmkr           TEXT    = doc_data ->> 'kmkr';
    doc_KEHTIVUS       DATE    = CASE
                                     WHEN ltrim(rtrim((doc_data ->> 'kehtivus')))::TEXT = '' THEN NULL::DATE
                                     ELSE (doc_data ->> 'kehtivus')::DATE END;
    is_import          BOOLEAN = data ->> 'import';
    doc_is_tootaja     BOOLEAN = coalesce((doc_data ->> 'is_tootaja') :: BOOLEAN, FALSE);
    doc_asutus_aa      JSONB   = coalesce((doc_data ->> 'asutus_aa') :: JSONB, '[]':: JSONB);
    doc_details        JSONB   = doc_data ->> 'gridData';
    doc_aa             TEXT    = doc_data ->> 'aa';
    doc_palk_email     TEXT    = doc_data ->> 'palk_email';
    doc_kas_teiste_kov BOOLEAN = doc_data ->> 'kas_teiste_kov';
    new_properties     JSONB;
    new_history        JSONB   = '[]'::JSONB;
    new_rights         JSONB;
    new_aa             JSONB;
    l_old_regkood      TEXT;
BEGIN


    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;
    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE EXCEPTION 'Viga. Kasutaja ei leidnud %', user;
    END IF;

    IF empty(ltrim(rtrim(doc_regkood))) OR empty(ltrim(rtrim(doc_nimetus)))
    THEN
        RAISE EXCEPTION 'Viga. Puudub vajaliku andmed ';
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    -- расчетные счета
    IF doc_details IS NOT NULL
    THEN
        -- для теста из род. платы
        doc_asutus_aa = doc_details;
        doc_aa = NULL;
    END IF;

    IF (doc_aa IS NOT NULL AND doc_details IS NULL)
    THEN
        -- если задан упрощенный расч. счет, то пишем его (для модуля дети)

        SELECT row_to_json(row)
        INTO new_aa
        FROM (SELECT doc_aa AS aa, '' AS pank) row;
    END IF;

    IF doc_id IS NOT NULL AND doc_id > 0 AND NOT coalesce((doc_data ->> 'is_tootaja') :: BOOLEAN, FALSE) AND
       exists(SELECT id FROM palk.tooleping WHERE parentid = doc_id)
    THEN
        doc_is_tootaja = TRUE;
    END IF;

    IF doc_tp IS NULL OR empty(doc_tp)
    THEN
        doc_tp = '800699';
    END IF;

    SELECT row_to_json(row)
    INTO new_properties
    FROM (SELECT doc_kehtivus                                                              AS kehtivus,
                 doc_pank                                                                  AS pank,
                 CASE WHEN doc_id IS NULL OR doc_id = 0 THEN FALSE ELSE doc_is_tootaja END AS is_tootaja,
                 doc_palk_email                                                            AS palk_email,
                 CASE
                     WHEN doc_aa IS NOT NULL AND NOT empty(doc_aa) THEN '[]'::JSONB || new_aa :: JSONB
                     ELSE doc_asutus_aa :: JSONB END                                       AS asutus_aa,
                 doc_kmkr                                                                  AS kmkr,
                 coalesce(doc_kas_teiste_kov, FALSE)                                       AS kas_teiste_kov) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;
        SELECT row_to_json(row)
        INTO new_rights
        FROM (SELECT ARRAY [user_id] AS "select",
                     ARRAY [user_id] AS "update",
                     ARRAY [user_id] AS "delete") row;

        INSERT INTO libs.asutus (rekvid, regkood, nimetus, omvorm, kontakt, aadress, tel, email, mark, muud, properties,
                                 tp, ajalugu)
        VALUES (user_rekvid, doc_regkood, doc_nimetus, doc_omvorm, doc_kontakt, doc_aadress, doc_tel, doc_email,
                doc_mark,
                doc_muud, new_properties, coalesce(doc_tp, '800699'), new_history) RETURNING id
                   INTO asutus_id;


    ELSE
        -- history
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        SELECT ltrim(rtrim(regkood)) INTO l_old_regkood FROM libs.asutus WHERE id = doc_id;
        IF NOT empty(l_old_regkood) AND len(l_old_regkood) >= 7 AND len(l_old_regkood) < 11
        THEN
            -- asutus, редактировать только по правам
            IF NOT exists(SELECT id FROM ou.userid WHERE id = user_id AND (roles ->> 'is_asutuste_korraldaja')::BOOLEAN)
            THEN
                RAISE EXCEPTION 'Viga. Puudub õigused';
                RETURN 0;
            END IF;

        END IF;

        UPDATE libs.asutus
        SET regkood    = doc_regkood,
            nimetus    = doc_nimetus,
            omvorm     = doc_omvorm,
            kontakt    = doc_kontakt,
            aadress    = doc_aadress,
            tel        = doc_tel,
            email      = doc_email,
            mark       = doc_mark,
            muud       = doc_muud,
            tp         = coalesce(doc_tp, '800699'),
            properties = properties || new_properties,
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || new_history::JSONB,
            staatus    = CASE WHEN staatus = 3 THEN 1 ELSE staatus END
        WHERE id = doc_id RETURNING id
            INTO asutus_id;

    END IF;

    RETURN asutus_id;

END;
$BODY$;


GRANT EXECUTE ON FUNCTION libs.sp_salvesta_asutus(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_asutus(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*
select libs.sp_salvesta_asutus('{"id":0,"data":{"aa":"","aadress":"","doc_type_id":"","email":"","faks":"","id":0,"kehtivus":"        ","kmkr":"","kontakt":"","mark":"","muud":"","nimetus":"test hoosiik","omvorm":"ISIK","pank":"","regkood":"232132132132","staatus":0,"tel":"","tp":"","userid":0,"valid":"        ","asutus_aa":[]}}'::json, 70::integer, 63::integer) as id
*/