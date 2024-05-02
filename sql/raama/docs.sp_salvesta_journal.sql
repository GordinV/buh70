DROP FUNCTION IF EXISTS docs.sp_salvesta_journal(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_journal(data JSON,
                                                    userid INTEGER,
                                                    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    journal_id            INTEGER;
    journal1_id           INTEGER;
    userName              TEXT;
    doc_id                INTEGER = data ->> 'id';
    doc_type_kood         TEXT    = 'JOURNAL'/*data->>'doc_type_id'*/;
    doc_type_id           INTEGER = (SELECT id
                                     FROM libs.library
                                     WHERE kood = doc_type_kood
                                       AND library = 'DOK'
                                     LIMIT 1);
    doc_data              JSON    = data ->> 'data';
    doc_details           JSON    = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');
    doc_asutusid          INTEGER = doc_data ->> 'asutusid';
    doc_dok               TEXT    = doc_data ->> 'dok';
    doc_objekt            TEXT    = doc_data ->> 'objekt';
    doc_kpv               DATE    = doc_data ->> 'kpv';
    doc_selg              TEXT    = doc_data ->> 'selg';
    doc_muud              TEXT    = doc_data ->> 'muud';
    doc_asendus_id        INTEGER = doc_data ->> 'asendus_id'; -- при создании проводки из счета , по замещающему табелю в другом учреждении
    l_number              INTEGER = coalesce((SELECT max(number) + 1
                                              FROM docs.journalid
                                              WHERE rekvId = user_rekvid
                                                AND aasta = (date_part('year' :: TEXT, doc_kpv) :: INTEGER)), 1);
    json_object           JSON;
    json_lausend          JSON;

    json_params           JSON;
    json_record           RECORD;
    new_history           JSONB;
    ids                   INTEGER[];
    lnId                  INTEGER;
    is_import             BOOLEAN = data ->> 'import';
    is_rekl_ettemaks      BOOLEAN = FALSE;
    is_hooldekodu_tehing  BOOLEAN = FALSE;
    l_prev_kpv            DATE;
    l_arv_id              INTEGER; --ид счета, если проводка является оплатой
    l_oma_tp              TEXT    = (SELECT tp
                                     FROM ou.aa
                                     WHERE parentid = user_rekvid
                                       AND kassa = 2
                                     LIMIT 1);

    l_check_lausend       TEXT;
    l_avans_id            INTEGER;
    l_db_tp               VARCHAR(20);
    l_kr_tp               VARCHAR(20);
    kas_uus               BOOLEAN = FALSE;
    v_prev_doc            RECORD;
    v_tehing              RECORD;
    l_arvtasu_id          INTEGER;
    l_json_props          JSONB;
    l_osaliselt_suletatud BOOLEAN = FALSE;
    l_suletatud           BOOLEAN = FALSE;


BEGIN

    SELECT 0 AS asutusid, 0 AS id INTO v_prev_doc;

    SELECT kasutaja,
           rekvid
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId
      AND (coalesce((u.roles ->> 'is_kasutaja')::BOOLEAN, FALSE)
        OR
           coalesce((u.roles ->> 'is_peakasutaja')::BOOLEAN, FALSE)
        OR
           coalesce((u.roles ->> 'is_rekl_maksuhaldur')::BOOLEAN, FALSE)
        )::BOOLEAN;
    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE EXCEPTION 'Viga, Kasutaja ei leidnud või puuduvad õigused %, userId %, user_rekvid %', user, userId, user_rekvid;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    -- проверка на период
    IF doc_kpv IS NULL
    THEN
        RAISE NOTICE 'Viga, Null kpv ';
        RETURN 0;
    END IF;

    l_suletatud = (SELECT NOT ou.fnc_aasta_kontrol(user_rekvid, doc_kpv));
    IF (l_suletatud)
    THEN
        l_osaliselt_suletatud = ou.is_last_quarter_opened(user_rekvid, doc_kpv);
    END IF;

    IF is_import IS NULL AND l_suletatud AND NOT l_osaliselt_suletatud
    THEN
        RAISE EXCEPTION 'Viga, Period on kinni, doc_kpv %', doc_kpv;
    END IF;

    -- проверка на символы
    PERFORM check_text(doc_selg);

    -- props
    IF doc_asendus_id IS NOT NULL
    THEN
        l_json_props = jsonb_build_object('asendus_id', doc_asendus_id);
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0 OR NOT exists(SELECT id
                                                  FROM public.cur_journal
                                                  WHERE id = doc_id)
    THEN

        IF is_import IS NULL AND l_suletatud AND l_osaliselt_suletatud
        THEN
            RAISE EXCEPTION 'Viga, Period on kinni, doc_kpv %', doc_kpv;
        END IF;


        kas_uus = TRUE; -- uus lausend

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        INSERT INTO docs.doc (doc_type_id, history, rekvid, status)
        VALUES (doc_type_id, '[]' :: JSONB || new_history, user_rekvid, 1);
        --RETURNING id INTO doc_id;
        SELECT currval('docs.doc_id_seq') INTO doc_id;

        INSERT INTO docs.journal (parentid, rekvid, userid, kpv, asutusid, dok, selg, muud, objekt, properties)
        VALUES (doc_id, user_rekvid, userId, doc_kpv, doc_asutusid, doc_dok, doc_selg, doc_muud,
                doc_objekt, l_json_props);
--                RETURNING id INTO journal_id;
        SELECT currval('docs.journal_id_seq') INTO journal_id;

        INSERT INTO docs.journalid (journalid, rekvid, aasta, number)
        VALUES (journal_id, user_rekvid, (date_part('year' :: TEXT, doc_kpv) :: INTEGER), l_number);

    ELSE

        -- проерка "старого" периода
        SELECT kpv INTO l_prev_kpv FROM docs.journal WHERE id = journal_id;

        IF doc_kpv <> l_prev_kpv AND NOT ou.fnc_aasta_kontrol(user_rekvid, coalesce(l_prev_kpv, doc_kpv)) AND
           NOT is_import
        THEN
            RAISE EXCEPTION 'Viga, Period on kinni';
        END IF;

        IF NOT l_suletatud
        THEN
            -- эти именения только в открытом периоде

            -- запомним прежнее значение
            SELECT id, asutusid INTO v_prev_doc FROM docs.journal WHERE parentid = doc_id;

            SELECT row_to_json(row)
            INTO new_history
            FROM (SELECT now()    AS updated,
                         userName AS user) row;

            UPDATE docs.doc
            SET lastupdate = now(),
                history    = coalesce(history, '[]') :: JSONB || new_history
            WHERE id = doc_id;

            UPDATE docs.journal
            SET kpv        = doc_kpv,
                asutusid   = doc_asutusid,
                dok        = doc_dok,
                objekt     = doc_objekt,
                muud       = doc_muud,
                selg       = doc_selg,
                properties = coalesce(properties, '{}'::JSONB) || l_json_props
            WHERE parentid = doc_id RETURNING id
                INTO journal_id;

        ELSE
            IF l_osaliselt_suletatud
            THEN
                -- оставим историю
                UPDATE docs.doc
                SET history = coalesce(history, '[]') :: JSONB || new_history
                WHERE id = doc_id;

            END IF;

        END IF;


    END IF;
    -- вставка в таблицы документа

    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details)
        LOOP

            SELECT *
            INTO json_record
            FROM json_to_record(
                         json_object) AS x (id TEXT, summa NUMERIC(14, 4), deebet TEXT, kreedit TEXT,
                                            tunnus TEXT, proj TEXT,
                                            kood1 TEXT, kood2 TEXT, kood3 TEXT, kood4 TEXT, kood5 TEXT, lisa_d TEXT,
                                            lisa_k TEXT, objekt TEXT,
                                            valuuta TEXT, kuurs NUMERIC(14, 8));


            IF json_record.summa <> 0
            THEN
                l_db_tp = json_record.lisa_d;
                l_kr_tp = json_record.lisa_k;

                l_db_tp = CASE
                              WHEN json_record.deebet IN ('601000', '601002') THEN '014001'
                              WHEN left(json_record.deebet, 6) IN ('100000', '100080') THEN ''
                              ELSE l_db_tp
                    END;

                l_kr_tp = CASE
                              WHEN json_record.kreedit IN ('601000', '601002') THEN '014001'
                              WHEN left(json_record.kreedit, 6) IN ('100000', '100080') THEN ''
                              ELSE l_kr_tp
                    END;

                IF ltrim(rtrim(json_record.kood1)) = 'null'
                THEN
                    json_record.kood1 = ''::TEXT;
                END IF;
                IF ltrim(rtrim(json_record.kood2)) = 'null'
                THEN
                    json_record.kood2 = ''::TEXT;
                END IF;
                IF ltrim(rtrim(json_record.kood3)) = 'null'
                THEN
                    json_record.kood3 = ''::TEXT;
                END IF;
                IF ltrim(rtrim(json_record.kood4)) = 'null'
                THEN
                    json_record.kood4 = ''::TEXT;
                END IF;
                IF ltrim(rtrim(json_record.kood5)) = 'null'
                THEN
                    json_record.kood5 = ''::TEXT;
                END IF;
                IF ltrim(rtrim(json_record.proj)) = 'null'
                THEN
                    json_record.proj = ''::TEXT;
                END IF;
                IF ltrim(rtrim(json_record.tunnus)) = 'null'
                THEN
                    json_record.tunnus = ''::TEXT;
                END IF;
                IF ltrim(rtrim(json_record.objekt)) = 'null'
                THEN
                    json_record.objekt = ''::TEXT;
                END IF;

                -- проверка проводки
                SELECT row_to_json(row)
                INTO json_lausend
                FROM (SELECT json_record.deebet             AS db,
                             json_record.kreedit            AS kr,
                             coalesce(l_db_tp, '')          AS tpd,
                             coalesce(l_kr_tp, '')          AS tpk,
                             json_record.kood1              AS tt,
                             json_record.kood2              AS allikas,
                             CASE
                                 WHEN ltrim(rtrim(json_record.kood3)) = 'null' THEN NULL::TEXT
                                 ELSE json_record.kood3 END AS rahavoog,
                             json_record.kood5              AS eelarve,
                             doc_kpv                        AS kpv,
                             l_oma_tp                       AS oma_tp
                     ) row;


                l_check_lausend = docs.sp_lausendikontrol(json_lausend::JSONB);

                IF is_import IS NULL AND char_length(l_check_lausend) > 0
                THEN
                    RAISE EXCEPTION '%',l_check_lausend;
                END IF;

                IF (json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW' OR
                    NOT exists(SELECT id
                               FROM docs.journal1
                               WHERE id = json_record.id :: INTEGER)) AND NOT l_osaliselt_suletatud
                THEN

                    INSERT INTO docs.journal1 (parentid, deebet, kreedit, summa, tunnus, proj, kood1, kood2, kood3,
                                               kood4, kood5, objekt,
                                               lisa_d, lisa_k, valuuta, kuurs, valsumma)
                    VALUES (journal_id, json_record.deebet, json_record.kreedit, json_record.summa, json_record.tunnus,
                            json_record.proj,
                            json_record.kood1, json_record.kood2,
                            coalesce(CASE
                                         WHEN ltrim(rtrim(json_record.kood3)) = 'null' THEN NULL::TEXT
                                         ELSE json_record.kood3 END, ''),
                            json_record.kood4,
                            json_record.kood5,
                            coalesce(json_record.objekt, ''),
                            l_db_tp, l_kr_tp,
                            coalesce(json_record.valuuta, 'EUR'), coalesce(json_record.kuurs, 1),
                            coalesce(json_record.kuurs, 1) * json_record.summa);
--                            RETURNING id INTO journal1_id;
                    SELECT currval('docs.journal1_id_seq') INTO journal1_id;

                    -- add new id into array of ids
                    ids = array_append(ids, journal1_id);

                ELSE
                    IF l_osaliselt_suletatud
                    THEN
                        -- допустимо менять только доп. классификаторы

                        UPDATE docs.journal1
                        SET tunnus = json_record.tunnus,
                            proj   = json_record.proj,
                            kood4  = json_record.kood4,
                            objekt = coalesce(json_record.objekt, '')
                        WHERE id = json_record.id :: INTEGER;
                    ELSE

                        UPDATE docs.journal1
                        SET deebet   = json_record.deebet,
                            kreedit  = json_record.kreedit,
                            summa    = json_record.summa,
                            tunnus   = json_record.tunnus,
                            proj     = json_record.proj,
                            kood1    = json_record.kood1,
                            kood2    = json_record.kood2,
                            kood3    = coalesce(CASE
                                                    WHEN ltrim(rtrim(json_record.kood3)) = 'null' THEN NULL::TEXT
                                                    ELSE json_record.kood3 END, ''),
                            kood4    = json_record.kood4,
                            kood5    = json_record.kood5,
                            objekt   = coalesce(json_record.objekt, ''),
                            lisa_d   = coalesce(l_db_tp, ''),
                            lisa_k   = coalesce(l_kr_tp, ''),
                            kuurs    = 1,
                            valuuta  = 'EUR',
                            valsumma = json_record.summa
                        WHERE id = json_record.id :: INTEGER;

                        journal1_id = json_record.id :: INTEGER;
                    END IF;

                    -- add existing id into array of ids
                    ids = array_append(ids, journal1_id);
                END IF;

            END IF;

            IF NOT l_osaliselt_suletatud
            THEN

--avans
                SELECT a1.parentid
                INTO l_avans_id
                FROM docs.avans1 a1
                         INNER JOIN libs.dokprop d ON d.id = a1.dokpropid
                WHERE ltrim(rtrim(number::TEXT)) = ltrim(rtrim(doc_dok::TEXT))
                  AND a1.rekvid = user_rekvid
                  AND a1.asutusId = doc_asutusid
                  AND ltrim(rtrim(coalesce((d.details :: JSONB ->> 'konto'), '') :: TEXT)) IN ('202050')
                ORDER BY a1.kpv DESC
                LIMIT 1;

                IF l_avans_id IS NOT NULL AND exists(SELECT 1 FROM pg_proc WHERE proname = 'get_avans_jaak')
                THEN
                    PERFORM docs.get_avans_jaak(l_avans_id);
                END IF;

                SELECT a1.parentid
                INTO lnId
                FROM docs.avans1 a1
                         INNER JOIN libs.dokprop d ON d.id = a1.dokpropid
                WHERE ltrim(rtrim(a1.number::TEXT)) = ltrim(rtrim(doc_dok::TEXT))
                  AND a1.rekvid = user_rekvid
                  AND a1.asutusId = doc_asutusid
                  AND (ltrim(rtrim((d.details :: JSONB ->> 'konto')::TEXT)) = ltrim(rtrim(json_record.deebet)) OR
                       ltrim(rtrim((d.details :: JSONB ->> 'konto')::TEXT)) = ltrim(rtrim(json_record.kreedit)))
                ORDER BY a1.kpv
                    DESC
                LIMIT 1;

                IF lnId IS NOT NULL AND exists(SELECT 1 FROM pg_proc WHERE proname = 'get_avans_jaak')
                THEN
                    PERFORM docs.get_avans_jaak(lnId);
                END IF;

                -- reklmaks
                IF (json_record.kreedit = '200060' OR json_record.kreedit = '200095') AND
                   doc_selg <> 'Alg.saldo kreedit'
                THEN
                    is_rekl_ettemaks = TRUE;
                END IF;


                IF (user_rekvid IN (64, 132) AND
                    ((left(json_record.kreedit, 6) IN ('203630', '203560')) OR
                     (left(json_record.deebet, 6) IN ('203630', '203560'))) AND
                    doc_selg <> 'Alg.saldo kreedit')
                    OR exists(SELECT id FROM hooldekodu.hootehingud WHERE hootehingud.journalid = doc_id)
                THEN
                    is_hooldekodu_tehing = TRUE;
                END IF;
            END IF;
        END LOOP;
    -- delete record which not in json

    IF NOT l_osaliselt_suletatud
    THEN

        DELETE
        FROM docs.journal1
        WHERE parentid = journal_id
          AND id NOT IN (SELECT unnest(ids));

        -- rekl ettemaks

        IF is_rekl_ettemaks AND exists(SELECT 1 FROM pg_proc WHERE proname = 'sp_koosta_ettemaks')
        THEN
            SELECT row_to_json(row)
            INTO json_params
            FROM (SELECT doc_id AS id,
                         1      AS liik) row;

            PERFORM rekl.sp_koosta_ettemaks(userid, json_params);
        END IF;

        -- arve tasumine

        l_arv_id = (SELECT d.id
                    FROM docs.arv a
                             INNER JOIN docs.doc d ON a.parentid = d.id
                    WHERE a.asutusid = doc_asutusid
                      AND number = doc_dok
                      AND a.rekvid = user_rekvid
                      AND a.journalid <> doc_id
                    ORDER BY a.jaak DESC
                            , a.kpv
                    LIMIT 1
        );

        IF is_import IS NULL AND l_arv_id IS NOT NULL
        THEN
            PERFORM docs.sp_tasu_arv(
                            doc_id, l_arv_id, userid);
        END IF;

        -- если номер документа отуствует, но есть связь со счетом, то удалыям оплату (В.Бешекерскас 15.01.2023)
        IF exists(SELECT id FROM docs.arvtasu WHERE doc_tasu_id = doc_id AND status < 3) AND empty(doc_dok)
        THEN
            l_arvtasu_id =
                    (SELECT id FROM docs.arvtasu WHERE doc_tasu_id = doc_id AND status < 3 ORDER BY id DESC LIMIT 1);
            IF l_arvtasu_id IS NOT NULL
            THEN
                PERFORM docs.sp_delete_arvtasu(userid, l_arvtasu_id);
            END IF;
        END IF;

        -- hooldekodu
-- hooldekodu

        IF is_hooldekodu_tehing AND exists(SELECT 1 FROM pg_proc WHERE proname = 'sp_koosta_hootehing')
        THEN
            -- если изменилось имя пенсионера
            IF NOT kas_uus
            THEN
                -- удалем связанные старые операции
/*            PERFORM hooldekodu.sp_delete_hootehing(userid, id, true)
            FROM hooldekodu.hootehingud
            WHERE hootehingud.journalid = doc_id
              AND status < 3;
*/
                UPDATE hooldekodu.hootehingud
                SET status = 3
                WHERE hootehingud.journalid = doc_id
                  AND status < 3;
            END IF;

            SELECT row_to_json(row)
            INTO json_params
            FROM (SELECT doc_id AS id,
                         1      AS liik) row;

            PERFORM hooldekodu.sp_koosta_hootehing(userid, json_params::JSONB);

        END IF;
    END IF;
    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION docs.sp_salvesta_journal(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_journal(JSON, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT ALL ON FUNCTION docs.sp_salvesta_journal(JSON, INTEGER, INTEGER) TO dbadmin;

/*


{"data":{"id":1436,"doc_type_id":"JOURNAL","kpv":"2018-05-17","selg":"Palk","muud":"test","asutusid":56},"gridData":[{"id":0,"summa":289.2000,"deebet":"2610","lisa_d":"800699","kreedit":"2530","lisa_k":"800699","tunnus":null,"proj":"","kood1":"","kood2":"","kood3":"","kood4":"","kood5":""}]}

select * from docs.journal1 where parentid = 14

*/
