DROP FUNCTION IF EXISTS lapsed.sp_salvesta_pank_vv(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_pank_vv(IN data JSONB,
                                                      IN user_id INTEGER,
                                                      IN user_rekvid INTEGER,
                                                      OUT result INTEGER,
                                                      OUT stamp TEXT,
                                                      OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName    TEXT;
    doc_data    JSON      = data ->> 'data';
    json_object JSON;
    count       INTEGER   = 0;
    json_record RECORD;
    l_timestamp TIMESTAMP = now();
BEGIN

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;
    IF userName IS NULL
    THEN
        error_message = 'User not found';

        RETURN;
    END IF;


    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_data)
        LOOP
            SELECT * INTO json_record
            FROM json_to_record(
                         json_object) AS x (pank_id TEXT, summa NUMERIC(12, 2), kpv DATE, maksja TEXT, iban TEXT,
                                            selg TEXT, viitenr TEXT, pank TEXT, number TEXT, isikukood text, aa text);

            -- проверяем уникальность записи по pank_id

            IF NOT exists(SELECT 1 FROM lapsed.pank_vv WHERE pank_id = json_record.pank_id)
            THEN

                INSERT INTO lapsed.pank_vv (userid, pank_id, viitenumber, maksja, iban, summa, kpv, selg, timestamp,
                                            pank, number, isikukood, aa)
                VALUES (user_id, json_record.pank_id, json_record.viitenr, json_record.maksja, json_record.iban,
                        json_record.summa, json_record.kpv, json_record.selg, l_timestamp, json_record.pank,
                        json_record.number, json_record.isikukood, json_record.aa);

                count = count + 1;
            END IF;
        END LOOP;

    -- расшифруем платежи
    result = count;
    stamp = l_timestamp::TEXT;

    -- расшифруем
    PERFORM lapsed.read_pank_vv(user_id::INTEGER, l_timestamp::TEXT);

    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_message = SQLERRM;
            RETURN;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_pank_vv (JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_pank_vv (JSONB, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_pank_vv (JSONB, INTEGER, INTEGER) TO dbpeakasutaja;


/*

select lapsed.sp_salvesta_pank_vv('{"data":[{"pank_id":"2,0191E+15","summa":null,"kpv":"13.10.2019","selg":"Proizvolny selgitus","viitenr":"9083141","maksja":"MAKSJA NIMI","iban":"EE862200001105183180"},{"pank_id":"2,0191E+15","summa":28,"kpv":"13.10.2019","selg":"Proizvolny selgitus","viitenr":"8981671","maksja":"MAKSJA NIMI","iban":"EE862200001105183180"}]}'::jsonb, 70::integer, 63::integer) as id

*/