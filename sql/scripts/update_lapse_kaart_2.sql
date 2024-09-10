DROP FUNCTION IF EXISTS lapsed.update_teenused_lapse_kaart();

CREATE FUNCTION lapsed.update_teenused_lapse_kaart()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_kaart RECORD;
    v_laps  RECORD;
    l_vn    TEXT;
    l_count INTEGER = 0;
BEGIN
    FOR v_laps IN
        SELECT DISTINCT l.id
        FROM lapsed.laps l
                 INNER JOIN lapsed.lapse_kaart lk ON l.id = lk.parentid
        WHERE lk.rekvid = 96
          and l.id <> 15067
          AND lk.staatus < 3
          AND lk.properties ->> 'yksus' = 'LAED-002-31'
          AND nomid NOT IN (
            SELECT n.id AS id
            FROM jsonb_to_recordset((SELECT properties::JSONB -> 'teenused'
                                     FROM libs.library
                                     WHERE id = 281486)) AS x(hind NUMERIC(12, 2), kogus NUMERIC(12, 2), nomid INTEGER)
                     INNER JOIN libs.nomenklatuur n ON n.id = x.nomid
        )
        LOOP

            FOR v_kaart IN
                SELECT lk.properties ->> 'yksus', lk.*
                FROM lapsed.laps l
                         INNER JOIN lapsed.lapse_kaart lk ON l.id = lk.parentid
                WHERE lk.rekvid = 96
                  AND l.id = v_laps.id
                  AND lk.staatus < 3
                  AND lk.properties ->> 'yksus' = 'LAED-002-31'
                  AND nomid NOT IN (
                    SELECT n.id AS id
                    FROM jsonb_to_recordset((SELECT properties::JSONB -> 'teenused'
                                             FROM libs.library
                                             WHERE id = 281486)) AS x(hind NUMERIC(12, 2), kogus NUMERIC(12, 2), nomid INTEGER)
                             INNER JOIN libs.nomenklatuur n ON n.id = x.nomid
                )
/*select * from libs.library
where id=281486*/
                LOOP
                    --1 kustuta vana teenused
                    perform lapsed.sp_delete_lapse_kaart(4824, v_kaart.id);

                    IF l_count > 0
                    THEN
                        RAISE NOTICE 'Updated total: l_count %', l_count;
                    END IF;
                END LOOP;

                -- копируем услуги из группы
            PERFORM lapsed.saama_yksuse_teenused(4824::INTEGER, v_laps.id::INTEGER, 281486::INTEGER, '2024-08-01'::DATE);
-- lapsed.saama_yksuse_teenused(IN user_id INTEGER,
--                                                         IN l_id INTEGER,
--                                                         IN l_grupp_id INTEGER,
--                                                         IN l_alates DATE DEFAULT current_date,
            l_count  = l_count + 1;
        END LOOP;
    RETURN l_count;

END ;
$$;

SELECT lapsed.update_teenused_lapse_kaart();

DROP FUNCTION IF EXISTS lapsed.update_teenused_lapse_kaart();

