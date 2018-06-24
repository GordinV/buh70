DROP FUNCTION IF EXISTS rekl.sp_muuda_lubastaatus( INTEGER, INTEGER );
DROP FUNCTION IF EXISTS rekl.sp_muuda_lubastaatus( INTEGER, JSON );

CREATE FUNCTION rekl.sp_muuda_lubastaatus(IN  user_id    INTEGER, IN params JSON, OUT result INTEGER,
                                          OUT error_code INTEGER, OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  l_id          INTEGER = params ->> 'id';
  l_new_staatus INTEGER = params ->> 'staatus';
  v_user        RECORD;
BEGIN
  SELECT
    kasutaja,
    rekvid
  INTO v_user
  FROM ou.userid u
  WHERE u.id = user_Id;

  IF v_user.kasutaja IS NULL
  THEN
    error_code = 5;
    error_message = 'Kasutaja ei leitud,  userId:' ||
                    coalesce(user_id, 0) :: TEXT;
    result = 0;
    RETURN;
  END IF;

  IF l_new_staatus > 1
  THEN
    error_code = 6;
    error_message = 'Vale parameter:' ||
                    coalesce(l_new_staatus, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  -- 0 - arhiiv, 1 - aktiivne
  UPDATE rekl.luba
  SET staatus = l_new_staatus
  WHERE parentid = l_id;
  result = 1;
  RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION rekl.sp_muuda_lubastaatus(user_id INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_muuda_lubastaatus(user_id INTEGER, params JSON) TO dbpeakasutaja;
