DROP FUNCTION IF EXISTS palk.change_kaart_status( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.change_kaart_status(
  IN  kaart_id      INTEGER,
  IN  user_id       INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
AS
$BODY$
DECLARE
  v_palk_kaart     RECORD;
  l_active_status  INTEGER = array_position((enum_range(NULL :: DOK_STATUS)), 'active');
  l_archive_status INTEGER = array_position((enum_range(NULL :: DOK_STATUS)), 'closed');
  new_history      JSONB;

BEGIN
  result = 0;
  error_code = 0;
  error_message = '';

  IF kaart_id IS NULL OR kaart_id = 0
  THEN
    error_code = 6;
    error_message = 'Dokumendi parameter on vale';
    RETURN;
  END IF;
  -- select kehtiv lepingud

  SELECT
    pk.*,
    u.kasutaja AS user_name
  INTO v_palk_kaart
  FROM palk.palk_kaart pk
    INNER JOIN ou.userid u ON u.id = user_id
  WHERE pk.id = kaart_id;

  IF v_palk_kaart.id IS NULL
  THEN
    error_code = 6;
    error_message = 'Kood ei leidnud';
    RETURN;
  END IF;

  IF NOT exists(SELECT id
                FROM ou.userid u
                WHERE id = user_id
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, rekvId: ' || ', userId:' ||
                    coalesce(userid, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;
  --ajalugu


  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()                                                  AS updated,
          (enum_range(NULL :: DOK_STATUS)) [v_palk_kaart.status] AS status,
          v_palk_kaart.user_name                                 AS user) row;

  UPDATE palk.palk_kaart
  SET status = (CASE WHEN status = l_active_status
    THEN l_archive_status
                ELSE l_active_status END),
    ajalugu  = new_history
  WHERE id = kaart_id
  RETURNING id
    INTO result;

  IF result IS NULL OR result = 0
  THEN
    error_code = 0;
    error_message = 'Puudub palgakaart';
  END IF;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_message = SQLERRM;
    error_code = 1;
    result = 0;
    RETURN;

END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION palk.change_kaart_status(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.change_kaart_status(INTEGER, INTEGER) TO dbpeakasutaja;

/*
select error_code, result, error_message from palk.palk_kaart_from_tmpl(56, 1)
*/
