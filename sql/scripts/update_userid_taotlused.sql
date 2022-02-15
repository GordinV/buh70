DROP FUNCTION IF EXISTS update_userid_taotlused();

CREATE FUNCTION update_userid_taotlused()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_docs             RECORD;
    l_count            INTEGER = 0;
    l_kasutaja         TEXT;
    l_koostaja_id      INTEGER;
    l_ametnik_id       INTEGER;
    l_aktsepteerija_id INTEGER;
    l_ajalugu jsonb;

BEGIN

    FOR v_docs IN
        SELECT d.id AS doc_id, t.*
        FROM docs.doc d
                 INNER JOIN eelarve.taotlus t ON t.parentid = d.id
        WHERE d.status < 3
--          AND d.id = 3443359
        LOOP

            IF v_docs.koostajaid IS NOT NULL AND NOT exists(SELECT id FROM ou.userid WHERE id = v_docs.koostajaid)
            THEN
                -- ищем нового пользователя
                l_kasutaja = (SELECT kasutaja
                              FROM remote_userid
                              WHERE id = v_docs.koostajaid
                                AND rekvid = v_docs.rekvid
                              ORDER BY id DESC
                              LIMIT 1);

                l_koostaja_id = (SELECT id
                                 FROM ou.userid
                                 WHERE rekvid = v_docs.rekvid
                                   AND kasutaja = l_kasutaja
                                   AND status < 3
                                 ORDER BY id DESC
                                 LIMIT 1);
            ELSE
                l_koostaja_id = v_docs.koostajaid;
            END IF;


            IF v_docs.ametnikid = v_docs.koostajaid
            THEN
                l_ametnik_id = l_koostaja_id;
            ELSE
                IF v_docs.ametnikid IS NOT NULL AND NOT exists(SELECT id FROM ou.userid WHERE id = v_docs.ametnikid)
                THEN
                    -- ищем нового пользователя
                    l_kasutaja = (SELECT kasutaja
                                  FROM remote_userid
                                  WHERE id = v_docs.ametnikid
                                    AND rekvid = v_docs.rekvid
                                  ORDER BY id DESC
                                  LIMIT 1);

                    l_ametnik_id = (SELECT id
                                    FROM ou.userid
                                    WHERE rekvid = v_docs.rekvid
                                      AND kasutaja = l_kasutaja
                                      AND status < 3
                                    ORDER BY id DESC
                                    LIMIT 1);

                END IF;

            END IF;


            IF v_docs.aktseptid IS NOT NULL AND NOT exists(SELECT id FROM ou.userid WHERE id = v_docs.aktseptid)
            THEN
                -- ищем нового пользователя
                l_kasutaja = (SELECT kasutaja
                              FROM remote_userid
                              WHERE id = v_docs.aktseptid
                                AND rekvid = v_docs.rekvid
                              ORDER BY id DESC
                              LIMIT 1);

                l_aktsepteerija_id = (SELECT id
                                      FROM ou.userid
                                      WHERE rekvid = v_docs.rekvid
                                        AND kasutaja = l_kasutaja
                                        AND status < 3
                                      ORDER BY id DESC
                                      LIMIT 1);
            ELSE
                l_aktsepteerija_id = v_docs.koostajaid;
            END IF;

            l_ajalugu = jsonb_build_object('koostajaid',v_docs.koostajaid, 'ametnikid',v_docs.ametnikid, 'aktseptid',v_docs.aktseptid);

            RAISE NOTICE 'l_aktsepteerija_id %, l_ametnik_id %, l_koostaja_id %', l_aktsepteerija_id, l_ametnik_id, l_koostaja_id;



            UPDATE eelarve.taotlus
            SET koostajaid = l_koostaja_id,
                ametnikid  = l_ametnik_id,
                aktseptid  = l_aktsepteerija_id
            WHERE id = v_docs.id;

            update docs.doc set history = history::jsonb || l_ajalugu where id = v_docs.doc_id;

            l_count = l_count + 1;
        END LOOP;
    RETURN l_count;

END;
$$;

SELECT update_userid_taotlused();

DROP FUNCTION IF EXISTS update_userid_taotlused();

