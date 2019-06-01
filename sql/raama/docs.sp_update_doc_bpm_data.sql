-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_update_doc_bpm_data(l_doc_id INTEGER, user_id INTEGER, params JSONB);

CREATE OR REPLACE FUNCTION docs.sp_update_doc_bpm_data(l_doc_id INTEGER, user_id INTEGER, params JSONB)
    RETURNS INTEGER AS
$BODY$

DECLARE
    doc_omniva  JSONB = params ->> 'omniva';
    json_object JSONB;
    new_history JSONB;
    userName    TEXT  = (SELECT ametnik
                         FROM ou.userid
                         WHERE id = user_id);
BEGIN
    IF userName IS NULL
    THEN
        RAISE EXCEPTION 'User not found %', user;
        RETURN 0;
    END IF;

    -- update docs.doc

    json_object = (SELECT to_jsonb(row)
                   FROM (SELECT doc_omniva :: JSONB AS omniva) row);

    -- ajalugu


    SELECT row_to_json(row) INTO new_history
    FROM (SELECT now()    AS bpm_updated,
                 userName AS user) row;

    UPDATE docs.doc
    SET bpm        = coalesce(bpm, '{}'::JSONB) || json_object,
        lastupdate = now(),
        history    = coalesce(history, '[]') :: JSONB || new_history
    WHERE id = l_doc_id;


    RETURN l_doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_update_doc_bpm_data(l_doc_id INTEGER, user_id INTEGER, params JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_update_doc_bpm_data(l_doc_id INTEGER, user_id INTEGER, params JSONB) TO dbpeakasutaja;


/*
select docs.sp_update_doc_bpm_data(1614158, 70, '{"omniva":[{"isik":"koostaja", "kpv":"2019-05-31","rolli":"creator"},{"isik":"koostaja", "kpv":"2019-05-31","rolli":"kinnitaja"}]}')


 */