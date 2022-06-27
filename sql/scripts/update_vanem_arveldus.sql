DROP FUNCTION IF EXISTS lapsed.update_lapsed_arveldused();

CREATE FUNCTION lapsed.update_lapsed_arveldused()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_va    RECORD;
    l_count INTEGER = 0;
    l_id    INTEGER;
BEGIN
    FOR v_va IN
        SELECT l.id AS laps_id, v.*, lk.rekvid
        FROM lapsed.laps l
                 INNER JOIN (SELECT v.parentid, v.asutusid
                             FROM lapsed.vanemad v
                             GROUP BY parentid, asutusid
                             HAVING count(*) = 1) v ON v.parentid = l.id
                 INNER JOIN (SELECT DISTINCT parentid, rekvid FROM lapsed.lapse_kaart lk WHERE staatus <> 3) lk
                            ON lk.parentid = l.id

        WHERE NOT exists(SELECT id
                         FROM lapsed.vanem_arveldus va
                         WHERE coalesce(arveldus, FALSE)
                           AND va.parentid = l.id
                           AND va.rekvid = lk.rekvid
            )
          AND lk.rekvid not in (85)
--          AND l.id = 10033

        LOOP
            IF NOT exists(SELECT id
                          FROM lapsed.vanem_arveldus
                          WHERE parentid = v_va.laps_id
                            AND rekvid = v_va.rekvid
                            AND coalesce(arveldus, FALSE))
            THEN
                l_id = (SELECT id
                        FROM lapsed.vanem_arveldus
                        WHERE parentid = v_va.laps_id
                          AND rekvid = v_va.rekvid
                        LIMIT 1);
                IF l_id IS NULL
                THEN
                    RAISE NOTICE 'insert v_va.laps_id %, v_va.asutusid %, v_va.rekvid %',v_va.laps_id, v_va.asutusid, v_va.rekvid;
                    INSERT INTO lapsed.vanem_arveldus (parentid, asutusid, rekvid, arveldus)
                    VALUES (v_va.laps_id, v_va.asutusid, v_va.rekvid, TRUE);
                ELSE
                    RAISE NOTICE 'update v_va.laps_id %, v_va.asutusid %, v_va.rekvid %',v_va.laps_id, v_va.asutusid, v_va.rekvid;

                    UPDATE lapsed.vanem_arveldus SET arveldus = TRUE WHERE id = l_id;
                END IF;
                l_count = l_count + 1;
            END IF;
        END LOOP;
    RETURN l_count;

END;
$$;

SELECT lapsed.update_lapsed_arveldused();

DROP FUNCTION IF EXISTS lapsed.update_lapsed_arveldused();

/*
 select trim(replace(vn,E'\n',''),'"'), vn, ik, asutus from tmp_viitenr_kustuta

SELECT id FROM ou.rekv WHERE left(nimetus, 10) = left(trim('"0911027 Narva Lasteaed Pongerjas T"','"'), 10) LIMIT 1

          FROM lapsed.viitenr
            WHERE isikukood = v_vn.ik
              AND rekv_id = l_rekv_id
              AND viitenumber = trim(replace(v_vn.vn,E'\n',''),'"');

select * from tmp_viitenr_kustuta
 where vn = '9366554'

 */
