DROP FUNCTION IF EXISTS eelarve.sp_taotlus_allkiri( INTEGER, JSON );

CREATE FUNCTION eelarve.sp_taotlus_allkiri(user_id INTEGER, params JSON, OUT error_code INTEGER, OUT result INTEGER,
                                                                         OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  doc_id      INTEGER = coalesce((params ->> 'doc_id') :: INTEGER, 0);

  result      INTEGER;
  tmpTaotlus  RECORD;
  tmpEelProj  RECORD;

  lnEelProjId INTEGER;
  l_proj_json JSON;
  l_proj_row  RECORD;
  new_history JSON;
BEGIN

  IF doc_id IS NULL
  THEN
    error_code = 6;
    error_message = 'Parameter doc_id not exists, docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RETURN;
  END IF;

  SELECT t.*
  INTO tmpTaotlus
  FROM eelarve.taotlus t, ou.userid u
  WHERE t.parentid = doc_id
  and u.id = user_id
  and coalesce((u.roles->>'is_eel_allkirjastaja')::boolean,false)::BOOLEAN;
--        AND docs.usersRigths(t.parentid, 'EelAllkirjastaja', user_id);

 -- @todo довести права до ума

  IF tmpTaotlus.id IS NULL
  THEN
    error_code = 6;
    error_message = 'Document not exists or not enough rights , docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RETURN;
  END IF;

  --* eelarve projektide side
  SELECT
    e.id,
    e.status
  INTO tmpEelProj
  FROM eelarve.eelproj e
  WHERE e.aasta = tmptaotlus.aasta AND e.status > 0 AND
        e.status < array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'aktsepteeritud') AND
        e.rekvid = tmpTaotlus.rekvid
  ORDER BY status DESC
  LIMIT 1;

  IF tmpEelProj IS NOT NULL
  THEN
    lnEelProjId = tmpEelProj.id;
  ELSE
    --		* puudub eelarve variant
    --		lnresult = -1;

    SELECT
      tmpTaotlus.rekvid AS rekvid,
      tmpTaotlus.aasta  AS aasta,
      tmpTaotlus.kuu    AS kuu,
      0                 AS kinnitaja,
      NULL :: TEXT      AS muud
    INTO l_proj_row;

    SELECT row_to_json(row)
    INTO l_proj_json
    FROM
      (SELECT
         0          AS id,
         l_proj_row AS data
      ) row;

    lnEelProjId = eelarve.sp_salvesta_eelproj(l_proj_json, user_id, tmpTaotlus.rekvid);

  END IF;

  IF lnEelProjId > 0 -- saved successfuly
  THEN
    UPDATE eelarve.taotlus1
    SET eelprojid = lnEelProjId
    WHERE parentid = tmpTaotlus.id;
  END IF;

  IF empty(tmptaotlus.allkiri)
  THEN
    UPDATE eelarve.taotlus
    SET status   = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'allkirjastatud'),
      allkiri    = 1,
      KoostajaID = user_id
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
            'allkirjastatud'  AS status
         ) row;

    -- will check if arvId exists
    UPDATE docs.doc
    SET
      lastupdate = now(),
      status     = array_position((enum_range(NULL :: DOK_STATUS)), 'active'),
      history    = coalesce(history, '[]') :: JSONB || new_history :: JSONB
    WHERE id = doc_id;


    result = 1;
  ELSE
    error_message = 'Taotlus juba allkirjastatud';
    result = 0;
  END IF;

  RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION eelarve.sp_taotlus_allkiri(INTEGER, JSON) TO eelallkirjastaja;


