DROP FUNCTION IF EXISTS update_userid_journal();

CREATE FUNCTION update_userid_journal()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_docs             RECORD;
    l_count            INTEGER = 0;
    l_kasutaja         TEXT;
    l_koostaja_id      INTEGER;
    l_ajalugu          JSONB;

BEGIN

    FOR v_docs IN
        SELECT d.id AS doc_id, t.*
        FROM docs.doc d
                 INNER JOIN docs.journal t ON t.parentid = d.id
        WHERE d.status < 3
--          AND d.id = 2979827
        LOOP

            IF v_docs.userid IS NOT NULL AND NOT exists(SELECT id FROM ou.userid WHERE id = v_docs.userid)
            THEN
                -- ищем нового пользователя
                l_kasutaja = (SELECT kasutaja
                              FROM remote_userid
                              WHERE id = v_docs.userid
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
                l_koostaja_id = v_docs.userid;
            END IF;

            IF l_koostaja_id <> v_docs.userid
            THEN
                l_ajalugu = jsonb_build_object('koostajaid', v_docs.userid);

                RAISE NOTICE ' l_koostaja_id %', l_koostaja_id;
                UPDATE docs.journal SET userid = l_koostaja_id WHERE id = v_docs.id;

                UPDATE docs.doc SET history = history::JSONB || l_ajalugu WHERE id = v_docs.doc_id;

                l_count = l_count + 1;
            ELSE
                RAISE NOTICE 'Pole vaja l_koostaja_id %', l_koostaja_id;

            END IF;


        END LOOP;
    RETURN l_count;

END;
$$;

SELECT update_userid_journal();

DROP FUNCTION IF EXISTS update_userid_journal();

