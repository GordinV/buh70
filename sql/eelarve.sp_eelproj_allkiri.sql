DROP FUNCTION IF EXISTS eelarve.sp_eelproj_allkiri( INTEGER, INTEGER );

CREATE FUNCTION eelarve.sp_eelproj_allkiri(tnId          INTEGER, tnAmetnikId INTEGER,
  OUT                                      error_code    INTEGER,
  OUT                                      result        INTEGER,
  OUT                                      error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE

  lnresult   INTEGER;
  tmpEelProj RECORD;
BEGIN

  lnresult = 0;

  SELECT *
  INTO tmpEelProj
  FROM eelarve.eelproj
  WHERE id = tnid;

  IF tmpEelProj.staatus = array_position((enum_range(NULL :: DOK_STATUS)), 'active')
  THEN
    --	* see tahendab et ainult uks voimas allkirjustada eelrve projekt kui staatus = 1

    UPDATE eelarve.eelproj
    SET staatus = array_position((enum_range(NULL :: DOK_STATUS)), 'closed'),
      kinnitaja = tnAmetnikId
    WHERE id = tnid;

    result = eelarve.sp_eelproj_kinnitamine(tnid);

  ELSE
    error_code = 1;
    error_message = 'status != 1';
    result = 0;
  END IF;

  RETURN;

END;
$$;


GRANT EXECUTE ON FUNCTION eelarve.sp_eelproj_allkiri(tnId INTEGER, tnAmetnikId INTEGER) TO eelaktsepterja;
