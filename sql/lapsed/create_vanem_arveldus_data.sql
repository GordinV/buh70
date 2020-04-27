DO $$
    DECLARE
        v_vanem          RECORD;
        v_laste_teenused RECORD;
    BEGIN
        -- список учреждений и детей
        FOR v_laste_teenused IN
            SELECT DISTINCT rekvid, parentid
            FROM lapsed.lapse_kaart lk
                WHERE staatus <> 3
            LOOP
                -- список родитедей
                FOR v_vanem IN
                    SELECT parentid,
                           asutusid,
                           CASE
                               WHEN UPPER(coalesce((properties ->> 'arved')::TEXT, 'EI')) = 'JAH' THEN TRUE
                               ELSE FALSE END AS arveldused
                    FROM lapsed.vanemad v
                        WHERE staatus <> 3
                             AND parentid = v_laste_teenused.parentid
                    LOOP
                        RAISE NOTICE 'lk %, v %', v_laste_teenused, v_vanem;
                        -- проверим на наличие
                        IF NOT exists(SELECT id
                                      FROM lapsed.vanem_arveldus WHERE parentid = v_vanem.parentid AND asutusid = v_vanem.asutusid AND rekvid = v_laste_teenused.rekvid)
                        THEN
                            INSERT INTO lapsed.vanem_arveldus (parentid, asutusid, rekvid, arveldus)
                            VALUES (v_vanem.parentid, v_vanem.asutusid, v_laste_teenused.rekvid, v_vanem.arveldused);
                        END IF;

                    END LOOP;
            END LOOP;
    END
    $$;