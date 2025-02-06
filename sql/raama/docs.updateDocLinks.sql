-- FUNCTION: docs.updatedoclinks(integer, integer, jsonb, jsonb)

-- DROP FUNCTION IF EXISTS docs.updatedoclinks(integer, integer, jsonb, jsonb);

CREATE OR REPLACE FUNCTION docs.updatedoclinks(
    doc_user_id integer,
    doc_id integer,
    new_ids jsonb,
    del_ids jsonb,
    OUT result integer,
    OUT error_message text)
    RETURNS record
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS
$BODY$


DECLARE
    userName   TEXT;
    l_rekv_id  INTEGER = (
                             SELECT
                                 rekvid
                             FROM
                                 ou.userid
                             WHERE
                                 id = doc_user_id
                             LIMIT 1
                         );
    v_docs     RECORD;
    a_docs_ids INTEGER[];
    l_count    INTEGER = 0;
    log        JSONB   = jsonb_build_object('new_ids', new_ids, 'del_ids', del_ids);
BEGIN
    result = 0;
    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
          u.id = doc_user_id
      AND ((u.roles ->> 'is_admin')::BOOLEAN OR (u.roles ->> 'is_peakasutaja')::BOOLEAN OR
           (u.roles ->> 'kasutaja')::BOOLEAN);

    IF userName IS NULL
    THEN
        RAISE EXCEPTION 'Viga: Puudub vajaliku õigused';
    END IF;

    -- новые
    SELECT
        docs_ids
    INTO a_docs_ids
    FROM
        docs.doc
    WHERE
        id = doc_id;


    IF jsonb_array_length(new_ids) > 0
    THEN
        FOR v_docs IN
            SELECT jsonb_array_elements(new_ids::JSONB)::integer AS id
            LOOP

                -- вставка
                a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_docs.id)));
                UPDATE docs.doc
                SET
                    docs_ids = a_docs_ids
                WHERE
                    id = doc_id;

                raise notice 'doc_id %,v_docs.id %, a_docs_ids %',doc_id,v_docs.id, a_docs_ids;

                l_count = l_count + 1;
            END LOOP;
    END IF;

    -- удаление из массива
    SELECT
        docs_ids
    INTO a_docs_ids
    FROM
        docs.doc
    WHERE
        id = doc_id;

    IF jsonb_array_length(del_ids) > 0
    THEN
        FOR v_docs IN
            SELECT jsonb_array_elements(del_ids::JSONB)::integer AS id
            LOOP
                UPDATE docs.doc SET docs_ids = array_remove(docs_ids, v_docs.id) WHERE id = doc_id;
                l_count = l_count + 1;

            END LOOP;
    END IF;

    result = l_count;

    raise notice 'l_count %', l_count;
    IF l_count > 0
    THEN
        INSERT INTO ou.logs (rekvid, user_id, doc_id, propertis)
        VALUES (l_rekv_id, doc_user_id, doc_id, log);
    END IF;

    RETURN;


END ;
$BODY$;

ALTER FUNCTION docs.updatedoclinks(integer, integer, jsonb, jsonb)
    OWNER TO vlad;

GRANT EXECUTE ON FUNCTION docs.updatedoclinks(integer, integer, jsonb, jsonb) TO PUBLIC;

GRANT EXECUTE ON FUNCTION docs.updatedoclinks(integer, integer, jsonb, jsonb) TO dbkasutaja;

GRANT EXECUTE ON FUNCTION docs.updatedoclinks(integer, integer, jsonb, jsonb) TO dbpeakasutaja;

GRANT EXECUTE ON FUNCTION docs.updatedoclinks(integer, integer, jsonb, jsonb) TO vlad;

/*select docs.updateDocLinks (2477, 6403584, '[]'::JSONB, '[6403583]'::JSONB)*/