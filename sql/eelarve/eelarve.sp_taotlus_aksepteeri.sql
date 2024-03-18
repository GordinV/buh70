DROP FUNCTION IF EXISTS eelarve.sp_taotlus_aktsepteeri(INTEGER, JSON);

CREATE FUNCTION eelarve.sp_taotlus_aktsepteeri(user_id INTEGER, params JSON, OUT error_code INTEGER, OUT result INTEGER,
                                               OUT error_message TEXT)
    RETURNS RECORD
    LANGUAGE plpgsql
AS
$$
DECLARE
    doc_id      INTEGER ;
    ttMuud      TEXT;
    new_history JSON;
    tmpTaotlus  RECORD;
    tmpEelProj  RECORD;
    lnEelProjId INTEGER;
BEGIN
    doc_id = coalesce((params ->> 'doc_id') :: INTEGER, 0);
    ttMuud = params ->> 'muud';

    IF doc_id IS NULL
    THEN
        error_code = 6;
        error_message = 'Parameter doc_id not exists, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;
    END IF;


    SELECT t.*
    INTO tmpTaotlus
    FROM eelarve.taotlus t,
         ou.userid u
    WHERE t.parentid = doc_id
      AND u.id = user_id
      AND coalesce((u.roles ->> 'is_eel_aktsepterja') :: BOOLEAN, FALSE) :: BOOLEAN;

    IF tmpTaotlus IS NULL
    THEN
        error_code = 6;
        error_message = 'Document not exists or not enough rights , docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;
    END IF;

    -- проверка на проект

--* eelarve projektide side
    SELECT e.id,
           e.status
    INTO tmpEelProj
    FROM eelarve.eelproj e
    WHERE e.aasta = tmptaotlus.aasta
      AND e.rekvid = tmpTaotlus.rekvid
    ORDER BY status DESC
    LIMIT 1;

    IF tmpEelProj IS NOT NULL
    THEN
        lnEelProjId = tmpEelProj.id;
    ELSE
        SELECT p.result
        INTO lnEelProjId
        FROM eelarve.koosta_eelproj(user_id,
                                    json_build_object('rekvid', tmpTaotlus.rekvid, 'aasta', tmpTaotlus.aasta,
                                                      'muud', tmpTaotlus.muud)) p;

        UPDATE eelarve.taotlus1
        SET eelprojid = lnEelProjId
        WHERE parentid in (select id from eelarve.taotlus where taotlus.parentid = doc_id);
    END IF;

    IF tmpTaotlus.status = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'esitatud')
    THEN
        UPDATE eelarve.taotlus
        SET status    = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'aktsepteeritud'),
            aktseptid = user_id,
            muud      = coalesce(muud, '') || coalesce(ttMuud, ''),
            timestamp = now()
        WHERE parentid = doc_id;


        -- ajalugu
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()             AS updated,
                     (SELECT kasutaja
                      FROM ou.userid
                      WHERE id = user_id
                      LIMIT 1) :: TEXT AS user,
                     'aktsepteeri'     AS status
             ) row;

        -- update status
        UPDATE docs.doc
        SET lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history :: JSONB,
            status     = array_position((enum_range(NULL :: DOK_STATUS)), 'closed')
        WHERE id = doc_id;

        result = 1;
    ELSE
        result = 0;
        error_message = 'Vale taotluse staatus';
        RETURN;
    END IF;


    SELECT *
    INTO error_code, result, error_message
    FROM eelarve.sp_eelproj_kinnitamine(user_id, ('{"taotlus_id":' || doc_id :: TEXT || '}') :: JSON);

    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION eelarve.sp_taotlus_aktsepteeri(INTEGER, JSON) TO eelaktsepterja;

/*
select * from  eelarve.sp_taotlus_aktsepteeri(2477, '{"doc_id":2487197, "muud":"test 2 akts"}'::json)
select * from eelarve.taotlus ORDER BY id desc limit 10
 */

