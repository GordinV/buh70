DROP FUNCTION IF EXISTS hooldekodu.sp_salvesta_hooltaabel(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_salvesta_hooltaabel(data JSONB,
                                                             userid INTEGER,
                                                             user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName      TEXT;
    doc_id        INTEGER = data ->> 'id';
    doc_data      JSON    = data ->> 'data';
    doc_kpv       DATE    = doc_data ->> 'kpv';
    doc_isikid    INTEGER = doc_data ->> 'isikid';
    doc_nomid     INTEGER = doc_data ->> 'nomid';
    doc_kogus     NUMERIC = doc_data ->> 'kogus';
    doc_summa     NUMERIC = doc_data ->> 'summa';
    doc_arvid     INTEGER = doc_data ->> 'arvid';
    doc_tuluarvid INTEGER = doc_data ->> 'tuluarvid';
    doc_muud      TEXT    = doc_data ->> 'muud';
    is_import     BOOLEAN = data ->> 'import';
    json_object   JSONB;
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
        INSERT INTO hooldekodu.hootaabel(isikid, nomid, kpv, kogus, summa, arvid, tuluarvid, muud)
        VALUES (doc_isikid, doc_nomid, doc_kpv, doc_kogus, doc_summa, 0, 0, doc_muud) RETURNING id
            INTO doc_id;
    ELSE

        UPDATE hooldekodu.hootaabel
        SET kpv       = doc_kpv,
            nomid     = doc_nomid,
            kogus     = doc_kogus,
            summa     = doc_summa,
            arvid     = doc_arvid,
            tuluarvid = doc_tuluarvid,
            muud      = doc_muud
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

GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooltaabel(JSONB, INTEGER, INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooltaabel(JSONB, INTEGER, INTEGER) TO hkametnik;


/*

SELECT hooldekodu.sp_salvesta_hooltaabel('{"id":0,"data":{"muud":"test kontod","isikid":13346,"kpv":"2022-07-01","summa":200,"kogus":1,"nomid":17234}}'
,3196, 64)


select * from libs.nomenklatuur where rekvid = 64 and dok =  'ARV'
*/