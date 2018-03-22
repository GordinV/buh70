DROP FUNCTION IF EXISTS eelarve.sp_eelproj_allkiri( INTEGER, INTEGER );
DROP FUNCTION IF EXISTS eelarve.sp_eelproj_allkiri( INTEGER, JSON );

CREATE FUNCTION eelarve.sp_eelproj_allkiri(tnAmetnikId   INTEGER, params JSON,
  OUT                                      error_code    INTEGER,
  OUT                                      result        INTEGER,
  OUT                                      error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  tnId            INTEGER = params ->> 'eelproj_id';
  lnresult        INTEGER;
  tmpEelProj      RECORD;
  new_history     JSONB;
BEGIN

  lnresult = 0;

  SELECT *
  INTO tmpEelProj
  FROM eelarve.eelproj
  WHERE id = tnid;

  IF tmpEelProj.status = array_position((enum_range(NULL :: DOK_STATUS)), 'active')
  THEN

    -- ajalugu
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()             AS updated,
            (SELECT kasutaja
             FROM ou.userid
             WHERE id = tnAmetnikId
             LIMIT 1) :: TEXT AS user,
            'allkirjastatud'  AS status
         ) row;

    --	* see tahendab et ainult uks voimas allkirjustada eelrve projekt kui staatus = 1
    UPDATE eelarve.eelproj
    SET status  = array_position((enum_range(NULL :: DOK_STATUS)), 'closed'),
      kinnitaja = tnAmetnikId,
      ajalugu   = ajalugu || new_history
    WHERE id = tnid;

    SELECT *
    INTO error_code, result, error_message
    FROM eelarve.sp_eelproj_kinnitamine(tnAmetnikId, params);

    IF (error_code IS NULL OR error_code = 0) AND result IS NULL
    THEN
      result = 1;
    END IF;
  ELSE
    error_code = 1;
    error_message = 'status != 1';
    result = 0;
  END IF;

  RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION eelarve.sp_eelproj_allkiri( INTEGER, JSON ) TO eelaktsepterja;

/*
select * from eelarve.eelproj where id = 3
select error_code, result, error_message from eelarve.sp_eelproj_allkiri(3, 1);

*/