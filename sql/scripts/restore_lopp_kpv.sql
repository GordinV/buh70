DROP FUNCTION IF EXISTS restore_lopp_kpv_in_kaart();

CREATE FUNCTION restore_lopp_kpv_in_kaart()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_kaart       RECORD;
    l_lopp_kpv    DATE;
    l_count_kaart INTEGER = 0;
BEGIN
    FOR v_kaart IN
        SELECT DISTINCT id, parentid AS laps_id, properties ->> 'yksus' AS yksus
        FROM lapsed.lapse_kaart lk
        WHERE rekvid = 92
          AND properties ->> 'lopp_kpv' = '2022-05-01'
          AND ajalugu::TEXT LIKE '%"user": "andrei.vargunin", "updated": "2022-08-18T16:25:00.347899+03:00"%'
        LOOP
            -- ищем дату из карточки
            SELECT max(properties ->> 'lopp_kpv') AS lopp_kpv
            INTO l_lopp_kpv
            FROM lapsed.lapse_kaart lk
            WHERE staatus = 1
              AND parentid = v_kaart.laps_id
              AND properties ->> 'lopp_kpv' IS NOT NULL
              AND (properties ->> 'lopp_kpv')::DATE <> '2022-05-01'
              AND (properties ->> 'yksus')::TEXT = v_kaart.yksus;

            IF (l_lopp_kpv IS NOT NULL)
            THEN
                update lapsed.lapse_kaart set properties = properties::jsonb || jsonb_build_object('lopp_kpv',l_lopp_kpv)
                where id = v_kaart.id;

                RAISE NOTICE 'id %, lopp_kpv %', v_kaart.id, l_lopp_kpv;
            ELSE

                -- алгорит льгота

                SELECT max(lk.properties ->> 'sooduse_lopp')::DATE
                INTO l_lopp_kpv
                FROM lapsed.lapse_kaart lk
                WHERE lk.rekvid = 92
                  AND lk.parentid = v_kaart.laps_id
                  and (properties ->> 'yksus')::TEXT = v_kaart.yksus
--                  and lk.parentid = 14365
--                  AND lk.properties ->> 'lopp_kpv' = '2022-05-01'
                  AND lk.properties ->> 'sooduse_lopp' IS NOT NULL
                  AND exists(SELECT id
                             FROM lapsed.lapse_kaart k
                             WHERE k.parentid = lk.parentid
                               AND (k.properties ->> 'alg_kpv')::DATE = (lk.properties ->> 'sooduse_lopp')::DATE + 1)
                  AND lk.staatus
                    < 3;

                IF (l_lopp_kpv IS NOT NULL)
                THEN
                    UPDATE lapsed.lapse_kaart
                    SET properties = properties::JSONB || jsonb_build_object('lopp_kpv', l_lopp_kpv)
                    WHERE parentid = v_kaart.laps_id
                    and properties ->> 'lopp_kpv' = '2022-05-01'
                    and (properties ->> 'yksus')::TEXT = v_kaart.yksus
                    and staatus < 3;

                    RAISE NOTICE 'id %, soodustuse lopp_kpv %', v_kaart.id, l_lopp_kpv;
                ELSE
                    RAISE NOTICE 'ikka null laps_id %, lopp_kpv %', v_kaart.laps_id, l_lopp_kpv;
                    l_count_kaart = l_count_kaart + 1;

                END IF;

            END IF;
        END LOOP;
    RAISE NOTICE 'l_count_kaart %', l_count_kaart;

    RETURN l_count_kaart;
END;

$$;

SELECT restore_lopp_kpv_in_kaart();

DROP FUNCTION IF EXISTS restore_lopp_kpv_in_kaart();;

