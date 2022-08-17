CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_viitenr(data JSONB,
                                                      userid INTEGER,
                                                      user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName        TEXT;
    doc_data        JSON    = data ->> 'data';
    doc_id          INTEGER = doc_data ->> 'id';
    doc_laps_id     INTEGER = doc_data ->> 'laps_id';
    doc_viitenumber TEXT    = doc_data ->> 'viitenumber';
    l_isikukood     TEXT    = (SELECT isikukood
                               FROM lapsed.laps
                               WHERE id = doc_laps_id
                                 AND staatus <> 3
                               LIMIT 1);
    v_teenused      RECORD;
    l_old_viitenr   TEXT;
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF doc_viitenumber IS NULL OR l_isikukood IS NULL
    THEN

    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO lapsed.viitenr (isikukood, rekv_id, viitenumber)
        VALUES (l_isikukood, user_rekvid, doc_viitenumber) RETURNING id
            INTO doc_id;

    ELSE
        IF NOT exists(SELECT id FROM lapsed.viitenr WHERE id = doc_id AND rekv_id = user_rekvid)
        THEN
            RAISE EXCEPTION 'Puudub õigused %', user;
        END IF;

        -- запоминаем старый (прежний) код
        l_old_viitenr = (SELECT viitenumber FROM lapsed.viitenr WHERE id = doc_id LIMIT 1);

        UPDATE lapsed.viitenr
        SET viitenumber = doc_viitenumber,
            isikukood   = l_isikukood
        WHERE id = doc_id RETURNING id
            INTO doc_id;

        IF (l_old_viitenr <> doc_viitenumber)
        THEN
            -- проверить в карточках услуг витенумберов
            FOR v_teenused IN
                SELECT lk.id
                FROM lapsed.lapse_kaart lk
                WHERE lk.rekvid = user_rekvid
                  AND parentid = doc_laps_id
                  AND staatus < 3
                  AND (lk.properties ->> 'viitenr' IS NOT NULL AND (lk.properties ->> 'viitenr')::TEXT = l_old_viitenr)
                LOOP
                    UPDATE lapsed.lapse_kaart
                    SET properties = properties::JSONB || jsonb_build_object('viitenr', doc_viitenumber)
                    WHERE id = v_teenused.id;

                END LOOP;

        END IF;


    END IF;


    RETURN doc_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_viitenr(JSONB, INTEGER, INTEGER) TO arvestaja;


/*

select lapsed.sp_salvesta_viitenr('{"data":{"id":0,"parentid":7,"asutusid":31825,"arved":"jah","muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id
select lapsed.sp_salvesta_vanem('{"data":{"id":2,"parentid":1,"asutusid":1621,"arved":"Jah","muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id

*/