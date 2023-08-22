DROP FUNCTION IF EXISTS hooldekodu.sp_salvesta_hoo_config(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_salvesta_hoo_config(data JSONB,
                                                             userid INTEGER,
                                                             user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName    TEXT;
    doc_id      INTEGER        = data ->> 'id';
    doc_data    JSON           = data ->> 'data';
    doc_kpv     DATE           = doc_data ->> 'kpv';
    doc_summa   NUMERIC(12, 2) = doc_data ->> 'summa';
    doc_library VARCHAR(20)    = doc_data ->> 'library';
    doc_muud    TEXT           = doc_data ->> 'muud';
    new_history JSONB          = '[]'::JSONB;
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    -- проверка пользователя
    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF userName IS NULL
    THEN
        RAISE EXCEPTION 'Viga, User not found %', user;
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS userName) row;


        INSERT INTO hooldekodu.hoo_config (kpv, summa, muud, ajalugu, library)
        VALUES (doc_kpv, doc_summa, doc_muud, '[]'::JSONB || new_history, doc_library) RETURNING id
            INTO doc_id;
    ELSE
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS userName) row;


        UPDATE hooldekodu.hoo_config
        SET kpv     = doc_kpv,
            summa   = doc_summa,
            ajalugu = ajalugu || new_history,
            muud    = doc_muud
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;

    RETURN doc_id;

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

GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hoo_config(JSONB, INTEGER, INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hoo_config(JSONB, INTEGER, INTEGER) TO hkametnik;


/*

SELECT hooldekodu.sp_salvesta_hooldaja('{"id":0,"data":{"hooldajaid":16810,"muud":"test kontod","isikid":13346,"algkpv":"2022-01-01","loppkpv":"2022-12-31","kohtumaarus":"kohtumäärus"}}'
,3196, 64)


*/