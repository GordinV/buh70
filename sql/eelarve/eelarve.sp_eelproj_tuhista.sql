DROP FUNCTION IF EXISTS eelarve.sp_eelproj_tuhista( INTEGER, JSON );

CREATE FUNCTION eelarve.sp_eelproj_tuhista(
      user_id       INTEGER,
      params        JSON,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE eelproj_id     INTEGER = coalesce((params ->> 'eelproj_id') :: INTEGER, 0); -- eelproj
        v_eelProj      RECORD;
        v_taotlus      RECORD;
        taotlus_params JSON;
BEGIN

  IF eelproj_id IS NULL
  THEN
    -- error
    error_code = 6;
    error_message = 'Eelarve projekt ei leidnud';
    result = 0;
    RETURN;
  END IF;


  SELECT e.*
  INTO v_eelproj
  FROM eelarve.eelproj e
  WHERE e.id = eelproj_id;

  IF v_eelProj.status = array_position((enum_range(NULL :: DOK_STATUS)), 'active')
  THEN
    --* see tahendab et ainult uks voimalus tuhistada eelrve projekt kui staatus = 1

    UPDATE eelarve.eelproj
    SET status = 0
    WHERE id = eelproj_id;

    -- tagastada kõik taotlused milline ühendatud projektiga

    FOR v_taotlus IN
    SELECT d.id
    FROM docs.doc d
      INNER JOIN eelarve.taotlus t ON t.parentid = d.id
    WHERE t.id IN (SELECT DISTINCT t1.parentid
                   FROM eelarve.taotlus1 t1
                   WHERE eelprojid = eelproj_id)
    LOOP
      SELECT row_to_json(row)
      INTO taotlus_params
      FROM (SELECT
              v_taotlus.id                    AS doc_id,
              'Eelarve projekt on tühistatud' AS muud) row;

      SELECT *
      INTO error_code, result, error_message
      FROM eelarve.sp_taotlus_tagastada(user_id, taotlus_params);

      IF error_code IS NOT NULL AND error_code > 0
      THEN
        -- error
        RAISE NOTICE 'Viga, katkestan error_message %', error_message;
        EXIT;
      END IF;
    END LOOP;

    result = 1;
  ELSE
    error_code = 1;
    error_message = 'Vale projekti staatus';
    result = 0;
  END IF;

  RETURN;

END;

$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION eelarve.sp_eelproj_tuhista(INTEGER, JSON) TO eelaktsepterja;
