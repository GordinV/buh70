DROP FUNCTION IF EXISTS eelarve.sp_taotlus_tuhista( INTEGER, JSON );

CREATE FUNCTION eelarve.sp_taotlus_tuhista(user_id INTEGER, params JSON, OUT error_code INTEGER, OUT result INTEGER,
                                                                         OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  doc_id     INTEGER = coalesce((params ->> 'doc_id') :: INTEGER, 0);
  tcLiik     TEXT = params ->> 'liik';
  tcMuud     TEXT = params ->> 'muud';

  c_oigus    TEXT = CASE WHEN tcLiik = 'ALLKIRI'
    THEN 'EelAllkirjastaja'
                    ELSE 'Eelesitaja' END;
  tmpTaotlus RECORD;

BEGIN

  IF doc_id IS NULL
  THEN
    error_code = 6;
    error_message = 'Parameter doc_id not exists, docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RETURN;
  END IF;


  raise notice ' c_oigus -> %', c_oigus;
  SELECT t.*
  INTO tmpTaotlus
  FROM eelarve.taotlus t
  WHERE t.parentid = doc_id
        AND docs.usersRigths(t.parentid, c_oigus, user_id);

  IF tmpTaotlus IS NULL
  THEN
    error_code = 6;
    error_message = 'Document not exists or not enough rights , docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RETURN;
  END IF;

  IF tmpTaotlus.status > array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'esitatud')
  THEN
    error_code = 7;
    error_message = 'Vale taotluse staatus , docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  /*
    SELECT
      taotlus.*,
      taotlus1.eelprojId
    INTO tmpTaotlus
    FROM taotlus
      INNER JOIN taotlus1 ON taotlus.id = taotlus1.parentid
    WHERE taotlus.id = doc_id;
  */

  IF tcLiik = 'ALLKIRI'
  THEN

    IF NOT empty(tmptaotlus.allkiri)
    THEN
      UPDATE eelarve.taotlus
      SET status  = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'allkirjastatud'),
        allkiri    = 0,
        KoostajaID = user_id,
        muud       = muud || chr(13) || current_user :: TEXT || ':' + tcMuud
      WHERE parentid = doc_id;

      RAISE NOTICE 'allkiri on tuhistatud';
      result = 1;

    ELSE
      RAISE NOTICE 'ei saa tuhistatda allkiri, allkiri = 0';
      result = 0;
      error_message = 'Ei saa tuhistatda allkiri, allkiri = 0 , docId: ' || coalesce(doc_id, 0) :: TEXT;
      RETURN;
    END IF;
  END IF;

  IF tcLiik = 'ESITA'
  THEN
    IF exists(SELECT id
              FROM eelarve.eelproj
              WHERE id IN (SELECT eelprojId
                           FROM eelarve.taotlus1 t1
                           WHERE parentid = tmptaotlus.id)
                    AND status = array_position((enum_range(NULL :: DOK_STATUS)), 'active')
                    AND NOT empty(kinnitaja))
    THEN
      RAISE NOTICE 'ei saa tuhistada esitamine, eelarve projekt on kinnitatud';
      result = 0;
      error_message = 'Ei saa tuhistada esitamine, eelarve projekt on kinnitatud, docId: ' ||
                      coalesce(doc_id, 0) :: TEXT;
      RETURN;
    END IF;

    RAISE NOTICE 'Esitamine tuhistamine ..';
    IF tmptaotlus.status = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'esitatud')
    THEN
      UPDATE eelarve.taotlus
      SET status  = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'allkirjastatud'),
        allkiri   = 1,
        ametnikid = 0,
        muud      = muud || chr(13) || current_user :: TEXT || ':' || tcMuud
      WHERE parentid = doc_id;

      RAISE NOTICE 'esitamine on tuhistatud';
      result = 1;
    ELSE
      RAISE NOTICE 'ei saa tuhistada esitamine, staatus = 1';
      error_message = 'ei saa tuhistada esitamine, staatus = allkirjastatud, docId: ' || coalesce(doc_id, 0) :: TEXT;
      result = 0;
    END IF;

  END IF;

  RETURN;

END;
$$;


GRANT EXECUTE ON FUNCTION eelarve.sp_taotlus_tuhista(INTEGER, JSON) TO eelallkirjastaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_taotlus_tuhista(INTEGER, JSON) TO eelesitaja;


/*

	select * from eelarve.sp_taotlus_tuhista(1,'{"doc_id":1308,"muud":"test","liik":"ALLKIRI"}')
				{"doc_id":?tnId,"muud":"test","liik":"ALLKIRI"}
 select * from eelarve.taotlus where parentid = 1310



 */
