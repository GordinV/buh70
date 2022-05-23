DROP FUNCTION IF EXISTS lapsed.sp_salvesta_day_taabel(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_day_taabel(data JSONB,
                                                         user_id INTEGER,
                                                         user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    tab_id       INTEGER;
    tab1_id      INTEGER;
    userName     TEXT;
    doc_id       INTEGER = data ->> 'id';
    doc_data     JSON    = data ->> 'data';
    doc_kpv      DATE    = doc_data ->> 'kpv';
    doc_grupp_id INTEGER = doc_data ->> 'grupp_id';
    doc_muud     TEXT    = doc_data ->> 'muud';
    doc_details  JSONB   = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');

    json_object  JSONB;
    json_record  RECORD;
    new_history  JSONB;
    ids          INTEGER[];

BEGIN

    RAISE NOTICE 'doc_details %', doc_details;


    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;

    IF userName IS NULL
    THEN
        RAISE EXCEPTION 'User not found %', user;
    END IF;


    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        INSERT INTO lapsed.day_taabel (rekv_id, kpv, grupp_id, muud, ajalugu)
        VALUES (user_rekvid, doc_kpv, doc_grupp_id, doc_muud, '[]' :: JSONB || new_history) RETURNING id
            INTO tab_id;
    ELSE
        -- history
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        UPDATE lapsed.day_taabel
        SET kpv      = doc_kpv,
            grupp_id = doc_grupp_id,
            muud     = doc_muud,
            ajalugu  = coalesce(ajalugu, '[]') :: JSONB || new_history
        WHERE id = doc_id RETURNING id
            INTO tab_id;
    END IF;

    -- вставка в таблицы документа
    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details::JSON)
        LOOP
            SELECT *
            INTO json_record
            FROM jsonb_to_record(
                         json_object) AS x (id TEXT, nom_id INTEGER, laps_id INTEGER, kogus NUMERIC(14, 4),
                                            osalemine INTEGER, covid INTEGER, muud TEXT);

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN
                INSERT INTO lapsed.day_taabel1 (parent_id, nom_id, laps_id, kogus, osalemine, covid, muud)
                VALUES (tab_id, json_record.nom_id, json_record.laps_id, json_record.kogus,
                        coalesce(json_record.osalemine, 0), coalesce(json_record.covid, 0),
                        json_record.muud);
            ELSE
                UPDATE lapsed.day_taabel1
                SET nom_id    = json_record.nom_id,
                    laps_id= json_record.laps_id,
                    kogus     = json_record.kogus,
                    osalemine = coalesce(json_record.osalemine),
                    covid     = coalesce(json_record.covid),
                    muud      = json_record.muud
                WHERE id = json_record.id :: INTEGER RETURNING id INTO tab1_id;
            END IF;
            -- add new id into array of ids
            ids = array_append(ids, tab1_id);

        END LOOP;

    -- delete record which not in json
    IF array_length(ids, 1) > 0
    THEN
        DELETE
        FROM lapsed.day_taabel1
        WHERE parent_id = tab_id
          AND id NOT IN (SELECT unnest(ids));
    END IF;

    RETURN tab_id;

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

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_day_taabel(JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_day_taabel(JSONB, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT lapsed.sp_salvesta_day_taabel('{"userId":70,"asutusId":63,"data":{"data":{"docTypeId":"PAEVA_TAABEL","module":"lapsed","userId":70,"uuid":"9897c560-da68-11ec-b791-154be7046f65","docId":45720,"context":null,"id":45720,"userid":"70","kpv":"2022-05-23","kpv_print":"23.05.2022","muud":null,"grupp_id":214218,"yksus":"Sekretar","yksuse_nimi":"Sekretar","status":"Aktiivne                                                                                                                                                                                                                                                      ","doc_status":1,"noms":[{"nom_id":19130,"teenus":null},{"nom_id":19129,"teenus":null},{"nom_id":11145,"teenus":null},{"nom_id":17941,"teenus":"sekretari koolitus"},{"nom_id":19131,"teenus":"2.Lõuna"}],"row":[{"id":45720,"userid":"70","kpv":"2022-05-23","kpv_print":"23.05.2022","muud":null,"grupp_id":214218,"yksus":"Sekretar","yksuse_nimi":"Sekretar","status":"Aktiivne                                                                                                                                                                                                                                                      ","doc_status":1,"noms":[{"nom_id":19130,"teenus":null},{"nom_id":19129,"teenus":null},{"nom_id":11145,"teenus":null},{"nom_id":17941,"teenus":"sekretari koolitus"},{"nom_id":19131,"teenus":"2.Lõuna"}]}],"details":[{"userid":"70","id":"1","parent_id":45720,"lapsid":5573,"isikukood":"47608105226","nimi":"Jelena Golubeva","viitenr":"0630055739","grupp_id":214218,"rekvid":63,"osalemine":1,"covid":0,"noms":[{"nom_id":19131,"teenus":"2.Lõuna","kogus":1,"id":2900237}]}],"gridConfig":[{"id":"id","name":"Rea nr","width":"10px","show":true,"type":"text","readOnly":true},{"id":"isikukood","name":"Isikukood","width":"50px","show":false,"type":"text","readOnly":true},{"id":"viitenr","name":"Viitenumber","width":"50px","show":true,"type":"text","readOnly":true},{"id":"nimi","name":"Nimi","width":"100px","show":true,"type":"text","readOnly":true},{"id":"osalemine","name":"Külastamine","width":"50px","show":true,"type":"boolean","readOnly":false,"boolSumbolYes":"●","yesBackgroundColor":"#b9edb9","boolSumbolNo":"✖"},{"id":"covid","name":"COVID","width":"50px","show":true,"type":"boolean","readOnly":false,"boolSumbolYes":"●","yesBackgroundColor":"#b9edb9","boolSumbolNo":"✖"},{"id":"17941","name":"sekretari koolitus","width":"50px","type":"boolean"},{"id":"19131","name":"2.Lõuna","width":"50px","type":"boolean"}],"gridData":[{"19131":false,"userid":"70","id":"1","parent_id":45720,"lapsid":5573,"isikukood":"47608105226","nimi":"Jelena Golubeva","viitenr":"0630055739","grupp_id":214218,"rekvid":63,"osalemine":false,"covid":true,"noms":[{"nom_id":19131,"teenus":"2.Lõuna","kogus":1,"id":2900237}]}],,"gridData":[{"19131":false,"userid":"70","id":"1","parent_id":45720,"lapsid":5573,"isikukood":"47608105226","nimi":"Jelena Golubeva","viitenr":"0630055739","grupp_id":214218,"rekvid":63,"osalemine":false,"covid":true,"noms":[{"nom_id":19131,"teenus":"2.Lõuna","kogus":1,"id":2900237}]}]}}}'
,70, 63)

select * from lapsed.day_taabel1
*/


