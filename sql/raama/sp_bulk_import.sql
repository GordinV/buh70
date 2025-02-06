DROP FUNCTION IF EXISTS docs.sp_bulk_import(INTEGER, INTEGER, TEXT);

CREATE OR REPLACE FUNCTION docs.sp_bulk_import(In user_id integer, In rekv_id integer, IN import_data TEXT,
                                               OUT result INTEGER,
                                               OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName    TEXT;
    doc_id      INTEGER;
    count       INTEGER;
    json_object JSONB;
BEGIN

    RAISE NOTICE 'doc_data %',import_data;

    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
        u.id = user_id;

    IF userName IS NULL
    THEN
        error_message = 'User not found ';
        json_object = to_jsonb(row.*)
                      FROM
                          (
                              SELECT
                                  NULL::INTEGER AS doc_id,
                                  error_message AS error_message,
                                  TRUE          AS kas_vigane,
                                  1::INTEGER    AS error_code
                          ) row;

        RETURN;
    END IF;


    result = count;
    RETURN;


END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_bulk_import (INTEGER, INTEGER, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_bulk_import (INTEGER, INTEGER, TEXT) TO dbpeakasutaja;


/*
SELECT docs.sp_bulk_import(2477, 63, 'ï»¿30.12.2024;Palk 09 2024 Revis;46002203715;BeÅ¡ekerskas Valentina ;50012001;800699;202000;PÃµhipalk ja kokkulepitud tasud;800699;2669.00;;01112;LE-P;5001;;;;75008427;69177.95;;;;;;;;;;;;;;;;;
'::TEXT)
*/
