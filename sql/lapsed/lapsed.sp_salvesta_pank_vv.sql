DROP FUNCTION IF EXISTS lapsed.sp_salvesta_pank_vv(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_pank_vv(IN import_data JSONB,
                                                      IN user_id INTEGER,
                                                      IN user_rekvid INTEGER,
                                                      OUT result INTEGER,
                                                      OUT stamp TEXT,
                                                      OUT error_message TEXT,
                                                      OUT data JSONB)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName      TEXT;
    doc_data      JSON      = import_data ->> 'data';
    doc_pank_id   TEXT      = doc_data ->> 'pank_id';
    doc_viitenr   TEXT      = doc_data ->> 'viitenr';
    doc_maksja    TEXT      = doc_data ->> 'maksja';
    doc_iban      TEXT      = doc_data ->> 'iban';
    doc_summa     NUMERIC   = doc_data ->> 'summa';
    doc_kpv       DATE      = doc_data ->> 'kpv';
    doc_selg      TEXT      = doc_data ->> 'selg';
    doc_pank      TEXT      = doc_data ->> 'pank';
    doc_number    TEXT      = doc_data ->> 'number';
    doc_isikukood TEXT      = doc_data ->> 'isikukood';
    doc_aa        TEXT      = doc_data ->> 'aa';
    json_object   JSON;
    count         INTEGER   = 0;
    json_record   RECORD;
    l_timestamp   TIMESTAMP = now();
    v_tulemus     RECORD;
    l_message     TEXT;
    l_viitenr     TEXT;
    l_kas_vigane  BOOLEAN   = FALSE;
    doc_id        INTEGER   = data ->> 'id';

BEGIN

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;

    IF userName IS NULL
    THEN
        error_message = 'User not found';
        json_object = to_jsonb(row.*)
                      FROM (
                               SELECT NULL::INTEGER AS doc_id,
                                      error_message AS error_message,
                                      TRUE          AS kas_vigane,
                                      1::INTEGER    AS error_code
                           ) row;
        data = coalesce(data, '[]'::JSONB) || json_object::JSONB;

        RETURN;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;


    IF doc_id IS NULL
    THEN
        FOR json_object IN
            SELECT *
            FROM json_array_elements(doc_data)
            LOOP

                SELECT *
                INTO json_record
                FROM json_to_record(
                             json_object) AS x (pank_id TEXT, summa NUMERIC(12, 2), kpv DATE, maksja TEXT, iban TEXT,
                                                selg TEXT, viitenr TEXT, pank TEXT, number TEXT, isikukood TEXT,
                                                aa TEXT);

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
        SELECT *
        FROM lapsed.read_pank_vv(user_id::INTEGER, l_timestamp::TEXT)
        INTO v_tulemus;

        IF v_tulemus.result > 0 OR v_tulemus.error_code IS NOT NULL OR v_tulemus.error_message IS NOT NULL
        THEN
            -- report
            data = coalesce(data, '[]'::JSONB) || coalesce(v_tulemus.data, '[]'::JSONB);
            error_message = v_tulemus.error_message;
        END IF;

    ELSE
        UPDATE lapsed.pank_vv
        SET pank_id     = doc_pank_id,
            viitenumber = doc_viitenr,
            maksja      = doc_maksja,
            iban        = doc_iban,
            summa       = doc_summa,
            kpv         = doc_kpv,
            selg        = doc_selg,
            pank        = doc_pank,
            number      = doc_number,
            isikukood   = doc_isikukood,
            aa          = doc_aa
        WHERE id = doc_id;

        count = 1;
    END IF;


    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_message = SQLERRM;
            result = 0;
            json_object = to_jsonb(row.*)
                          FROM (
                                   SELECT NULL::INTEGER                     AS doc_id,
                                          l_message || ',' || error_message AS error_message,

                                          1::INTEGER                        AS error_code
                               ) row;
            data = coalesce(data, '[]'::JSONB) || json_object::JSONB;

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