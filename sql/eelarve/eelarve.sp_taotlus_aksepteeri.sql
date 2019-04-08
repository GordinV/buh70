DROP FUNCTION IF EXISTS eelarve.sp_taotlus_aktsepteeri(INTEGER, JSON);

CREATE FUNCTION eelarve.sp_taotlus_aktsepteeri(user_id INTEGER, params JSON, OUT error_code INTEGER, OUT result INTEGER,
                                               OUT error_message TEXT)
  RETURNS RECORD
  LANGUAGE plpgsql
AS
$$
DECLARE
  doc_id      INTEGER = coalesce((params ->> 'doc_id') :: INTEGER, 0);
  ttMuud      TEXT    = params ->> 'muud';
  new_history JSON;
  new_eelarve JSON;

  lnTunnus    INTEGER = 0;

  lnId        INTEGER;

  tmpEelProj  RECORD;
  tmpTaotlus  RECORD;
  tmpTaotlus1 RECORD;
  tmpEelarve  RECORD;

  ldKpv       DATE;
  lcSelg      TEXT;
  lnKuurs     NUMERIC;
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
  FROM eelarve.taotlus t,
       ou.userid u
  WHERE t.parentid = doc_id
    AND u.id = user_id
    AND coalesce((u.roles ->> 'is_eel_aktsepterja') :: BOOLEAN, FALSE) :: BOOLEAN;
  --        AND docs.usersRigths(t.parentid, 'EelAktsepterja', user_id);

  IF tmpTaotlus IS NULL
  THEN
    error_code = 6;
    error_message = 'Document not exists or not enough rights , docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RETURN;
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
    FROM (SELECT
            now()             AS updated,
            (SELECT kasutaja
             FROM ou.userid
             WHERE id = user_id
             LIMIT 1) :: TEXT AS user,
            'aktsepteeri'     AS status
         ) row;

    -- will check if arvId exists
    UPDATE docs.doc
    SET
      lastupdate = now(),
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
