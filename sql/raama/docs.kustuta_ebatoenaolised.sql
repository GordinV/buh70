DROP FUNCTION IF EXISTS docs.kustuta_ebatoenaolised(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.kustuta_ebatoenaolised(IN l_doc_id INTEGER,
                                                       IN user_id INTEGER,
                                                       OUT error_code INTEGER,
                                                       OUT result INTEGER,
                                                       OUT error_message TEXT)
AS
$BODY$
DECLARE
    v_arv    RECORD;
    l_json   JSONB;
    userName TEXT = (SELECT kasutaja
                     FROM ou.userid
                     WHERE id = user_id);
BEGIN
    -- ищем документ и связанный счет
    FOR v_arv IN
        SELECT d.id                                              AS id,
               a.id                                              AS arv_id,
               (a.properties ->> 'ebatoenaolised_1_id')::INTEGER AS ebatoenaolised_1_id,
               (a.properties ->> 'ebatoenaolised_2_id')::INTEGER AS ebatoenaolised_2_id

        FROM docs.doc d
                 INNER JOIN docs.arv a ON d.id = a.parentid
        WHERE d.docs_ids @> ARRAY [l_doc_id]
        LOOP
            -- снимаем со счета метку о наличие маловероятных
            IF v_arv.ebatoenaolised_1_id = l_doc_id
            THEN
                l_json = to_json(row)
                         FROM (SELECT NULL AS ebatoenaolised_1_id
                              ) row;
            ELSIF v_arv.ebatoenaolised_2_id = l_doc_id
            THEN
                l_json = to_json(row)
                         FROM (SELECT NULL AS ebatoenaolised_2_id
                              ) row;
            END IF;

            IF l_json IS NOT NULL
            THEN
                UPDATE docs.arv
                SET properties = properties::JSONB || l_json
                WHERE parentid = v_arv.id;
            END IF;

            l_json = to_json(row)
                     FROM (SELECT now()                    AS updated,
                                  userName                 AS user,
                                  'kustuta_ebatoenaolised' AS task
                          ) row;

            -- снимаем связь с маловероятными со счета
            UPDATE docs.doc
            SET docs_ids   = array_remove(docs_ids, l_doc_id),
                lastupdate = now(),
                history    = coalesce(history, '[]') :: JSONB || l_json::JSONB
            WHERE id = v_arv.id;

        END LOOP;

    result = 1;
    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            result = 0;
            error_code = 9;
            error_message = 'tekkis viga: ' || coalesce(SQLERRM, '');
            RETURN;

END;

$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

ALTER FUNCTION docs.kustuta_ebatoenaolised( INTEGER, INTEGER )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.kustuta_ebatoenaolised(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.kustuta_ebatoenaolised(INTEGER, INTEGER) TO dbpeakasutaja;

--SELECT docs.kustuta_ebatoenaolised(2288915, 28 );
