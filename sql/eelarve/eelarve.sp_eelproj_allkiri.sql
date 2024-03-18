DROP FUNCTION IF EXISTS eelarve.sp_eelproj_allkiri(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.sp_eelproj_allkiri(INTEGER, JSON);

CREATE FUNCTION eelarve.sp_eelproj_allkiri(tnAmetnikId INTEGER, params JSON,
                                           OUT error_code INTEGER,
                                           OUT result INTEGER,
                                           OUT error_message TEXT)
    RETURNS RECORD
    LANGUAGE plpgsql
AS
$$
DECLARE
    tnId        INTEGER = params ->> 'eelproj_id';
    lnresult    INTEGER;
    tmpEelProj  RECORD;
    new_history JSONB;
    v_projekt   RECORD;
    proj_params JSONB   = params::JSONB;
BEGIN
    lnresult = 0;

    -- ajalugu
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT now()             AS updated,
                 (SELECT kasutaja
                  FROM ou.userid
                  WHERE id = tnAmetnikId
                  LIMIT 1) :: TEXT AS user,
                 'allkirjastatud'  AS status
         ) row;


    SELECT *
    INTO tmpEelProj
    FROM eelarve.eelproj
    WHERE id = tnid;

    FOR v_projekt IN
        SELECT p.*
        FROM eelarve.eelproj p
        WHERE p.rekvid IN (SELECT rekv_id FROM get_asutuse_struktuur(tmpEelProj.rekvid))
          AND p.aasta = tmpEelProj.aasta
          AND p.status = array_position((enum_range(NULL :: DOK_STATUS)), 'active')
        LOOP

            --	* see tahendab et ainult uks voimas allkirjustada eelrve projekt kui staatus = 1
            UPDATE eelarve.eelproj
            SET status    = array_position((enum_range(NULL :: DOK_STATUS)), 'closed'),
                kinnitaja = tnAmetnikId,
                ajalugu   = ajalugu || new_history
            WHERE id = v_projekt.id;

            proj_params = params::JSONB || jsonb_build_object('eelproj_id', v_projekt.id);

            SELECT *
            INTO error_code, result, error_message
            FROM eelarve.sp_eelproj_kinnitamine(tnAmetnikId, proj_params::JSON);

            IF (error_code IS NULL OR error_code = 0) AND result IS NULL
            THEN
                result = 1;
            END IF;
        END LOOP;

    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION eelarve.sp_eelproj_allkiri( INTEGER, JSON ) TO eelaktsepterja;

/*
select * from eelarve.eelproj where id = 3
select error_code, result, error_message from eelarve.sp_eelproj_allkiri(3, 1);

*/