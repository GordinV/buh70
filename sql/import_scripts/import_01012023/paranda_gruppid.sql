DROP FUNCTION IF EXISTS parandata_gruppid(INTEGER);

CREATE OR REPLACE FUNCTION parandata_gruppid(in_new_id INTEGER DEFAULT NULL::INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    l_lib_id       INTEGER;
    log_id         INTEGER;
    v_lib          RECORD;
    l_count        INTEGER = 0;
    l_lib          TEXT    = 'LIBRARY';
    l_json_objekt  JSONB;
    l_teenused     JSONB;
    l_uus_teenused JSONB   = '[]';
    l_vana_nom_id  INTEGER;
    l_uus_nom_id   INTEGER;
    l_json_raw     JSONB   = '{}';
    l_uuendatud    BOOLEAN = FALSE;
    l_vana_tyyp    INTEGER;
    l_uus_tyyp     INTEGER;
BEGIN
    -- выборка из "старого меню"

    FOR v_lib IN
        SELECT l.*
        FROM libs.library l
        WHERE (l.id = in_new_id OR in_new_id IS NULL)
          AND l.library IN ('LAPSE_GRUPP')
          AND status < 3
          AND l.properties IS NOT NULL
          AND l.properties <> '{}'
          AND l.properties::JSONB -> 'teenused' IS NOT NULL

        LIMIT ALL
        LOOP

            SELECT old_id INTO l_lib_id FROM import_log WHERE new_id = v_lib.id AND lib_name = 'LIBRARY';
            RAISE NOTICE 'v_lib.id %, l_lib_id %', v_lib.id, l_lib_id;
            l_json_objekt = (SELECT properties::JSONB FROM remote_library WHERE id = l_lib_id);
            l_vana_tyyp = (l_json_objekt ->> 'tyyp')::INTEGER;

            l_teenused = l_json_objekt -> 'teenused';
            RAISE NOTICE 'l_teenused %', l_teenused;
            IF l_json_objekt IS NULL
            THEN
                -- не импортировано = удалено
--                UPDATE libs.library SET status = 3 WHERE id = v_lib.id;
            ELSE
                FOR i IN 0..jsonb_array_length(l_teenused)
                    LOOP

                        l_json_raw = l_teenused -> i;
                        l_vana_nom_id = (l_json_raw ->> 'nomid')::INTEGER;

                        IF l_vana_nom_id IS NOT NULL
                        THEN
                            -- ищем в logs
                            IF NOT exists(SELECT new_id
                                          FROM import_log
                                          WHERE old_id = l_vana_nom_id
                                            AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'NOMENKLATUUR'
                                          LIMIT 1)
                            THEN
                                PERFORM import_nomenklatuur(l_vana_nom_id);
                            END IF;

                            l_uus_nom_id = (SELECT new_id
                                            FROM import_log
                                            WHERE old_id = l_vana_nom_id
                                              AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'NOMENKLATUUR'
                                            LIMIT 1);
                            IF (l_uus_nom_id) IS NULL
                            THEN
                                RAISE EXCEPTION 'nomid ei leidnud vana_nom_id %, v_lib.id %', l_vana_nom_id, v_lib.id;
                            END IF;

                            -- подменяем
                            l_json_raw = l_json_raw || jsonb_build_object('nomid', l_uus_nom_id, 'id', l_uus_nom_id);
                            RAISE NOTICE 'l_vana_nomid ->> %, uus ->? %', l_vana_nom_id, l_uus_nom_id;
                            l_uus_teenused = l_uus_teenused || l_json_raw;
                        END IF;

                    END LOOP;

                -- сохранение
                l_json_objekt = l_json_objekt || jsonb_build_object('teenused', l_uus_teenused);
                UPDATE libs.library SET properties = l_json_objekt::TEXT WHERE id = v_lib.id;
                RAISE NOTICE 'l_json_objekt %',l_json_objekt;
                l_json_objekt = '{}'::JSONB;
                l_uus_teenused = '[]'::JSONB;
            END IF;

            -- тип обучения
            raise notice 'v_lib.id %, l_vana_tyyp %',v_lib.id, l_vana_tyyp;

            IF l_vana_tyyp IS NOT NULL
            THEN
                l_uus_tyyp = (select new_id from import_log where old_id = l_vana_tyyp and lib_name = 'LIBRARY');
                update libs.library set properties = properties::jsonb || jsonb_build_object('tyyp',l_uus_tyyp)
                where id = v_lib.id;
            END IF;
        END LOOP;


    RETURN l_count;

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

SELECT parandata_gruppid(l.id)
FROM libs.library l
WHERE l.library IN ('LAPSE_GRUPP')
--  and id = 267983
  AND l.status < 3
;
--DROP FUNCTION IF EXISTS parandata_gruppid(INTEGER);

