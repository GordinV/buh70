DROP FUNCTION IF EXISTS ou.sp_muuda_aasta_status(INTEGER, JSON);

CREATE OR REPLACE FUNCTION ou.sp_muuda_aasta_status(IN user_id INTEGER,
                                                    IN params JSON,
                                                    OUT error_code INTEGER,
                                                    OUT result INTEGER,
                                                    OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_aasta_id  INTEGER = params ->> 'id';
    l_status    INTEGER = coalesce((params ->> 'status') :: INTEGER, 0);
    l_module    TEXT    = coalesce((params ->> 'module') :: TEXT, '');
    l_kuu       INTEGER = params ->> 'kuu';
    l_aasta     INTEGER = params ->> 'aasta';
    l_kinni     INTEGER = 0;
    v_user      RECORD;
    v_doc       RECORD;
    l_rekv_id   INTEGER = (
                              SELECT
                                  rekvid
                              FROM
                                  ou.userid u
                              WHERE
                                  id = user_id
                          );
    new_history JSON;
    v_rekv      RECORD;
BEGIN
    SELECT *,
           (roles ->> 'is_peakasutaja')::BOOLEAN AS is_peakasutaja
    INTO v_user
    FROM
        ou.userid
    WHERE
        id = user_id;

    IF v_user IS NULL OR NOT v_user.is_peakasutaja
    THEN
        error_code = 5;
        error_message = 'Viga, Kasutaja ei leitud või puudub õigused, aasta.id: ' || coalesce(l_aasta_id, 0) :: TEXT ||
                        ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RAISE NOTICE 'error %', error_message;
        RETURN;
    END IF;

    -- Только работники фин. департамента
    if upper(coalesce(l_module, '')) = 'EELARVE' and not exists
    (
        select
            id
        from
            ou.userid u
        where
              u.kasutaja = v_user.kasutaja
          and u.rekvid = 63
          and u.status < 3
          and (roles ->> 'is_peakasutaja')::BOOLEAN
    ) then
        error_code = 5;
        error_message = 'Viga, peaks olla ainult Rahandusameti kasutaja. Puudub õigused, aasta.id: ' ||
                        coalesce(l_aasta_id, 0) :: TEXT ||
                        ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RAISE NOTICE 'error %', error_message;
        RETURN;

    end if;


    if l_module not in ('raamat', 'eelarve', 'palk') then
        error_code = 5;
        error_message = 'Vale moduul: ' || l_module :: TEXT;
        result = 0;
        RAISE NOTICE 'error %', error_message;
        RETURN;

    end if;

    IF l_aasta_id IS NOT NULL
    THEN
        SELECT
            kuu,
            aasta,
            kinni
        INTO l_kuu, l_aasta, l_kinni
        FROM
            ou.aasta
        WHERE
            id = l_aasta_id;

    END IF;

    FOR v_rekv IN
        SELECT *
        FROM
            (
                SELECT
                    rekv_id
                FROM
                    get_asutuse_struktuur(l_rekv_id)
--                 WHERE rekv_id = l_rekv_id
            ) qry
        WHERE
            CASE WHEN l_status = 1 THEN rekv_id = rekv_id ELSE rekv_id = l_rekv_id END
        LOOP
            --            RAISE NOTICE 'v_rekv.id %', v_rekv.rekv_id;
            l_aasta_id = (
                             SELECT
                                 id
                             FROM
                                 ou.aasta a
                             WHERE
                                   rekvid = v_rekv.rekv_id
                               AND kuu = l_kuu
                               AND l_aasta = aasta
                         );

            -- ajalugu
            SELECT
                row_to_json(row)
            INTO new_history
            FROM
                (
                    SELECT
                        now()                        AS updated,
                        ltrim(rtrim(v_user.ametnik)) AS user
                ) row;


            IF (l_aasta_id IS NULL OR l_aasta_id = 0)
            THEN
                -- new perioa
                IF l_kuu IS NULL OR l_aasta IS NULL
                THEN
                    error_code = 6;
                    error_message = 'Puuduvad vajaliku andmed: ' :: TEXT;
                    result = 0;
                    RETURN;

                END IF;

                l_aasta_id = (
                                 SELECT
                                     id
                                 FROM
                                     ou.aasta a
                                 WHERE
                                       rekvid = v_rekv.rekv_id
                                   AND kuu = l_kuu
                                   AND l_aasta = aasta
                                 LIMIT 1
                             );

                IF l_aasta_id IS NULL OR l_aasta_id = 0
                THEN
                    INSERT INTO ou.aasta (rekvid, ajalugu, kuu, aasta)
                    VALUES (v_rekv.rekv_id, '[]' :: JSONB || new_history:: JSONB, l_kuu, l_aasta)
                    RETURNING id
                        INTO l_aasta_id;

                END IF;
            ELSE
                SELECT
                    a.*
                INTO v_doc
                FROM
                    ou.aasta a
                WHERE
                    a.id = l_aasta_id;

                IF v_doc IS NULL
                THEN
                    error_code = 6;
                    error_message = 'Dokument ei leitud, docId: ' || coalesce(l_aasta_id, 0) :: TEXT;
                    result = 0;
                    RETURN;

                END IF;
            END IF;

            case
                when upper(coalesce(l_module, '')) = 'RAAMAT'
                    THEN UPDATE ou.aasta
                         SET
                             ajalugu    = coalesce(ajalugu, '[]') :: JSONB || new_history:: JSONB,
                             kinni      = l_status,
                             palk_kinni = l_status
                         WHERE
                             id = l_aasta_id;
                when upper(coalesce(l_module, '')) = 'PALK'
                    then UPDATE ou.aasta
                         SET
                             ajalugu    = coalesce(ajalugu, '[]') :: JSONB || new_history:: JSONB,
                             palk_kinni = case when l_kinni = 1 then 1 else l_status end
                         WHERE
                             id = l_aasta_id;
                when upper(coalesce(l_module, '')) = 'EELARVE'
                    then UPDATE ou.aasta
                         SET
                             ajalugu       = coalesce(ajalugu, '[]') :: JSONB || new_history:: JSONB,
                             eelarve_kinni = l_status
                         WHERE
                             id = l_aasta_id;

                END case;
        END LOOP;
    result = 1;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION ou.sp_muuda_aasta_status(INTEGER, JSON) TO dbpeakasutaja;

/*
select ou.sp_muuda_aasta_status(3196,'{"id":8810,"status":1}')


select * from ou.userid where rekvid = 64 and kasutaja = 'vlad'
select * from ou.aasta where  rekvid = 64  and aasta = 2026 and kuu = 1

*/

