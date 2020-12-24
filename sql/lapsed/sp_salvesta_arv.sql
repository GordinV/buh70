DROP FUNCTION IF EXISTS docs.sp_salvesta_arv(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_arv(data JSON,
                                                user_id INTEGER,
                                                user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    arv_id                INTEGER;
    arv1_id               INTEGER;
    userName              TEXT;
    doc_id                INTEGER        = data ->> 'id';
    doc_data              JSON           = data ->> 'data';
    doc_type_kood         TEXT           = 'ARV'/*data->>'doc_type_id'*/;
    doc_type_id           INTEGER        = (SELECT id
                                            FROM libs.library
                                            WHERE kood = doc_type_kood
                                              AND library = 'DOK'
                                            LIMIT 1);

    doc_details           JSON           = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');
    doc_number            TEXT           = doc_data ->> 'number';
    doc_summa             NUMERIC(14, 4) = coalesce((doc_data ->> 'summa') :: NUMERIC, 0);
    doc_liik              INTEGER        = doc_data ->> 'liik';
    doc_operid            INTEGER        = doc_data ->> 'operid';
    doc_asutusid          INTEGER        = doc_data ->> 'asutusid';
    doc_lisa              TEXT           = doc_data ->> 'lisa';
    doc_kpv               DATE           = doc_data ->> 'kpv';
    doc_tahtaeg_text      TEXT           = CASE
                                               WHEN (trim(doc_data ->> 'tahtaeg')::TEXT)::TEXT = '' THEN current_date::TEXT
                                               ELSE ((doc_data ->> 'tahtaeg')::TEXT) END;
    doc_tahtaeg           DATE           = doc_tahtaeg_text::DATE;
    doc_kbmta             NUMERIC(14, 4) = coalesce((doc_data ->> 'kbmta') :: NUMERIC, 0);
    doc_kbm               NUMERIC(14, 4) = coalesce((doc_data ->> 'kbm') :: NUMERIC, 0);
    doc_muud              TEXT           = doc_data ->> 'muud';
    doc_objektid          INTEGER        = doc_data ->> 'objektid'; -- считать или не считать (если не пусто) интресс
    doc_objekt            TEXT           = doc_data ->> 'objekt';
    tnDokLausId           INTEGER        = coalesce((doc_data ->> 'doklausid') :: INTEGER, 1);
    doc_lepingId          INTEGER        = doc_data ->> 'leping_id';
    doc_aa                TEXT           = doc_data ->> 'aa'; -- eri arve
    doc_viitenr           TEXT           = doc_data ->> 'viitenr'; -- viite number
    doc_lapsid            INTEGER        = doc_data ->> 'lapsid'; -- kui arve salvestatud lapse modulis
    doc_type              TEXT           = doc_data ->> 'tyyp'; -- ETTEMAKS - если счет на предоплату
    doc_print             JSONB          = coalesce((doc_data ->> 'print')::JSONB, '[]'::JSONB); -- '["paber","email","earve"]'
    doc_ettemaksu_period  INTEGER        = doc_data ->> 'ettemaksu_period'; -- период в месяцах для счета на предоплату или номер периода в доходных
    doc_ettemaksu_arve_id INTEGER        = doc_data ->> 'ettemaksu_arve_id'; -- ссылка на счет предоплатв

    dok_props             JSONB;

    json_object           JSON;
    json_record           RECORD;
    new_history           JSONB;
    new_rights            JSONB;
    ids                   INTEGER[];
    l_json_arve_id        JSONB;
    is_import             BOOLEAN        = data ->> 'import';

    arv1_rea_json         JSONB;
    l_jaak                NUMERIC;

    l_mk_id               INTEGER;
BEGIN

    -- если есть ссылка на ребенка, то присвоим viitenumber
    IF doc_lapsid IS NOT NULL
    THEN
        doc_viitenr = lapsed.get_viitenumber(user_rekvid, doc_lapsid);
    END IF;
    dok_props = (SELECT row_to_json(row)
                 FROM (SELECT doc_aa               AS aa,
                              doc_viitenr          AS viitenr,
                              doc_type             AS tyyp,
                              doc_ettemaksu_period AS ettemaksu_period,
                              doc_print            AS print) row);

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    IF doc_number IS NULL OR doc_number = ''
    THEN
        -- присвоим новый номер
        doc_number = docs.sp_get_number(user_rekvid, 'ARV', YEAR(doc_kpv), tnDokLausId);
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

-- установим срок оплаты, если не задан
    IF doc_tahtaeg IS NULL OR doc_tahtaeg < doc_kpv
    THEN
        doc_tahtaeg = doc_kpv + coalesce((SELECT tahtpaev FROM ou.config WHERE rekvid = user_rekvid LIMIT 1), 14);
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        SELECT row_to_json(row) INTO new_rights
        FROM (SELECT ARRAY [user_id] AS "select",
                     ARRAY [user_id] AS "update",
                     ARRAY [user_id] AS "delete") row;


        INSERT INTO docs.doc (doc_type_id, history, rigths, rekvId)
        VALUES (doc_type_id, '[]' :: JSONB || new_history, new_rights, user_rekvid);
        -- RETURNING id             INTO doc_id;
        SELECT currval('docs.doc_id_seq') INTO doc_id;

        ids = NULL;

        INSERT INTO docs.arv (parentid, rekvid, userid, liik, operid, number, kpv, asutusid, lisa, tahtaeg, kbmta, kbm,
                              summa, muud, objektid, objekt, doklausid, properties)
        VALUES (doc_id, user_rekvid, user_id, doc_liik, doc_operid, doc_number, doc_kpv, doc_asutusid, doc_lisa,
                doc_tahtaeg,
                doc_kbmta, doc_kbm, doc_summa,
                doc_muud, doc_objektid, doc_objekt, tnDokLausId, dok_props) RETURNING id
                   INTO arv_id;

    ELSE
        -- history
        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;


        UPDATE docs.doc
        SET lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history,
            rekvid     = user_rekvid
        WHERE id = doc_id;


        UPDATE docs.arv
        SET liik       = doc_liik,
            operid     = doc_operid,
            number     = doc_number,
            kpv        = doc_kpv,
            asutusid   = doc_asutusid,
            lisa       = doc_lisa,
            tahtaeg    = doc_tahtaeg,
            kbmta      = coalesce(doc_kbmta, 0),
            kbm        = coalesce(doc_kbm, 0),
            summa      = coalesce(doc_summa, 0),
            muud       = doc_muud,
            objektid   = doc_objektid,
            objekt     = doc_objekt,
            doklausid  = tnDokLausId,
            properties = dok_props
        WHERE parentid = doc_id RETURNING id
            INTO arv_id;

    END IF;

    -- вставка в таблицы документа
    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details)
        LOOP
            SELECT * INTO json_record
            FROM json_to_record(
                         json_object) AS x (id TEXT, nomId INTEGER, kogus NUMERIC(14, 4), hind NUMERIC(14, 4),
                                            kbm NUMERIC(14, 4),
                                            kbmta NUMERIC(14, 4),
                                            summa NUMERIC(14, 4), kood TEXT, nimetus TEXT, kood1 TEXT, kood2 TEXT,
                                            kood3 TEXT,
                                            kood4 TEXT, kood5 TEXT,
                                            konto TEXT, tunnus TEXT, tp TEXT, proj TEXT, arve_id INTEGER, muud TEXT,
                                            km TEXT, yksus TEXT, all_yksus TEXT, lapse_taabel_id INTEGER,
                                            soodustus NUMERIC(14, 2));


            SELECT row_to_json(row) INTO arv1_rea_json
            FROM (SELECT json_record.yksus,
                         json_record.all_yksus,
                         json_record.lapse_taabel_id,
                         json_record.soodustus) row;

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN

                INSERT INTO docs.arv1 (parentid, nomid, kogus, hind, kbm, kbmta, summa, kood1, kood2, kood3, kood4,
                                       kood5,
                                       konto, tunnus, tp, proj, muud, kbm_maar, properties, soodus)
                VALUES (arv_id, json_record.nomid,
                        coalesce(json_record.kogus, 1),
                        coalesce(json_record.hind, 0),
                        coalesce(json_record.kbm, 0),
                        coalesce(json_record.kbmta, coalesce(json_record.kogus, 1) * coalesce(json_record.hind, 0)),
                        coalesce(json_record.summa, (coalesce(json_record.kogus, 1) * coalesce(json_record.hind, 0)) +
                                                    coalesce(json_record.kbm, 0)),
                        coalesce(json_record.kood1, ''),
                        coalesce(json_record.kood2, ''),
                        coalesce(json_record.kood3, ''),
                        coalesce(json_record.kood4, ''),
                        coalesce(json_record.kood5, ''),
                        coalesce(json_record.konto, ''),
                        coalesce(json_record.tunnus, ''),
                        coalesce(json_record.tp, ''),
                        coalesce(json_record.proj, ''),
                        coalesce(json_record.muud, ''),
                        coalesce(json_record.km, ''),
                        arv1_rea_json,
                        coalesce(json_record.soodustus::NUMERIC(14, 2), 0)::NUMERIC(14, 2)) RETURNING id
                           INTO arv1_id;

                -- add new id into array of ids
                ids = array_append(ids, arv1_id);

            ELSE
                UPDATE docs.arv1
                SET parentid   = arv_id,
                    nomid      = json_record.nomid,
                    kogus      = coalesce(json_record.kogus, 0),
                    hind       = coalesce(json_record.hind, 0),
                    kbm        = coalesce(json_record.kbm, 0),
                    kbmta      = coalesce(json_record.kbmta, kogus * hind),
                    summa      = coalesce(json_record.summa, (kogus * hind) + kbm),
                    kood1      = coalesce(json_record.kood1, ''),
                    kood2      = coalesce(json_record.kood2, ''),
                    kood3      = coalesce(json_record.kood3, ''),
                    kood4      = coalesce(json_record.kood4, ''),
                    kood5      = coalesce(json_record.kood5, ''),
                    konto      = coalesce(json_record.konto, ''),
                    tunnus     = coalesce(json_record.tunnus, ''),
                    tp         = coalesce(json_record.tp, ''),
                    kbm_maar   = coalesce(json_record.km, ''),
                    muud       = json_record.muud,
                    soodus     = coalesce(json_record.soodustus::NUMERIC(14, 2), 0)::NUMERIC(14, 2),
                    properties = properties || arv1_rea_json
                WHERE id = json_record.id :: INTEGER RETURNING id
                    INTO arv1_id;

                -- add new id into array of ids
                ids = array_append(ids, arv1_id);

            END IF;

            IF (arv1_id IS NOT NULL AND NOT empty(arv1_id) AND json_record.arve_id IS NOT NULL)
            THEN
                -- в параметрах есть ссылки на другие счета
                l_json_arve_id = (SELECT row_to_json(row) FROM (SELECT json_record.arve_id AS arve_id) row)::JSONB;
                UPDATE docs.arv1
                SET properties = coalesce(properties::JSONB, '{}'::JSONB)::JSONB || l_json_arve_id
                WHERE id = arv1_id;

                -- установим связь со счетом , на который выписан интрес
                UPDATE docs.doc
                SET docs_ids = array_append(docs_ids, doc_id)
                WHERE id = json_record.arve_id;

            END IF;

            -- есои задан параметр json_record.lapse_kaart_id то устанавливаем статус табеля = 2 (закрыт)
            IF json_record.lapse_taabel_id IS NOT NULL
            THEN
                UPDATE lapsed.lapse_taabel SET staatus = 2 WHERE id = json_record.lapse_taabel_id;
            END IF;


        END LOOP;

    -- delete record which not in json
    IF array_length(ids, 1) > 0
    THEN
        -- проверить на наличие ссылок на другие счета и снять ссылку
        IF exists(
                SELECT d.id
                FROM docs.doc d
                WHERE d.id IN (
                    SELECT (properties ->> 'arve_id')::INTEGER
                    FROM docs.arv1 a1
                    WHERE a1.parentid = arv_id
                      AND a1.id NOT IN (SELECT unnest(ids))))
        THEN
            -- есть ссылка, надо снять
            UPDATE docs.doc
            SET docs_ids = array_remove(docs_ids, doc_id)
            WHERE id IN (
                SELECT (a1.properties ->> 'arve_id')::INTEGER
                FROM docs.arv1 a1
                         INNER JOIN docs.arv a ON a.id = a1.parentid
                WHERE a.parentid = doc_id
                  AND a1.id NOT IN (SELECT unnest(ids)));
        END IF;

        DELETE
        FROM docs.arv1
        WHERE parentid = arv_id
          AND id NOT IN (SELECT unnest(ids));
    END IF;
    -- update arv summad
    SELECT sum(summa) AS summa,
           sum(kbm)   AS kbm
           INTO doc_summa, doc_kbm
    FROM docs.arv1
    WHERE parentid = arv_id;

    UPDATE docs.arv
    SET kbmta = coalesce(doc_summa, 0) - coalesce(doc_kbm, 0),
        kbm   = coalesce(doc_kbm, 0),
        summa = coalesce(doc_summa, 0)
    WHERE parentid = doc_id;

    IF doc_lepingId IS NOT NULL
    THEN
        -- will add reference to leping
        UPDATE docs.doc
        SET docs_ids = array_append(docs_ids, doc_lepingId)
        WHERE id = doc_id;

        -- will add ref.id to leping
        UPDATE docs.doc
        SET docs_ids = array_append(docs_ids, doc_id)
        WHERE id = doc_lepingId;

    END IF;

    IF (doc_ettemaksu_arve_id IS NOT NULL)
    THEN
        -- will add reference to ettemaksu arve
        UPDATE docs.doc
        SET docs_ids = array_append(docs_ids, doc_ettemaksu_arve_id)
        WHERE id = doc_id;

        UPDATE docs.doc
        SET docs_ids = array_append(docs_ids, doc_id)
        WHERE id = doc_ettemaksu_arve_id;


    END IF;

    -- lapse module

    IF doc_lapsid IS NOT NULL
    THEN
        IF NOT exists(SELECT id FROM lapsed.liidestamine WHERE parentid = doc_lapsid AND docid = doc_id)
        THEN
            raise notice 'insert doc_lapsid %, doc_id %', doc_lapsid, doc_id;
            INSERT INTO lapsed.liidestamine (parentid, docid) VALUES (doc_lapsid, doc_id);
        END IF;

    END IF;

    l_jaak = (SELECT jaak FROM docs.arv WHERE parentid = doc_id);
    IF doc_id IS NOT NULL AND doc_id > 0 AND l_jaak > 0
    THEN
        -- проверить на наличие предоплат
        PERFORM docs.check_ettemaks(doc_id, user_id);
    END IF;

    -- если это доходный счет, созданный на основе предоплатного
    IF doc_ettemaksu_arve_id IS NULL AND doc_ettemaksu_period IS NOT NULL
    THEN
        doc_ettemaksu_arve_id = (SELECT d.id
                                 FROM docs.doc d
                                          INNER JOIN docs.arv a ON d.id = a.parentid
                                 WHERE d.id IN (
                                     SELECT unnest((SELECT d.docs_ids
                                                    FROM docs.arv a
                                                             INNER JOIN docs.doc d ON d.id = a.parentid
                                                    WHERE parentid = doc_id)))
                                   AND a.properties ->> 'tyyp' IS NOT NULL
                                   AND a.properties ->> 'tyyp' = 'ETTEMAKS'
                                 LIMIT 1
        );

    END IF;

    RAISE NOTICE 'doc_ettemaksu_arve_id %', doc_ettemaksu_arve_id;
    IF doc_ettemaksu_arve_id IS NOT NULL
    THEN
        -- проверим оплату счета
        IF exists(SELECT id FROM docs.arv WHERE parentid = doc_ettemaksu_arve_id
            --                                AND coalesce(jaak, summa) > 0
            )
        THEN
            -- вызываем оплату

            l_mk_id = (SELECT doc_tasu_id FROM docs.arvtasu WHERE doc_arv_id = doc_ettemaksu_arve_id);
            RAISE NOTICE 'call  sp_tasu_arv l_mk_id %', l_mk_id;
            PERFORM docs.sp_tasu_arv(l_mk_id, doc_ettemaksu_arve_id, user_id);

        END IF;
    END IF;

    PERFORM docs.sp_update_arv_jaak(doc_id);

    RETURN doc_id;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(JSON, INTEGER, INTEGER) TO ladukasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
select docs.sp_salvesta_arv('{"id":1898296,"data": {"aa":"EE681010220037906015","aadress":"Ida-Viru maakond, Narva linn, Kalda tn 9, 20104","arvid":0,"asutus":"OÜ DATEL VIRU","asutusid":30224,"bpm":"{\"omniva\": [{\"kpv\": \"22.05.2020 14:11:48\", \"isik\": \"47608105226|Jelena Golubeva|VERIFIED|\", \"rolli\": \"Kinnitaja\"}, {\"kpv\": \"25.05.2020 09:44:02\", \"isik\": \"46610172217|Jelena TÅ¡ekanina|VERIFIED|\", \"rolli\": \"Kinnitaja\"}, {\"kpv\": \"\", \"isik\": \"48612183747|A","created":"26.05.2020 09:05:15","doc":"Arved","doc_status":1,"doc_type_id":"ARV","doklausid":1625,"dokprop":"arve","id":1898296,"is_show_journal":1,"jaak":5781,"journalid":1898297,"kbm":0,"kbmkonto":"601000","kbmta":5781,"kmkr":"","konto":"201000","koostaja":"jelena.tsekanina","kpv":"20200522","lastupdate":"02.06.2020 08:06:45","laus_nr":1350,"liik":1,"lisa":"","muud":"","number":"39","objekt":"","objektid":0,"operid":0,"regkood":"11047855","rekvid":63,"status":"Aktiivne","summa":5781,"tahtaeg":"20200605","tasud":null,"tasudok":null,"userid":2477,"viitenr":"12345","gridData":[{"formula":null,"hind":5781,"id":181643,"kbm":0,"kbmta":5781,"km":"0","kogus":1,"konto":"551485","kood":"OMNIVA","kood1":"01112","kood2":"LE-P","kood3":"","kood4":"","kood5":"5514","kuurs":1,"muud":"Tarkvara arendamine","nimetus":"Importeeritud e-arvete registrist teenused","nomid":17748,"proj":"OSAK","soodus":0,"summa":5781,"tp":"800599","tunnus":"OSAK","uhik":"","userid":2477,"valuuta":"EUR","vastisik":null}]}}'::json,
957::integer,
64::integer) as id;


select * from docs.arv where parentid = 1616296
select * from docs.arv1 where parentid = 331

"gridData":[{"formula":"","hind":0,"id":0,"kbm":0,"kbmta":0,"km":"","kogus":0,"konto":"","kood":"","kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","kuurs":0,"nimetus":"","nomid":0,"proj":"","soodus":0,"summa":0,"tp":"","tunnus":"","userid":0,"valuuta":"","vastisik":""}]
*/
