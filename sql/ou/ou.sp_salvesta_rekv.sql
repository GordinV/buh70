DROP FUNCTION IF EXISTS ou.sp_salvesta_rekv(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION ou.sp_salvesta_rekv(data JSON,
                                               user_id INTEGER,
                                               user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    rekv_id                INTEGER;
    userName               TEXT;
    doc_id                 INTEGER = data ->> 'id';
    doc_data               JSON    = data ->> 'data';
    doc_parentid           INTEGER = doc_data ->> 'parentid';
    doc_regkood            TEXT    = doc_data ->> 'regkood';
    doc_nimetus            TEXT    = doc_data ->> 'nimetus';
    doc_kbmkood            TEXT    = doc_data ->> 'kbmkood';
    doc_aadress            TEXT    = doc_data ->> 'aadress';
    doc_haldus             TEXT    = doc_data ->> 'haldus';
    doc_tel                TEXT    = doc_data ->> 'tel';
    doc_faks               TEXT    = doc_data ->> 'faks';
    doc_email              TEXT    = doc_data ->> 'email';
    doc_juht               TEXT    = doc_data ->> 'juht';
    doc_raama              TEXT    = doc_data ->> 'raama';
    doc_muud               TEXT    = doc_data ->> 'muud';
    doc_ftp                TEXT    = doc_data ->> 'ftp';
    doc_login              TEXT    = doc_data ->> 'login';
    doc_parool             TEXT    = doc_data ->> 'parool';
    doc_tahtpaev           INTEGER = doc_data ->> 'tahtpaev';
    doc_earved             TEXT    = doc_data ->> 'earved';
    doc_liik               TEXT    = doc_data ->> 'liik';
    doc_earve_regkood      TEXT    = doc_data ->> 'earve_regkood'; -- рег.код учреждения для эл. счетов
    doc_earve_asutuse_nimi TEXT    = doc_data ->> 'earve_asutuse_nimi'; -- наименование учреждения для эл. счетов
    doc_seb                TEXT    = doc_data ->> 'seb'; -- имя пользователя себ для эл. счетов
    doc_seb_earve          TEXT    = doc_data ->> 'seb_earve'; -- расч. счет для отправки эл. счетов в банк
    doc_swed               TEXT    = doc_data ->> 'swed'; -- имя пользователя свед для эл. счетов
    doc_swed_earve         TEXT    = doc_data ->> 'swed_earve'; -- расч. счет для отправки эл. счетов в банк

    doc_details            JSON    = doc_data ->> 'gridData';
    detail_id              INTEGER;
    json_object            JSONB;
    json_arved             JSONB;
    json_record            RECORD;
    ids                    INTEGER[];

    new_history            JSON;
    aa_history             JSON;
    user_json              JSON;
    v_user                 RECORD;
    new_user_id            INTEGER;
    is_import              BOOLEAN = data ->> 'import';

BEGIN

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE EXCEPTION 'User not found %', user;
        RETURN 0;
    END IF;

    -- rekl ftp andmed
    json_object = (SELECT to_jsonb(row)
                   FROM (SELECT doc_ftp    AS ftp,
                                doc_login  AS login,
                                doc_parool AS parool) row);

    json_object = (SELECT to_jsonb(row)
                   FROM (SELECT json_object :: JSONB AS reklftp) row);

    -- arved properties

    json_arved = (SELECT to_jsonb(row)
                  FROM (SELECT doc_tahtpaev AS tahtpaev) row);

    json_object = json_object || (SELECT to_jsonb(row)
                                  FROM (SELECT json_arved :: JSONB    AS arved,
                                               doc_earved             AS earved,
                                               doc_liik               AS liik,
                                               doc_earve_regkood      AS earve_regkood,
                                               doc_earve_asutuse_nimi AS earve_asutuse_nimi,
                                               doc_seb                AS seb,
                                               doc_seb_earve          AS seb_earve,
                                               doc_swed               AS swed,
                                               doc_swed_earve         AS swed_earve
                                       ) row);


    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;


    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN


        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;


        INSERT INTO ou.rekv (parentid, regkood, nimetus, kbmkood, aadress, haldus, tel, faks, email, juht, raama, muud,
                             ajalugu, status, properties)
        VALUES (doc_parentid, doc_regkood, doc_nimetus, doc_kbmkood, doc_aadress, doc_haldus, doc_tel, doc_faks,
                doc_email,
                doc_juht, doc_raama, doc_muud, new_history,
                array_position((enum_range(NULL :: DOK_STATUS)), 'active'), json_object) RETURNING id
                   INTO rekv_id;

        -- should insert admin user

        SELECT 0                              AS id,
               rekv_id                        AS rekvid,
               ltrim(rtrim(kasutaja)) :: TEXT AS kasutaja,
               ltrim(rtrim(ametnik)) :: TEXT  AS ametnik,
               kasutaja_,
               peakasutaja_,
               admin,
               muud
               INTO v_user
        FROM ou.userid
        WHERE id = user_id;

        SELECT row_to_json(row) INTO user_json
        FROM (SELECT 0         AS id,
                     is_import AS import,
                     v_user    AS data) row;

/*        new_user_id = ou.sp_salvesta_userid(user_json, user_id, rekv_id);

        IF new_user_id IS NULL OR new_user_id = 0
        THEN
            RAISE EXCEPTION 'Uue kasutaja salvestamine eba õnnestus';
        END IF;
*/
    ELSE

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user,
                     r.*
              FROM ou.rekv r
              WHERE r.id = doc_id) row;

        -- save aa old state

        SELECT array_to_json(array_agg(row_to_json(row_data))) INTO aa_history
        FROM (SELECT aa.*
              FROM ou.aa aa
              WHERE aa.parentid = doc_id) row_data;

        aa_history = ('{"aa":' || aa_history :: TEXT || '}') :: JSON;
        new_history = new_history :: JSONB || aa_history :: JSONB;

        UPDATE ou.rekv
        SET 
--            parentid   = doc_parentid,
            regkood    = doc_regkood,
            kbmkood    = doc_kbmkood,
            nimetus    = doc_nimetus,
            aadress    = doc_aadress,
            haldus     = doc_haldus,
            tel        = doc_tel,
            faks       = doc_faks,
            email      = doc_email,
            juht       = doc_juht,
            raama      = doc_raama,
            muud       = doc_muud,
            ajalugu    = new_history,
            properties = coalesce(properties :: JSONB, '{}' :: JSONB) || json_object :: JSONB
        WHERE id = doc_id RETURNING id
            INTO rekv_id;
    END IF;

    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details)
        LOOP
            SELECT * INTO json_record
            FROM jsonb_to_record(
                         json_object) AS x (id TEXT, parentid INTEGER, arve TEXT, nimetus TEXT, default_ BOOLEAN,
                                            kassa INTEGER,
                                            pank INTEGER,
                                            konto TEXT, tp TEXT, muud TEXT, kassapank INTEGER);

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN


                INSERT INTO ou.aa (parentid, arve, nimetus, default_, kassa, pank, konto, tp, muud)
                VALUES (user_rekvid, json_record.arve, json_record.nimetus,
                        (CASE WHEN json_record.default_ IS NULL OR NOT json_record.default_ THEN 0 ELSE 1 END),
                        json_record.kassapank, coalesce(json_record.pank, 1), json_record.konto, json_record.tp,
                        json_record.muud) RETURNING id
                           INTO detail_id;

            ELSE
                UPDATE ou.aa
                SET arve     = json_record.arve,
                    nimetus  = json_record.nimetus,
                    default_ = (CASE WHEN json_record.default_ IS NULL OR NOT (json_record.default_) THEN 0 ELSE 1 END),
                    kassa    = json_record.kassapank,
                    pank     = json_record.pank,
                    konto    = json_record.konto,
                    tp       = json_record.tp,
                    muud     = json_record.muud
                WHERE id = json_record.id :: INTEGER RETURNING id
                    INTO detail_id;
            END IF;

            -- add new id into array of ids
            ids = array_append(ids, detail_id);
        END LOOP;

    -- delete record which not in json

    DELETE
    FROM ou.aa
    WHERE parentid = doc_id
      AND id NOT IN (SELECT unnest(ids));

    RETURN rekv_id;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE EXCEPTION 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION ou.sp_salvesta_rekv(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_rekv(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT ou.sp_salvesta_rekv('{"id":1,"data":{"docTypeId":"REKV","module":"lapsed","userId":70,"uuid":"679c46a0-181b-11ea-9662-c7e1326a899d","docId":63,"context":null,"doc_type_id":"REKV","userid":70,"id":63,"parentid":0,"nimetus":"RAHANDUSAMET T","aadress":"Peetri 5, Narva","email":"rahandus@narva.ee","faks":"3599181","haldus":"","juht":"Jelena Golubeva","raama":"Jelena Tsekanina","kbmkood":"","muud":"Narva Linnavalitsuse Rahandusamet","regkood":"75008427","tel":"3599190","tahtpaev":null,"ftp":null,"login":null,"parool":null,"earved":"106549:elbevswsackajyafdoupavfwewuiafbeeiqatgvyqcqdqxairz","earved_omniva":"https://finance.omniva.eu/finance/erp/","row":[{"doc_type_id":"REKV","userid":70,"id":63,"parentid":0,"nimetus":"RAHANDUSAMET T","aadress":"Peetri 5, Narva","email":"rahandus@narva.ee","faks":"3599181","haldus":"","juht":"Jelena Golubeva","raama":"Jelena Tsekanina","kbmkood":"","muud":"Narva Linnavalitsuse Rahandusamet","regkood":"75008427","tel":"3599190","tahtpaev":null,"ftp":null,"login":null,"parool":null,"earved":"106549:elbevswsackajyafdoupavfwewuiafbeeiqatgvyqcqdqxairz","earved_omniva":"https://finance.omniva.eu/finance/erp/"}],"details":[{"id":1,"arve":"TP                  ","nimetus":"RAHANDUSAMET                                                                                                                                                                                                                                                  ","default_":1,"kassa":2,"pank":1,"konto":"","tp":"18510101","kassapank":2,"userid":"70"},{"id":2,"arve":"EE051010562011276005","nimetus":"SEB                                                                                                                                                                                                                                                           ","default_":1,"kassa":1,"pank":401,"konto":"10010002","tp":"800401","kassapank":1,"userid":"70"},{"id":3,"arve":"kassa               ","nimetus":"Kassa                                                                                                                                                                                                                                                         ","default_":1,"kassa":0,"pank":1,"konto":"100000","tp":"18510101","kassapank":0,"userid":"70"}],"gridConfig":[{"id":"id","name":"id","width":"0px","show":false,"type":"text","readOnly":true},{"id":"arve","name":"Arve","width":"100px","show":true,"type":"text","readOnly":false},{"id":"nimetus","name":"Nimetus","width":"300px","show":true,"readOnly":true},{"id":"konto","name":"Konto","width":"100px","show":true,"type":"text","readOnly":false},{"id":"tp","name":"TP","width":"100px","show":true,"type":"text","readOnly":false}],"default.json":[{"id":75,"number":"","rekvid":63,"toolbar1":0,"toolbar2":0,"toolbar3":0,"tahtpaev":14,"keel":2,"port":"465","smtp":"smtp.gmail.com","user":"vladislav.gordin@gmail.com","pass":"Vlad490710A","email":"vladislav.gordin@gmail.com","earved":"https://finance.omniva.eu/finance/erp/"}],"gridData":[{"id":"NEW0.352711495575625","arve":"EE712200221023241719","nimetus":"test arve","konto":"10010009","tp":"","kassapank":"1"},{"id":1,"arve":"TP                  ","nimetus":"RAHANDUSAMET                                                                                                                                                                                                                                                  ","default_":1,"kassa":2,"pank":1,"konto":"","tp":"18510101","kassapank":2,"userid":"70"},{"id":2,"arve":"EE051010562011276005","nimetus":"SEB                                                                                                                                                                                                                                                           ","default_":1,"kassa":1,"pank":401,"konto":"10010002","tp":"800401","kassapank":1,"userid":"70"},{"id":3,"arve":"kassa               ","nimetus":"Kassa                                                                                                                                                                                                                                                         ","default_":1,"kassa":0,"pank":1,"konto":"100000","tp":"18510101","kassapank":0,"userid":"70"}],"bpm":[],"requiredFields":[{"name":"regkood","type":"C"},{"name":"nimetus","type":"C"}]}}', 70, 63);

*/
