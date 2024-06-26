-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_salvesta_mk(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_mk(data JSON,
                                               user_id INTEGER,
                                               user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    mk_id             INTEGER;
    mk1_id            INTEGER;
    userName          TEXT;
    doc_id            INTEGER = data ->> 'id';
    doc_data          JSON    = data ->> 'data';
    doc_details       JSON    = doc_data ->> 'gridData';
    doc_opt           TEXT    = coalesce((doc_data ->> 'opt'), '1'); -- 2 -> smk, 1 -> vmk
    doc_type_kood     TEXT    = coalesce((doc_data ->> 'doc_type_id'), CASE
                                                                           WHEN doc_opt = '2'
                                                                               THEN 'SMK'
                                                                           ELSE 'VMK' END);
    doc_typeId        INTEGER = (SELECT id
                                 FROM libs.library
                                 WHERE ltrim(rtrim(kood)) = ltrim(rtrim(upper(doc_type_kood)))
                                   AND library = 'DOK'
                                 LIMIT 1);
    doc_number        TEXT    = doc_data ->> 'number';
    doc_kpv           DATE    = coalesce((doc_data ->> 'kpv')::DATE, current_date);
    doc_aa_id         INTEGER = coalesce((doc_data ->> 'aa_id')::INTEGER, (doc_data ->> 'aaid')::INTEGER);
    doc_arvid         INTEGER = doc_data ->> 'arvid';
    doc_muud          TEXT    = doc_data ->> 'muud';
    doc_doklausid     INTEGER = doc_data ->> 'doklausid';
    doc_maksepaev     DATE    = coalesce((doc_data ->> 'maksepaev')::DATE, current_date);
    doc_selg          TEXT    = doc_data ->> 'selg';
    doc_viitenr       TEXT    = doc_data ->> 'viitenr';
    doc_lapsid        INTEGER = doc_data ->> 'lapsid'; -- kui arve salvestatud lapse modulis
    doc_dok_id        INTEGER = doc_data ->> 'dokid'; -- kui mk salvestatud avansiaruanne alusel
    doc_kasusaaja_id  INTEGER = doc_data ->> 'kasusaaja_id'; -- дл модуля Hooldekodu
    doc_tyyp        TEXT = doc_data ->> 'tehingu_tyyp'; -- если перенос сальдо из детского модуля
    doc_kreedit_makse INTEGER = doc_data ->> 'doc_kreedit_makse'; -- если перенос сальдо то ссылка на первый документ

    json_object       JSON;
    json_record       RECORD;
    json_properties   JSONB   = '{}'::JSONB;
    new_history       JSONB;
    ids               INTEGER[];
    docs              INTEGER[];
    is_import         BOOLEAN = data ->> 'import';
    l_jaak            NUMERIC = 0; -- tasu jääk

    l_vana_tasu_summa NUMERIC = 0; -- vana tasu summa
    l_uus_tasu_summa  NUMERIC = 0; -- uus tasu summa
    kas_muudatus      BOOLEAN = FALSE; -- если апдейт, то тру
    v_arvtasu         RECORD;
    l_yksus           TEXT; -- код группы
    v_nom             RECORD;
BEGIN

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;
    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF NOT ou.fnc_aasta_kontrol(user_rekvid, doc_kpv)
    THEN
        RAISE EXCEPTION 'Viga, Period on kinni, doc_kpv %, doc_viitenr %, doc_lapsid %, doc_selg %', doc_kpv, doc_viitenr, doc_lapsid, doc_selg;
    END IF;
    

    IF doc_muud = 'Oppetasu algsaldo 2023' AND doc_kpv = '2022-12-31' AND user_id NOT IN (
        SELECT id
        FROM ou.userid
        WHERE kasutaja IN ('temp', 'vlad')
    )
    THEN

        RAISE NOTICE 'Vale kasutaja %', user;
        RETURN 0;

    END IF;


    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    IF doc_number IS NULL OR doc_number = ''
    THEN
        -- присвоим новый номер
        doc_number = docs.sp_get_number(user_rekvid, doc_type_kood, YEAR(doc_kpv), doc_doklausid);
    END IF;

-- проверим расч. счет
    IF doc_aa_id IS NULL OR NOT exists(SELECT id
                                       FROM ou.aa
                                       WHERE parentId = user_rekvid
                                         AND kassa = 1
                                         AND id = doc_aa_id
                                       ORDER BY default_ DESC)
    THEN
        SELECT id
        INTO doc_aa_id
        FROM ou.aa
        WHERE parentId = user_rekvid
          AND kassa = 1
        ORDER BY default_ DESC
        LIMIT 1;
        IF NOT found
        THEN
            RAISE NOTICE 'pank not found %', doc_aa_id;
            RETURN 0;
        END IF;
    END IF;

    IF coalesce(doc_doklausid, 0) = 0
    THEN
        -- не задан профиль, укажем принудительно
        doc_doklausid = (SELECT ID
                         FROM libs.dokprop
                         WHERE parentid IN
                               (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN (doc_type_kood))
                           AND rekvid = user_rekvid
                         ORDER BY registr DESC, id DESC
                         LIMIT 1);
    END IF;

    -- для модуля Hooldekodu укажем бенефициара платежа, если получателем денег является отличное от их владельца лицо
    IF (doc_kasusaaja_id IS NOT NULL AND NOT empty(doc_kasusaaja_id))
    THEN
        json_properties = jsonb_build_object('kasusaaja_id', doc_kasusaaja_id);
    END IF;

    -- для модуля lapsed укажем тип операции, для последующей контировки с коррекцией корр.счетов
    IF (doc_tyyp IS NOT NULL AND NOT empty(doc_tyyp))
    THEN
        json_properties = jsonb_build_object('tehingu_tyyp', doc_tyyp, 'doc_kreedit_makse',doc_kreedit_makse);
    END IF;

    -- вставка или апдейт docs.doc

    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;


        INSERT INTO docs.doc (doc_type_id, history, rekvid, status)
        VALUES (doc_typeId, '[]' :: JSONB || new_history, user_rekvid, 1);
        --RETURNING id             INTO doc_id;
        SELECT currval('docs.doc_id_seq') INTO doc_id;

        INSERT INTO docs.mk (parentid, rekvid, kpv, opt, aaId, number, muud, arvid, doklausid, maksepaev, selg, viitenr,
                             dokid, properties)
        VALUES (doc_id, user_rekvid, doc_kpv, doc_opt :: INTEGER, doc_aa_id, left(doc_number, 20), doc_muud,
                coalesce(doc_arvid, 0),
                coalesce(doc_doklausid, 0), coalesce(doc_maksepaev, doc_kpv), coalesce(doc_selg, ''),
                coalesce(doc_viitenr, ''), coalesce(doc_dok_id, 0), json_properties) RETURNING id
                   INTO mk_id;

    ELSE
        kas_muudatus = TRUE;
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        -- устанавливаем связи с документами

        -- получим связи документа
        SELECT docs_ids
        INTO docs
        FROM docs.doc
        WHERE id = doc_id;

        IF doc_arvid IS NOT NULL
        THEN
            docs = array_append(docs, doc_arvid);
        END IF;

        UPDATE docs.doc
        SET doc_type_id = doc_typeId,
            docs_ids    = docs,
            lastupdate  = now(),
            history     = coalesce(history, '[]') :: JSONB || new_history
        WHERE id = doc_id;

        UPDATE docs.mk
        SET kpv        = doc_kpv,
            aaid       = doc_aa_id,
            number     = left(doc_number, 20),
            muud       = doc_muud,
            arvid      = coalesce(doc_arvid, 0),
            doklausid  = coalesce(doc_doklausid, 0),
            maksepaev  = coalesce(doc_maksepaev, doc_kpv),
            selg       = coalesce(doc_selg, ''),
            viitenr    = coalesce(doc_viitenr, ''),
            dokid      = coalesce(doc_dok_id, 0),
            properties = coalesce(properties, '{}'::JSONB) || coalesce(json_properties, '{}'::JSONB)
        WHERE parentid = doc_id RETURNING id
            INTO mk_id;

        -- если есть оплата счетов и меняется дата, правим
        UPDATE docs.arvtasu SET kpv = doc_kpv WHERE doc_tasu_id = doc_id;


        -- кешируем старую сумму оплаты
        SELECT sum(summa) INTO l_vana_tasu_summa FROM docs.mk1 WHERE parentid = mk_id;


    END IF;
    -- вставка в таблицы документа

    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details)
        LOOP
            SELECT *
            INTO json_record
            FROM json_to_record(
                         json_object) AS x(id TEXT, asutusid INTEGER, nomid INTEGER, summa NUMERIC(14, 4), aa TEXT,
                                           pank TEXT,
                                           tunnus TEXT, proj TEXT, konto TEXT, kood1 TEXT, kood2 TEXT, kood3 TEXT,
                                           kood4 TEXT, kood5 TEXT, tp TEXT, valuuta TEXT, kuurs NUMERIC(14, 8),
                                           journalid INTEGER);

            SELECT properties ->> 'tegev'    AS tegev,
                   properties ->> 'artikkel' AS artikkel,
                   properties ->> 'allikas'  AS allikas,
                   *
            INTO v_nom
            FROM libs.nomenklatuur
            WHERE id = json_record.nomid
            LIMIT 1;


            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW' OR
               NOT exists(SELECT id
                          FROM docs.mk1
                          WHERE id = json_record.id :: INTEGER)
            THEN

                INSERT INTO docs.mk1 (parentid, asutusid, nomid, summa, aa, pank, tunnus, proj, konto,
                                      kood1, kood2, kood3, kood4, kood5, tp, journalid)
                VALUES (mk_id, json_record.asutusid, json_record.nomid, json_record.summa, json_record.aa,
                        json_record.pank,
                        json_record.tunnus, json_record.proj, json_record.konto,
                        coalesce(json_record.kood1, v_nom.tegev), coalesce(json_record.kood2, v_nom.allikas),
                        json_record.kood3, json_record.kood4,
                        coalesce(json_record.kood5, v_nom.artikkel),
                        json_record.tp, json_record.journalid) RETURNING id
                           INTO mk1_id;

                -- add new id into array of ids
                ids = array_append(ids, mk1_id);

            ELSE

                UPDATE docs.mk1
                SET nomid    = json_record.nomid,
                    asutusid = json_record.asutusid,
                    summa    = json_record.summa,
                    aa       = json_record.aa,
                    pank     = json_record.pank,
                    konto    = json_record.konto,
                    tunnus   = json_record.tunnus,
                    proj     = json_record.proj,
                    kood1    = coalesce(json_record.kood1, v_nom.tegev),
                    kood2    = coalesce(json_record.kood2, v_nom.allikas),
                    kood3    = json_record.kood3,
                    kood4    = json_record.kood4,
                    kood5    = coalesce(json_record.kood5, v_nom.artikkel),
                    tp       = json_record.tp
                WHERE id = json_record.id :: INTEGER;

                mk1_id = json_record.id :: INTEGER;

                -- add existing id into array of ids
                ids = array_append(ids, mk1_id);

            END IF;

            -- delete record which not in json

            DELETE
            FROM docs.mk1
            WHERE parentid = mk_id
              AND id NOT IN (SELECT unnest(ids));

            l_uus_tasu_summa = l_uus_tasu_summa + json_record.summa;

        END LOOP;

    -- правим сумму оплаты
    IF (kas_muudatus)
    THEN

        IF l_uus_tasu_summa <> l_vana_tasu_summa
        THEN
            -- кешируем старую сумму оплаты
            SELECT *
            INTO v_arvtasu
            FROM docs.arvtasu
            WHERE doc_tasu_id = doc_id
              AND status <> 3
            ORDER BY summa DESC
            LIMIT 1;
            -- если сумма оплаты уменьшилась
            IF l_uus_tasu_summa < l_vana_tasu_summa AND v_arvtasu.summa > l_uus_tasu_summa
            THEN
                -- просто меняем сумму оплаты
                UPDATE docs.arvtasu SET summa = l_uus_tasu_summa WHERE id = v_arvtasu.id;
            ELSE
                -- удаляем оплату и распределяем счета по новой
                PERFORM docs.sp_delete_arvtasu(
                                user_id,
                                v_arvtasu.id);
            END IF;
        END IF;

    END IF;

    -- сальдо платежа
    l_jaak = docs.sp_update_mk_jaak(doc_id);

    IF doc_arvid IS NOT NULL AND doc_arvid > 0 AND l_jaak > 0
    THEN

        -- произведем оплату счета
        PERFORM docs.sp_tasu_arv(doc_id, doc_arvid, user_id);
    END IF;

    -- lapse module
    IF doc_viitenr IS NOT NULL AND char_length(doc_viitenr) > 0 AND (doc_lapsid IS NULL OR doc_lapsid = 0)
    THEN
        -- попробуем найти ребенка по ссылке
        doc_lapsid = lapsed.get_laps_from_viitenumber(doc_viitenr);
    END IF;

    IF doc_lapsid IS NOT NULL AND doc_lapsid > 0
    THEN

        IF NOT exists(SELECT id FROM lapsed.liidestamine WHERE parentid = doc_lapsid AND docid = doc_id)
        THEN
            INSERT INTO lapsed.liidestamine (parentid, docid) VALUES (doc_lapsid, doc_id);
        END IF;

        -- проверим на учреждение
        IF NOT exists(SELECT id FROM lapsed.lapse_kaart WHERE parentid = doc_lapsid AND rekvid = user_rekvid)
        THEN
            -- чужой, удаляем связь (Kalle 17.01.2023)
            DELETE FROM lapsed.liidestamine WHERE docid = doc_id AND parentid = doc_lapsid;
        END IF;

        -- присвоим платежу код группы по услугам
        IF (SELECT properties ->> 'yksus'
            FROM docs.mk
            WHERE parentid = doc_id
        ) IS NULL
        THEN
            l_yksus = (SELECT properties ->> 'yksus'
                       FROM lapsed.lapse_kaart
                       WHERE parentid = doc_lapsid
                         AND rekvid = user_rekvid
                         AND staatus < 3
                       ORDER BY (properties ->> 'lopp_kpv')::DATE DESC
                       LIMIT 1);

            UPDATE docs.mk
            SET properties = coalesce(properties, '{}'::JSONB) || jsonb_build_object('yksus', l_yksus)
            WHERE parentid = doc_id;

        END IF;

    END IF;

    IF l_jaak > 0 AND doc_opt::INTEGER = 2 -- smk
    THEN
        -- произведем поиск и оплату счета
        PERFORM docs.sp_loe_tasu(doc_id, user_id);
    END IF;


    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_mk(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_mk(JSON, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_mk(JSON, INTEGER, INTEGER) TO arvestaja;

/*
SELECT docs.sp_salvesta_mk('{
  "id": 928,
  "data": {
    "aaid": 2,
    "arvid": 5,
    "arvnr": null,
    "bpm": null,
    "created": "15.02.2018 03:02:41",
    "doc": null,
    "docs_ids": null,
    "doc_type_id": null,
    "doklausid": 0,
    "dokprop": null,
    "id": 928,
    "konto": null,
    "kpv": "20180215",
    "lastupdate": "15.02.2018 03:02:41",
    "maksepaev": "20180215",
    "muud": "",
    "number": "001",
    "opt": 1,
    "pank": null,
    "rekvid": 1,
    "selg": "",
    "status": "????????",
    "summa": 0,
    "viitenr": "123455",
    "gridData": [
      {
        "aa": "",
        "asutus": "Asutus",
        "asutusid": 2,
        "id": 150,
        "id1": 150,
        "journalid": null,
        "konto": "111",
        "kood": "pank",
        "kood1": "",
        "kood2": "",
        "kood3": "",
        "kood4": "",
        "kood5": "",
        "kuurs": 1,
        "nimetus": "Raha arvele",
        "nomid": 5,
        "pank": "",
        "parentid": 163,
        "proj": "test",
        "summa": 0,
        "tp": "",
        "tunnus": "1343205",
        "userid": 1,
        "valuuta": "EUR"
      }
    ]
  }
}', 1, 1);

*/