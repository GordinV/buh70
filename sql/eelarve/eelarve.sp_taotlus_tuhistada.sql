DROP FUNCTION IF EXISTS eelarve.sp_taotlus_tuhista(INTEGER, JSON);

CREATE FUNCTION eelarve.sp_taotlus_tuhista(user_id INTEGER, params JSON, OUT error_code INTEGER, OUT result INTEGER,
                                           OUT error_message TEXT)
    RETURNS RECORD
    LANGUAGE plpgsql
AS
$$
DECLARE
    doc_id     INTEGER = coalesce((params ->> 'doc_id') :: INTEGER, 0);
    tcLiik     TEXT    = params ->> 'liik';
    tcMuud     TEXT    = params ->> 'muud';
    c_oigus    TEXT    = CASE
                             WHEN tcLiik = 'ALLKIRI'
                                 THEN 'is_eel_allkirjastaja'
                             WHEN tcLiik = 'AKTSEPTEERIMINE'
                                 THEN 'is_eel_admin'
                             ELSE 'is_eel_allkirjastaja' END;
    tmpTaotlus RECORD;
    v_eelarve  RECORD;

BEGIN

    SELECT
        t.*
    INTO tmpTaotlus
    FROM
        eelarve.taotlus t,
        ou.userid       u
    WHERE
          t.parentid = doc_id
      AND u.id = user_id
      AND coalesce((u.roles ->> c_oigus) :: BOOLEAN, FALSE) :: BOOLEAN;

    IF tmpTaotlus IS NULL
    THEN
        error_code = 6;
        error_message = 'Viga, document not exists or not enough rights , docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;
    END IF;

    IF tmpTaotlus.status > 3
    THEN
        error_code = 7;
        error_message = 'Viga, vale taotluse staatus , docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- контроль периода для модуля Eelarve
    IF NOT (ou.fnc_aasta_eelarve_kontrol(tmpTaotlus.rekvid, tmpTaotlus.kpv))
    THEN
        RAISE EXCEPTION 'Viga, periodi kontrol. Eelarve kinni';
    END IF;

    IF tcLiik = 'ALLKIRI'
    THEN

        IF NOT empty(tmptaotlus.allkiri)
        THEN
            UPDATE eelarve.taotlus
            SET
                status  = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'allkirjastatud'),
                allkiri = 0,
--                KoostajaID = user_id,
                muud    = muud || chr(13) || current_user :: TEXT || ':' + tcMuud
            WHERE
                parentid = doc_id;

            result = 1;

        ELSE
            result = 0;
            error_message = 'Viga, Ei saa tuhistatda allkiri, allkiri = 0 , docId: ' || coalesce(doc_id, 0) :: TEXT;
            RETURN;
        END IF;
    END IF;

    IF tcLiik = 'ESITA'
    THEN
        IF tmptaotlus.status = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'esitatud')
        THEN
            UPDATE eelarve.taotlus
            SET
                status    = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'allkirjastatud'),
                allkiri   = 1,
                ametnikid = 0,
                muud      = muud || chr(13) || current_user :: TEXT || ':' || tcMuud
            WHERE
                parentid = doc_id;

            result = 1;
        ELSE
            error_message =
                    'Viga, ei saa tuhistada esitamine, staatus = allkirjastatud, docId: ' ||
                    coalesce(doc_id, 0) :: TEXT;
            result = 0;
        END IF;

    END IF;

    IF tcLiik = 'AKTSEPTEERIMINE'
    THEN
        -- удалить бюджет
        FOR v_eelarve IN (
                             SELECT
                                 e.id
                             FROM
                                 eelarve.eelarve e
                             WHERE
                                 id IN (
                                           SELECT
                                               t1.eelarveid
                                           FROM
                                               eelarve.taotlus                 t
                                                   INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                                           WHERE
                                               t.parentid = doc_id
                                       )
                         )
            LOOP
                -- удаляем бюджетную строку
                PERFORM eelarve.sp_delete_eelarve(user_id, v_eelarve.id, 0);

                -- убираем ссылку
                UPDATE eelarve.taotlus1 SET eelarveid = NULL WHERE eelarveid = v_eelarve.id;
            END LOOP;

        -- поменять статус

        UPDATE eelarve.taotlus
        SET
            status    = array_position((enum_range(NULL :: TAOTLUSE_STATUS)), 'esitatud'),
            allkiri   = 1,
            ametnikid = 0,
            muud      = muud || chr(13) || CURRENT_USER :: TEXT ||
                        ':' || tcMuud
        WHERE
            parentid = doc_id;

        result = 1;

    END IF;

    RETURN;

END;
$$;


GRANT EXECUTE ON FUNCTION eelarve.sp_taotlus_tuhista(INTEGER, JSON) TO eelallkirjastaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_taotlus_tuhista(INTEGER, JSON) TO eelesitaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_taotlus_tuhista(INTEGER, JSON) TO eelaktsepterja;


/*

	select * from eelarve.sp_taotlus_tuhista(2477,'{"doc_id":2275556,"muud":"test","liik":"AKTSEPTEERIMINE"}')
				{"doc_id":?tnId,"muud":"test","liik":"ALLKIRI"}
 select * from eelarve.taotlus where parentid = 1310

SELECT * FROM OU.userid where rekvid = 63 and kasutaja = 'vlad'

 */
