DROP FUNCTION IF EXISTS ou.sp_salvesta_arvete_meil(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION ou.sp_salvesta_arvete_meil(data JSON,
                                                      user_id INTEGER,
                                                      user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName         TEXT;
    doc_id           INTEGER = data ->> 'id';
    doc_data         JSON    = data ->> 'data';
    doc_alg_kpv      DATE    = doc_data ->> 'alg_kpv';
    doc_lopp_kpv     DATE    = doc_data ->> 'lopp_kpv';
    doc_kas_alusta   BOOLEAN = coalesce((doc_data ->> 'kas_alusta')::BOOLEAN, FALSE);
    doc_muud         TEXT    = doc_data ->> 'muud';
    doc_paus         BOOLEAN = (doc_data ->> 'paus')::BOOLEAN;
    l_alus_ametnik   INTEGER = user_id;
    l_alus_timestamp TIMESTAMP;
    l_paus_timestamp TIMESTAMP;
    l_paus_ametnik   INTEGER;
    new_history      JSONB;
    v_dok            RECORD;

BEGIN
    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id
      AND (u.roles ->> 'is_admin')::BOOLEAN;

    IF userName IS NULL
    THEN
        RAISE EXCEPTION 'User not found %', user;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT to_jsonb(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        IF (doc_kas_alusta)
        THEN
            l_alus_ametnik = user_id;
            l_alus_timestamp = now();
        END IF;

        INSERT INTO ou.arvete_meil (rekvid, user_id, kas_alusta, kas_alusta_timestamp, alusta_ametnik, alg_kpv,
                                    lopp_kpv, muud, ajalugu)
        VALUES (user_rekvid, user_id, doc_kas_alusta, l_alus_timestamp, l_alus_ametnik, doc_alg_kpv, doc_lopp_kpv,
                doc_muud, new_history) RETURNING id
                   INTO doc_id;

    ELSE

        -- прежнее значение
        SELECT * INTO v_dok FROM ou.arvete_meil WHERE id = doc_id;

        -- логгируем историю
        SELECT to_jsonb(row)
        INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user,
                     a.alg_kpv,
                     a.lopp_kpv,
                     a.kas_alusta,
                     a.paus,
                     a.muud
              FROM ou.arvete_meil a
              WHERE a.id = doc_id) row;

        -- если отметка о начале изменилась, то запомним кто и когда
        IF (doc_kas_alusta AND NOT v_dok.kas_alusta)
        THEN
            l_alus_ametnik = user_id;
            l_alus_timestamp = now();
        ELSE
            l_alus_ametnik = v_dok.alusta_ametnik;
            l_alus_timestamp = v_dok.kas_alusta_timestamp;
        END IF;

        -- если отправка счетов еще не начата, то пауза не имеет смысла
        IF NOT doc_kas_alusta AND coalesce(doc_paus, FALSE)
        THEN
            doc_paus = NULL;
            l_paus_ametnik = NULL;
            l_paus_timestamp = NULL;
        END IF;

        IF doc_kas_alusta
        THEN
            -- отправка начата, отрабатываем паузу
            IF doc_paus IS NOT NULL AND doc_paus <> coalesce(v_dok.paus,false)
            THEN
                l_paus_ametnik = user_id;
                l_paus_timestamp = now();
            ELSE
                l_paus_ametnik = v_dok.paus_ametnik;
                l_paus_timestamp = v_dok.paus_timestamp;
            END IF;

        END IF;


        UPDATE ou.arvete_meil
        SET alg_kpv              = doc_alg_kpv,
            lopp_kpv             = doc_lopp_kpv,
            kas_alusta           = doc_kas_alusta,
            kas_alusta_timestamp = l_alus_timestamp,
            alusta_ametnik       = l_alus_ametnik,
            paus                 = doc_paus,
            paus_timestamp       = l_paus_timestamp,
            paus_ametnik         = l_paus_ametnik,
            muud                 = doc_muud,
            ajalugu              = arvete_meil.ajalugu || new_history
        WHERE id = doc_id RETURNING id
            INTO doc_id;
    END IF;

    RETURN doc_id;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE EXCEPTION 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION ou.sp_salvesta_arvete_meil(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_arvete_meil(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT ou.sp_salvesta_rekv('{"id":1,"data":{"docTypeId":"REKV","module":"lapsed","userId":70,"uuid":"679c46a0-181b-11ea-9662-c7e1326a899d","docId":63,"context":null,"doc_type_id":"REKV","userid":70,"id":63,"parentid":0,"nimetus":"RAHANDUSAMET T","aadress":"Peetri 5, Narva","email":"rahandus@narva.ee","faks":"3599181","haldus":"","juht":"Jelena Golubeva","raama":"Jelena Tsekanina","kbmkood":"","muud":"Narva Linnavalitsuse Rahandusamet","regkood":"75008427","tel":"3599190","tahtpaev":null,"ftp":null,"login":null,"parool":null,"earved":"106549:elbevswsackajyafdoupavfwewuiafbeeiqatgvyqcqdqxairz","earved_omniva":"https://finance.omniva.eu/finance/erp/","row":[{"doc_type_id":"REKV","userid":70,"id":63,"parentid":0,"nimetus":"RAHANDUSAMET T","aadress":"Peetri 5, Narva","email":"rahandus@narva.ee","faks":"3599181","haldus":"","juht":"Jelena Golubeva","raama":"Jelena Tsekanina","kbmkood":"","muud":"Narva Linnavalitsuse Rahandusamet","regkood":"75008427","tel":"3599190","tahtpaev":null,"ftp":null,"login":null,"parool":null,"earved":"106549:elbevswsackajyafdoupavfwewuiafbeeiqatgvyqcqdqxairz","earved_omniva":"https://finance.omniva.eu/finance/erp/"}],"details":[{"id":1,"arve":"TP                  ","nimetus":"RAHANDUSAMET                                                                                                                                                                                                                                                  ","default_":1,"kassa":2,"pank":1,"konto":"","tp":"18510101","kassapank":2,"userid":"70"},{"id":2,"arve":"EE051010562011276005","nimetus":"SEB                                                                                                                                                                                                                                                           ","default_":1,"kassa":1,"pank":401,"konto":"10010002","tp":"800401","kassapank":1,"userid":"70"},{"id":3,"arve":"kassa               ","nimetus":"Kassa                                                                                                                                                                                                                                                         ","default_":1,"kassa":0,"pank":1,"konto":"100000","tp":"18510101","kassapank":0,"userid":"70"}],"gridConfig":[{"id":"id","name":"id","width":"0px","show":false,"type":"text","readOnly":true},{"id":"arve","name":"Arve","width":"100px","show":true,"type":"text","readOnly":false},{"id":"nimetus","name":"Nimetus","width":"300px","show":true,"readOnly":true},{"id":"konto","name":"Konto","width":"100px","show":true,"type":"text","readOnly":false},{"id":"tp","name":"TP","width":"100px","show":true,"type":"text","readOnly":false}],"default.json":[{"id":75,"number":"","rekvid":63,"toolbar1":0,"toolbar2":0,"toolbar3":0,"tahtpaev":14,"keel":2,"port":"465","smtp":"smtp.gmail.com","user":"vladislav.gordin@gmail.com","pass":"Vlad490710A","email":"vladislav.gordin@gmail.com","earved":"https://finance.omniva.eu/finance/erp/"}],"gridData":[{"id":"NEW0.352711495575625","arve":"EE712200221023241719","nimetus":"test arve","konto":"10010009","tp":"","kassapank":"1"},{"id":1,"arve":"TP                  ","nimetus":"RAHANDUSAMET                                                                                                                                                                                                                                                  ","default_":1,"kassa":2,"pank":1,"konto":"","tp":"18510101","kassapank":2,"userid":"70"},{"id":2,"arve":"EE051010562011276005","nimetus":"SEB                                                                                                                                                                                                                                                           ","default_":1,"kassa":1,"pank":401,"konto":"10010002","tp":"800401","kassapank":1,"userid":"70"},{"id":3,"arve":"kassa               ","nimetus":"Kassa                                                                                                                                                                                                                                                         ","default_":1,"kassa":0,"pank":1,"konto":"100000","tp":"18510101","kassapank":0,"userid":"70"}],"bpm":[],"requiredFields":[{"name":"regkood","type":"C"},{"name":"nimetus","type":"C"}]}}', 70, 63);

*/
