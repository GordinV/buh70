DROP FUNCTION IF EXISTS hooldekodu.sp_salvesta_hooettemaks(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_salvesta_hooettemaks(data JSONB,
                                                              userid INTEGER,
                                                              user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName    TEXT;
    doc_id      INTEGER        = data ->> 'id';
    doc_data    JSON           = data ->> 'data';
    doc_isikid  INTEGER        = doc_data ->> 'asutusid';
    doc_kpv     DATE           = doc_data ->> 'kpv';
    doc_summa   NUMERIC(14, 2) = doc_data ->> 'summa';
    doc_dokid   INTEGER        = doc_data ->> 'dokid';
    doc_doktyyp TEXT           = doc_data ->> 'doktyyp';
    doc_allikas TEXT           = doc_data ->> 'allikas';
    doc_selg    TEXT           = doc_data ->> 'selg';
    doc_muud    TEXT           = doc_data ->> 'muud';
    is_import   BOOLEAN        = data ->> 'import';
BEGIN

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF (is_import IS NULL OR NOT is_import) AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO hooldekodu.hooettemaksud (isikid, kpv, selg, muud, summa, staatus, dokid, doktyyp)
        VALUES (doc_isikid, doc_kpv, doc_selg, doc_muud, doc_summa, 1, doc_dokid, doc_doktyyp) RETURNING id
            INTO doc_id;

    ELSE

        UPDATE hooldekodu.hooettemaksud
        SET kpv     = doc_kpv,
            selg    = doc_selg,
            muud    = doc_muud,
            summa   = doc_summa,
            dokid   = doc_dokid,
            doktyyp = doc_doktyyp
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;
    -- вставка в таблицы документа
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


GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooettemaks(JSONB, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooettemaks(JSONB, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooettemaks(JSONB, INTEGER, INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hooettemaks(JSONB, INTEGER, INTEGER) TO hkametnik;

/*
SELECT rekl.sp_salvesta_ettemaksud('{
  "id": 0,
  "data": {
    "number": 1,
    "kpv": "2018-06-19",
    "asutusid": 1,
    "selg": "test",
    "summa": 100
  }
}', 1, 1);

*/