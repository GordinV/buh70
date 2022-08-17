-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.update_teenused_set_viitenr(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.update_teenused_set_viitenr(IN user_id INTEGER,
                                                              IN l_doc_id INTEGER,
                                                              OUT error_code INTEGER,
                                                              OUT result INTEGER,
                                                              OUT doc_type_id TEXT,
                                                              OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid     INTEGER = (SELECT rekvid
                            FROM ou.userid u
                            WHERE id = user_id
                            LIMIT 1);

    l_viitenr    TEXT    = (SELECT viitenumber
                            FROM lapsed.viitenr
                            WHERE id = l_doc_id
                            LIMIT 1);
    l_isikukood  TEXT    = (SELECT isikukood
                            FROM lapsed.viitenr
                            WHERE id = l_doc_id
                            LIMIT 1);
    v_teenused   RECORD;
    l_message    TEXT    = '';
    l_count      INTEGER = 0;
    json_ajalugu JSONB;
    userName     TEXT;
BEGIN
    doc_type_id = 'LAPSE_KAART';

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = l_rekvid
      AND u.id = user_id;

    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        error_message = 'User not found';
        RETURN;
    END IF;

    -- проверить в карточках услуг витенумберов
    FOR v_teenused IN
        SELECT lk.id, ltrim(rtrim(n.kood)) AS kood
        FROM lapsed.lapse_kaart lk
                 INNER JOIN lapsed.laps l ON l.id = lk.parentid
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.rekvid = l_rekvid
          AND l.isikukood = l_isikukood
          AND lk.staatus < 3
          AND (lk.properties ->> 'viitenr' IS NULL OR empty(lk.properties ->> 'viitenr'))
        LOOP
            -- ajalugu
            json_ajalugu = to_jsonb(row)
                           FROM (SELECT now()    AS updated,
                                        userName AS user) row;

            UPDATE lapsed.lapse_kaart
            SET properties = properties::JSONB || jsonb_build_object('viitenr', l_viitenr)
            WHERE id = v_teenused.id;

            l_message = l_message || ',kood:' || ltrim(rtrim(v_teenused.kood)) || ' uuendatud';
            l_count = l_count + 1;

        END LOOP;

    result = l_count;
    error_message = l_message;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

REVOKE EXECUTE ON FUNCTION lapsed.update_teenused_set_viitenr(INTEGER, INTEGER) FROM dbkasutaja;
REVOKE EXECUTE ON FUNCTION lapsed.update_teenused_set_viitenr(INTEGER, INTEGER) FROM dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.update_teenused_set_viitenr(INTEGER, INTEGER) TO arvestaja;


/*
select lapsed.arvesta_taabel(45, 8013,'2022-01-31')

select * from lapsed.lapsed_taabel where rekvid = 63

 */