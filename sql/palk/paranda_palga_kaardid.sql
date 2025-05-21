DROP FUNCTION IF EXISTS palk.paranda_palga_kaardid( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.paranda_palga_kaardid(
    IN  user_id      INTEGER,
    IN  proj_id       INTEGER,
    OUT error_code    INTEGER,
    OUT result        INTEGER,
    OUT error_message TEXT)
AS
$BODY$
DECLARE
    v_palk_kaart     RECORD;
    new_history      JSONB;
    v_projekt record;

BEGIN
    result = 0;
    error_code = 0;
    error_message = '';

    IF proj_id IS NULL OR proj_id = 0
    THEN
        error_code = 6;
        error_message = 'Puudub projekt';
        RETURN;
    END IF;

    select p.rekvid, p.kood
    into v_projekt
    from libs.library p
    where p.id = proj_id;

/*    SELECT
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
*/    RETURN;

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


GRANT EXECUTE ON FUNCTION palk.paranda_palga_kaardid(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.paranda_palga_kaardid(INTEGER, INTEGER) TO dbpeakasutaja;

/*
select error_code, result, error_message from palk.palk_kaart_from_tmpl(56, 1)
*/
