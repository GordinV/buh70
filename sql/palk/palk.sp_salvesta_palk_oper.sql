DROP FUNCTION IF EXISTS palk.sp_salvesta_palk_oper(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION palk.sp_salvesta_palk_oper(data JSON,
                                                      userid INTEGER,
                                                      user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    oper_id       INTEGER;
    userName      TEXT;
    doc_id        INTEGER = data ->> 'id';
    doc_data      JSON    = data ->> 'data';
    kas_lausend   BOOLEAN = coalesce((doc_data ->> 'kas_lausend') :: BOOLEAN, FALSE);
    doc_type_kood TEXT    = 'PALK_OPER';

    doc_type_id   INTEGER = (SELECT id
                             FROM libs.library
                             WHERE ltrim(rtrim(upper(kood))) = ltrim(rtrim(upper(doc_type_kood)))
                               AND library = 'DOK'
                             LIMIT 1);
    doc_libid     INTEGER = doc_data ->> 'libid';
    doc_lepingid  INTEGER = doc_data ->> 'lepingid';
    doc_kpv       DATE    = doc_data ->> 'kpv';
    doc_summa     NUMERIC = doc_data ->> 'summa';
    doc_dokpropid INTEGER = doc_data ->> 'dokpropid';
    doc_kood1     TEXT    = doc_data ->> 'kood1';
    doc_kood2     TEXT    = doc_data ->> 'kood2';
    doc_kood3     TEXT    = doc_data ->> 'kood3';
    doc_kood4     TEXT    = doc_data ->> 'kood4';
    doc_kood5     TEXT    = doc_data ->> 'kood5';
    doc_konto     TEXT    = doc_data ->> 'konto';
    doc_tp        TEXT    = doc_data ->> 'tp';
    doc_tunnus    TEXT    = doc_data ->> 'tunnus';
    doc_tunnus_id INTEGER = doc_data ->> 'tunnusid';
    doc_proj      TEXT    = doc_data ->> 'proj';
    doc_tulumaks  NUMERIC = doc_data ->> 'tulumaks';
    doc_sotsmaks  NUMERIC = doc_data ->> 'sotsmaks';
    doc_tootumaks NUMERIC = doc_data ->> 'tootumaks';
    doc_pensmaks  NUMERIC = doc_data ->> 'pensmaks';
    doc_tulubaas  NUMERIC = doc_data ->> 'tulubaas';
    doc_tka       NUMERIC = doc_data ->> 'tka';
    doc_period    DATE    = doc_data ->> 'period';
    doc_pohjus    TEXT    = doc_data ->> 'pohjus';
    doc_tululiik  TEXT    = doc_data ->> 'tululiik';
    doc_muud      TEXT    = doc_data ->> 'muud';
    new_history   JSONB;
    docs          INTEGER[];
    l_params      JSON;
    l_result      INTEGER;
    is_import     BOOLEAN = data ->> 'import';
BEGIN
    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    IF doc_tunnus IS NULL AND doc_tunnus_id IS NOT NULL
    THEN
        -- передан ид признака
        doc_tunnus = (SELECT kood FROM libs.library WHERE id = doc_tunnus_id);
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        IF doc_summa = 0 AND doc_tulumaks = 0 AND doc_sotsmaks = 0 AND doc_tootumaks = 0 AND doc_pensmaks = 0 AND
           doc_tulubaas = 0 AND doc_tka = 0
        THEN
            -- нулевая операция, нет смысла
            RAISE NOTICE 'Kõik summad = 0';
            RETURN 0;
        END IF;

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        INSERT INTO docs.doc (doc_type_id, history, rekvid, status)
        VALUES (doc_type_id, '[]' :: JSONB || new_history, user_rekvid, 1) RETURNING id
            INTO doc_id;

        INSERT INTO palk.palk_oper (parentid, rekvid, libid, lepingid, kpv, summa, doklausid,
                                    kood1, kood2, kood3, kood4, kood5, konto, tp, tunnus, proj,
                                    tulumaks, sotsmaks, tootumaks, pensmaks, tulubaas, tka, period, pohjus, tululiik,
                                    ajalugu, muud)

        VALUES (doc_id, user_rekvid, doc_libid, doc_lepingid, doc_kpv, doc_summa, doc_dokpropid,
                doc_kood1, doc_kood2, doc_kood3, doc_kood4, doc_kood5, doc_konto, doc_tp, doc_tunnus, doc_proj,
                doc_tulumaks, doc_sotsmaks, doc_tootumaks, doc_pensmaks,
                doc_tulubaas, doc_tka, doc_period, doc_pohjus, doc_tululiik,
                new_history, doc_muud) RETURNING id
                   INTO oper_id;

    ELSE
        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        -- устанавливаем связи с документами

        -- получим связи документа
        SELECT docs_ids INTO docs
        FROM docs.doc
        WHERE id = doc_id;

        -- will check if arvId exists
        UPDATE docs.doc
        SET docs_ids   = docs,
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history
        WHERE id = doc_id;

        UPDATE palk.palk_oper
        SET kpv       = doc_kpv,
            libid     = doc_libid,
            lepingid  = doc_lepingid,
            summa     = doc_summa,
            doklausid = doc_dokpropid,
            kood1     = doc_kood1,
            kood2     = doc_kood2,
            kood3     = doc_kood3,
            kood4     = doc_kood4,
            kood5     = doc_kood5,
            konto     = doc_konto,
            tp        = doc_tp,
            tunnus    = doc_tunnus,
            proj      = doc_proj,
            tulumaks  = doc_tulumaks,
            sotsmaks  = doc_sotsmaks,
            tootumaks = doc_tootumaks,
            pensmaks  = doc_pensmaks,
            tulubaas  = doc_tulubaas,
            tka       = doc_tka,
            period    = doc_period,
            pohjus    = doc_period,
            ajalugu   = new_history,
            muud      = doc_muud
        WHERE parentid = doc_id RETURNING id
            INTO oper_id;

    END IF;
    -- вставка в таблицы документа

    -- контировка
    IF kas_lausend
    THEN

        SELECT row_to_json(row) INTO l_params
        FROM (SELECT doc_id AS id) row;

        SELECT result INTO l_result
        FROM palk.gen_lausend_palk(userid, l_params);
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


GRANT EXECUTE ON FUNCTION palk.sp_salvesta_palk_oper(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_salvesta_palk_oper(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT palk.sp_salvesta_palk_oper('{"id":1429,"data":{"asutusest":0,"bpm":null,"created":"17.05.2018 07:05:16","doc":"Palga operatsioonid","docs_ids":null,"doc_type_id":"PALK_OPER","dokprop":"Palk","dokpropid":22,"id":1429,"journalid":null,"kas_lausend":"1","konto":"2540","kood1":"","kood2":"","kood3":null,"kood4":null,"kood5":"","kpv":"20180517","lastupdate":"17.05.2018 09:05:22","lausend":0,"lepingid":4,"libid":528,"liik":7,"muud":null,"parentid":56,"pensmaks":0,"period":null,"pohjus":null,"proj":"","rekvid":1,"sotsmaks":0,"status":"????????","summa":24,"tka":0,"tootumaks":0,"tp":"800699","tulubaas":0,"tululiik":"99","tulumaks":0,"tunnus":null}}', 1, 1);


*/
