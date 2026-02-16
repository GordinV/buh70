DROP FUNCTION IF EXISTS ou.sp_salvesta_task(TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS ou.sp_salvesta_task(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION ou.sp_salvesta_task(in doc_sql text, in doc_nimetus text,
                                               user_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName TEXT;
    doc_id   INTEGER;

BEGIN

    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
        u.id = user_id;

    IF userName IS NULL
    THEN
        RAISE EXCEPTION 'Viga: User not found %', user;
    END IF;


    insert into ou.task (user_id, nimetus, sql)
    values (user_id, doc_nimetus, doc_sql)
    returning id into doc_id;

    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION ou.sp_salvesta_task(TEXT, TEXT, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_task(TEXT, TEXT, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_task(TEXT, TEXT, INTEGER) TO dbpeakasutaja;

/*

SELECT ou.sp_salvesta_task('select palk.loe_puudumised(2477, ''{
      "puudumiste_ids": [
        161918
      ]
    }''::jsonb','Arvesta puudumised',2477);



*/
