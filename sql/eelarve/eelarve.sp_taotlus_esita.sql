DROP FUNCTION IF EXISTS eelarve.sp_taotlus_esita( INTEGER, JSON );

CREATE FUNCTION eelarve.sp_taotlus_esita(user_id INTEGER, params JSON, OUT error_code INTEGER, OUT result INTEGER,
                                                                       OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  doc_id      INTEGER = coalesce((params ->> 'doc_id') :: INTEGER, 0);
  tmpTaotlus  RECORD;
  new_history JSON;
BEGIN

  IF doc_id IS NULL
  THEN

    error_code = 6;
    error_message = 'Parameter doc_id not exists, docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;

    RAISE NOTICE 'viga, %', error_message;
    RETURN;
  END IF;

  SELECT t.*
  INTO tmpTaotlus
  FROM eelarve.taotlus t, ou.userid u
  WHERE t.parentid = doc_id
        and u.id = user_id
        and coalesce((u.roles->>'is_eel_esitaja')::boolean,false)::BOOLEAN;
  --        AND docs.usersRigths(t.parentid, 'Eelesitaja', user_id);

  IF tmpTaotlus IS NULL
  THEN
    error_code = 6;
    error_message = 'Document not exists or not enough rights , docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;

    RETURN;
  END IF;

  IF NOT empty(tmpTaotlus.allkiri)
  THEN
    UPDATE eelarve.taotlus
    SET
      status    = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'esitatud'),
      AmetnikID = user_id
    WHERE parentid = doc_id;

    -- ajalugu
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()             AS updated,
            (SELECT kasutaja
             FROM ou.userid
             WHERE id = user_id
             LIMIT 1) :: TEXT AS user,
            'esitatud'        AS status
         ) row;

    -- will check if arvId exists
    UPDATE docs.doc
    SET
      lastupdate = now(),
      history    = coalesce(history, '[]') :: JSONB || new_history :: JSONB
    WHERE id = doc_id;


    result = 1;
  ELSE
    error_message = 'Puudub allkiri';
    result = 0;
    RAISE NOTICE 'viga, %', error_message;

  END IF;
  RETURN;

END;
$$;


GRANT EXECUTE ON FUNCTION eelarve.sp_taotlus_esita(INTEGER, JSON) TO eelesitaja;
