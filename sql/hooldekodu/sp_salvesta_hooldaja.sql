DROP FUNCTION IF EXISTS hooldekodu.sp_salvesta_hooldaja(JSON, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS hooldekodu.sp_salvesta_hooldaja(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_salvesta_hooldaja(data JSONB,
                                                           userid INTEGER,
                                                           user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName        TEXT;
    doc_id          INTEGER = data ->> 'id';
    doc_data        JSON    = data ->> 'data';
    doc_algkpv      DATE    = doc_data ->> 'algkpv';
    doc_loppkpv     DATE    = doc_data ->> 'loppkpv';
    doc_kohtumaarus TEXT    = doc_data ->> 'kohtumaarus';
    doc_isikid      INTEGER = doc_data ->> 'isikid';
    doc_hooldajaid  INTEGER = doc_data ->> 'hooldajaid';
    doc_muud        TEXT    = doc_data ->> 'muud';
    is_import       BOOLEAN = data ->> 'import';
    json_object     JSONB;
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;


    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE EXCEPTION 'User not found %', user;
        RETURN 0;
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO hooldekodu.hooldaja (hooldajaid, isikid, kohtumaarus, algkpv, loppkpv, muud, status)
        VALUES (doc_hooldajaid, doc_isikid, doc_kohtumaarus, doc_algkpv, doc_loppkpv, doc_muud, 1) RETURNING id
            INTO doc_id;
    ELSE

        UPDATE hooldekodu.hooldaja
        SET hooldajaid  = doc_hooldajaid,
            kohtumaarus = doc_kohtumaarus,
            algkpv      = doc_algkpv,
            loppkpv     = doc_loppkpv,
            muud        = doc_muud
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

GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooldaja(JSONB, INTEGER, INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooldaja(JSONB, INTEGER, INTEGER) TO hkametnik;


/*

SELECT hooldekodu.sp_salvesta_hooldaja('{"id":0,"data":{"hooldajaid":16810,"muud":"test kontod","isikid":13346,"algkpv":"2022-01-01","loppkpv":"2022-12-31","kohtumaarus":"kohtumäärus"}}'
,3196, 64)


*/