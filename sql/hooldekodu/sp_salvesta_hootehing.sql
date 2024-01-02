DROP FUNCTION IF EXISTS hooldekodu.sp_salvesta_hootehing(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_salvesta_hootehing(data JSONB,
                                                            userid INTEGER,
                                                            user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName          TEXT;
    doc_id            INTEGER        = data ->> 'id';
    doc_data          JSON           = data ->> 'data';
    doc_isikid        INTEGER        = doc_data ->> 'isikid';
    doc_ettemaksid    INTEGER        = doc_data ->> 'ettemaksid';
    doc_dokid         INTEGER        = doc_data ->> 'dokid';
    doc_journalid     INTEGER        = doc_data ->> 'journalid';
    doc_kpv           DATE           = doc_data ->> 'kpv';
    doc_summa         NUMERIC(14, 2) = doc_data ->> 'summa';
    doc_tyyp          TEXT           = doc_data ->> 'tyyp';
    doc_doktyyp       TEXT           = doc_data ->> 'doktyyp';
    doc_allikas       TEXT           = doc_data ->> 'allikas';
    doc_muud          TEXT           = doc_data ->> 'muud';
    is_import         BOOLEAN        = data ->> 'import';
    l_tehingu_summa   NUMERIC;
    l_ettemaksu_summa NUMERIC;

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

        INSERT INTO hooldekodu.hootehingud (rekvid, isikid, journalid, dokid, doktyyp, kpv, summa, allikas, tyyp, muud)
        VALUES (user_rekvid, doc_isikid, doc_journalid, doc_dokid, doc_doktyyp, doc_kpv, doc_summa, doc_allikas,
                doc_tyyp,
                doc_muud) RETURNING id
                   INTO doc_id;

    ELSE

        UPDATE hooldekodu.hootehingud
        SET kpv       = doc_kpv,
            isikid    = doc_isikid,
            muud      = doc_muud,
            summa     = doc_summa,
            dokid     = doc_dokid,
            journalid = doc_journalid,
            allikas   = doc_allikas,
            tyyp      = doc_tyyp,
            doktyyp   = doc_doktyyp
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;

    -- arvestame jaagid
    PERFORM hooldekodu.sp_calc_hoojaak(doc_isikid);

    -- uhendame arved ja isik
    IF NOT exists(SELECT id
                  FROM hooldekodu.hoouhendused
                  WHERE isikid = doc_isikid
                    AND dokid = doc_dokid
                    AND doktyyp = doc_doktyyp)
    THEN
        INSERT INTO hooldekodu.hoouhendused (rekvid, isikid, dokid, doktyyp)
        VALUES (user_rekvid, doc_isikid, doc_dokid, doc_doktyyp);
    END IF;


    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hootehing(JSONB, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hootehing(JSONB, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hootehing(JSONB, INTEGER, INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_salvesta_hootehing(JSONB, INTEGER, INTEGER) TO hkametnik;

/*
SELECT hooldekodu.sp_salvesta_hootehing('{
  "id": 0,
  "data": {
    "isikid": 13346,
    "ettemaksid":3,
    "allikas":"PENSION85",
    "tyyp":"TULUD",
    "dokid":2379498,
    "kpv": "2022-07-19",
    "summa": 200
  }
}', 3196, 64);

select * from ou.userid where rekvid = 64 and kasutaja = 'vlad'

*/