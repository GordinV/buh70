DROP FUNCTION IF EXISTS lapsed.muuda_pank_vv(JSON, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.muuda_pank_vv(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.muuda_pank_vv(data JSONB,
                                                userid INTEGER,
                                                user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName        TEXT;
    docId          INTEGER = data ->> 'id';
    doc_data        JSON    = data ->> 'data';
    doc_pank_id     TEXT    = doc_data ->> 'pank_id';
    doc_summa       NUMERIC = doc_data ->> 'summa';
    doc_kpv         DATE    = doc_data ->> 'kpv';
    doc_maksja      TEXT    = doc_data ->> 'maksja';
    doc_iban        TEXT    = doc_data ->> 'iban';
    doc_selg        TEXT    = doc_data ->> 'selg';
    doc_viitenumber TEXT    = doc_data ->> 'viitenumber';
    doc_pank        TEXT    = doc_data ->> 'pank';
    doc_isikukood   TEXT    = doc_data ->> 'isikukood';
    doc_aa          TEXT    = doc_data ->> 'aa';


BEGIN

    IF (docId IS NULL)
    THEN
        docId = doc_data ->> 'id';
    END IF;


    SELECT kasutaja
           INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    -- апдейт docs.doc
    IF docId IS NOT NULL AND docId > 0
    THEN
        UPDATE lapsed.pank_vv
        SET pank_id     = doc_pank_id,
            pank        = doc_pank,
            isikukood   = doc_isikukood,
            viitenumber = doc_viitenumber,
            iban        = doc_iban,
            aa          = doc_aa,
            selg        = doc_selg,
            maksja      = doc_maksja,
            kpv         = doc_kpv,
            summa       = doc_summa
        WHERE id = docId;

    END IF;

    RETURN docId;

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

GRANT EXECUTE ON FUNCTION lapsed.muuda_pank_vv(JSONB, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.muuda_pank_vv(JSONB, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT lapsed.muuda_pank_vv('{"data":{"docTypeId":"PANK_VV","module":"lapsed","userId":70,"uuid":"196d7650-bcc7-11eb-b761-8bd661173254","docId":23878,"context":null,"userid":"70","id":23878,"kpv":"2021-01-10","pank_id":"2019120200119528-7","viitenumber":"0630000030","maksja":"Vladislav Gordin","isikukood":"37303023721","selg":"Lev Gordin, test makse","doc_id":2334126,"summa":"120.00","iban":"EE852200221045301886","pank":"HABAEE2X","number":"98","row":[{"userid":"70","id":23878,"kpv":"2021-01-10","pank_id":"2019120200119528-7","viitenumber":"0630000030","maksja":"Vladislav Gordin","isikukood":"37303023721","selg":"Lev Gordin, test makse","doc_id":2334126,"summa":"120.00","iban":"EE852200221045301886","pank":"HABAEE2X","number":"98"}],"bpm":[],"requiredFields":[]}}'::JSONB, 70::INTEGER, 63::INTEGER) as id

     { data:


SELECT libs.sp_salvesta_konto('{"id":38,"data":{"doc_type_id":"KONTOD","id":38,"konto_tyyp":null,"kood":"620","library":"KONTOD","muud":"test kontod","nimetus":"Sotsiaalmaks töötasult","rekvid":1,"tun1":1,"tun2":1,"tun3":0,"tun4":0,"tyyp":1,"userid":1,"valid":"20181231"}}'
,1, 1)
*/