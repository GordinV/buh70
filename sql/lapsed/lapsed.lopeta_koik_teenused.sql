-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.lopeta_koik_teenused(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.lopeta_koik_teenused(IN user_id INTEGER,
                                                       IN l_laps_id INTEGER,
                                                       IN l_kpv DATE DEFAULT current_date,
                                                       OUT error_code INTEGER,
                                                       OUT result INTEGER,
                                                       OUT doc_type_id TEXT,
                                                       OUT error_message TEXT,
                                                       OUT viitenr TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid     INTEGER = (SELECT rekvid
                            FROM ou.userid u
                            WHERE id = user_id
                            LIMIT 1);
    l_user       TEXT    = (SELECT ametnik
                            FROM ou.userid
                            WHERE id = user_id
                            LIMIT 1);
    json_ajalugu JSONB   = jsonb_build_object('updated', now(), 'userName', l_user); -- логгирование
    v_laps       RECORD;
    l_count      INTEGER = 0;
    json_params  JSONB;
    v_teenused   RECORD;

BEGIN
    SELECT *, lapsed.get_viitenumber(l_rekvid, l_laps_id) AS viitenr
    INTO v_laps
    FROM lapsed.laps l
    WHERE id = l_laps_id;

    --
    -- update
    FOR v_teenused IN
        SELECT id, (properties ->> 'sooduse_lopp')::DATE AS sooduse_lopp
        FROM lapsed.lapse_kaart lk
        WHERE parentid = l_laps_id
          AND rekvid = l_rekvid
          AND ((properties ->> 'lopp_kpv')::DATE IS NULL OR (properties ->> 'lopp_kpv')::DATE > l_kpv)
          AND staatus = 1
        LOOP

            json_params = jsonb_build_object('lopp_kpv', l_kpv);
            -- льгота
            IF (v_teenused.sooduse_lopp)::DATE IS NOT NULL AND
               (v_teenused.sooduse_lopp)::DATE > l_kpv
            THEN
                -- льгота не должна превышать срок услуги
                json_params = json_params || jsonb_build_object('sooduse_lopp', l_kpv);
            END IF;

            UPDATE lapsed.lapse_kaart
            SET properties = properties::JSONB || json_params,
                ajalugu    = ajalugu::JSONB || json_ajalugu
            WHERE id = v_teenused.id;
            l_count = l_count + 1;
        END LOOP;

    -- response
    doc_type_id = 'LAPS';
    result = l_laps_id;
    error_message = 'Isikukood: ' || v_laps.isikukood || ', Nimi:' || v_laps.nimi || ', kokku uuendatud ' ||
                    COALESCE(l_count, 0)::TEXT || ' teenused'::TEXT;


    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END ;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.lopeta_koik_teenused(INTEGER, INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lopeta_koik_teenused(INTEGER, INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.lopeta_koik_teenused(INTEGER, INTEGER, DATE) TO arvestaja;


/*
select * from lapsed.lopeta_koik_teenused(70, 5573, '2021-04-27')
 */

