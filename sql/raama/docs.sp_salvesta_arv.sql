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
    doc_type              TEXT           = doc_data ->> 'tyyp'; -- ETTEMAKS - если счет на предоплату, hooldekodu
    doc_print             JSONB          = coalesce((doc_data ->> 'print')::JSONB, '[]'::JSONB); -- '["paber","email","earve"]'
    doc_ettemaksu_period  INTEGER        = doc_data ->> 'ettemaksu_period'; -- период в месяцах для счета на предоплату или номер периода в доходных
    doc_ettemaksu_arve_id INTEGER        = doc_data ->> 'ettemaksu_arve_id'; -- ссылка на счет предоплатв

-- Hooldekodu
    doc_isik_id           INTEGER        = doc_data ->> 'isik_id'; -- kui arve salvestatud hooldekodu modulist

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
    l_km                  TEXT;
    l_mks                 RECORD;
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
                              doc_isik_id          AS isik_id,
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

-- установим срок оплаты, если не задан
    IF doc_tahtaeg IS NULL OR doc_tahtaeg < doc_kpv
    THEN
        doc_tahtaeg = doc_kpv + coalesce((SELECT tahtpaev FROM ou.config WHERE rekvid = user_rekvid LIMIT 1), 14);
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        SELECT row_to_json(row)
        INTO new_rights
        FROM (SELECT ARRAY [user_id] AS "select",
                     ARRAY [user_id] AS "update",
                     ARRAY [user_id] AS "delete") row;

        IF doc_lepingId IS NOT NULL
        THEN
            -- will add reference to leping
            ids = array_append(ids, doc_lepingId);
        END IF;

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
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;


        UPDATE docs.doc
        SET lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history,
            rekvid     = user_rekvid
        WHERE id = doc_id;

        IF doc_lepingId IS NOT NULL
        THEN
            -- will add reference to leping
            UPDATE docs.doc
            SET docs_ids = array_append(docs_ids, doc_lepingId)
            WHERE id = doc_id;
        END IF;

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
            properties = properties::JSONB || dok_props::JSONB
        WHERE parentid = doc_id RETURNING id
            INTO arv_id;

    END IF;

    -- вставка в таблицы документа
    FOR json_object IN
        SELECT *
        FROM json_array_elements(doc_details)
        LOOP
            SELECT *
            INTO json_record
            FROM json_to_record(
                         json_object) AS x (id TEXT, nomId INTEGER, kogus NUMERIC(14, 4), hind NUMERIC(14, 4),
                                            kbm NUMERIC(14, 4),
                                            kbmta NUMERIC(14, 4),
                                            summa NUMERIC(14, 4), kood TEXT, nimetus TEXT, kood1 TEXT, kood2 TEXT,
                                            kood3 TEXT,
                                            kood4 TEXT, kood5 TEXT,
                                            konto TEXT, tunnus TEXT, tp TEXT, proj TEXT, arve_id INTEGER, muud TEXT,
                                            km TEXT, yksus TEXT, all_yksus TEXT, lapse_taabel_id INTEGER,
                                            soodustus NUMERIC(14, 4), soodus NUMERIC(14, 4), allikas_85 NUMERIC(12, 2),
                                            allikas_vara NUMERIC(12, 2), allikas_muud NUMERIC(12, 2),
                                            umardamine NUMERIC(12, 2), sugulane_osa NUMERIC(12, 2),
                                            omavalitsuse_osa NUMERIC(12, 2));


            SELECT row_to_json(row)
            INTO arv1_rea_json
            FROM (SELECT json_record.yksus,
                         json_record.all_yksus,
                         json_record.lapse_taabel_id,
                         CASE
                             WHEN json_record.soodustus IS NULL OR empty(json_record.soodustus)
                                 THEN coalesce(json_record.soodus, 0)
                             ELSE json_record.soodustus END        AS soodustus,
                         coalesce(json_record.allikas_85, 0)       AS allikas_85,
                         coalesce(json_record.allikas_vara, 0)     AS allikas_vara,
                         coalesce(json_record.allikas_muud, 0)     AS allikas_muud,
                         coalesce(json_record.umardamine, 0)       AS umardamine,
                         coalesce(json_record.sugulane_osa, 0)     AS sugulane_osa,
                         coalesce(json_record.omavalitsuse_osa, 0) AS omavalitsuse_osa
                 ) row;

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN
                IF empty(coalesce(json_record.km, ''))
                THEN
                    json_record.kbm = 0;
                END IF;

                IF coalesce(json_record.km, '') NOT IN ('0', '5', '10', '20')
                THEN
                    json_record.km = '0';
                END IF;

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
                        CASE
                            WHEN json_record.soodustus IS NULL OR empty(json_record.soodustus)
                                THEN coalesce(json_record.soodus, 0)
                            ELSE json_record.soodustus END ::NUMERIC(14, 4)) RETURNING id
                           INTO arv1_id;

                -- add new id into array of ids
                ids = array_append(ids, arv1_id);

            ELSE
                IF coalesce(json_record.km, '') NOT IN ('0', '5', '10', '20')
                THEN
                    json_record.km = '0';
                END IF;

                IF empty(coalesce(json_record.km, ''))
                THEN
                    json_record.kbm = 0;
                END IF;

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
                    proj       = coalesce(json_record.proj, ''),
                    kbm_maar   = coalesce(json_record.km, ''),
                    muud       = json_record.muud,
                    soodus     = CASE
                                     WHEN json_record.soodustus IS NULL OR empty(json_record.soodustus)
                                         THEN coalesce(json_record.soodus, 0)
                                     ELSE json_record.soodustus END::NUMERIC(14, 4),
                    properties = coalesce(properties, '{}'::JSONB) || arv1_rea_json
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
            INSERT INTO lapsed.liidestamine (parentid, docid) VALUES (doc_lapsid, doc_id);
        END IF;

    END IF;

    -- расчет сальдо счета
    l_jaak = docs.sp_update_arv_jaak(doc_id);

    IF doc_id IS NOT NULL AND doc_id > 0 AND l_jaak > 0
    THEN
        -- проверить на наличие предоплат
--        PERFORM docs.check_ettemaks(doc_id, user_id);
        PERFORM docs.sp_loe_arv(doc_id, user_id);
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

    IF doc_ettemaksu_arve_id IS NOT NULL
    THEN
        -- проверим оплату счета
        IF exists(SELECT id FROM docs.arv WHERE parentid = doc_ettemaksu_arve_id
            --                                AND coalesce(jaak, summa) > 0
            )
        THEN
            -- вызываем оплату
            FOR l_mks IN SELECT doc_tasu_id AS mk_id FROM docs.arvtasu WHERE doc_arv_id = doc_ettemaksu_arve_id
                LOOP
                    PERFORM docs.sp_tasu_arv(l_mks.mk_id, doc_ettemaksu_arve_id, user_id);

                END LOOP;

        END IF;
    END IF;

--    PERFORM docs.sp_update_arv_jaak(doc_id);

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
SELECT docs.sp_salvesta_arv('{
  "id": 0,
  "data": {
    "kbm": 0.0000,
    "kpv": "2022-12-19",
    "jaak": 0.0000,
    "liik": 0,
    "lisa": "Perioodi eest 01-31.12.22.a (tekkepohised tulud on kajastatud 12.2022)                                                  ",
    "muud": null,
    "arvid": 0,
    "kbmta": 866.8400,
    "summa": 866.8400,
    "tasud": "2023-01-03",
    "number": "2022361             ",
    "objekt": null,
    "operid": null,
    "rekvid": 119,
    "userid": 8932,
    "tahtaeg": "2022-12-19",
    "tasudok": null,
    "asutusid": 23720,
    "objektid": 0,
    "doklausid": 1570,
    "properties": {
      "aa": "EE652200221027849230",
      "tyyp": "",
      "print": [],
      "viitenr": "8600017",
      "ettemaksu_period": null
    },
    "gridData": [
      {
        "id": 0,
        "tp": "240101",
        "kbm": 0.0000,
        "hind": 433.4200,
        "maha": 0,
        "muud": "",
        "proj": "",
        "kbmta": 866.8400,
        "kogus": 2.000,
        "konto": "322020",
        "kood1": "09110",
        "kood2": "80",
        "kood3": "",
        "kood4": "",
        "kood5": "3220",
        "nomid": 17235,
        "summa": 866.8400,
        "isikid": 0,
        "soodus": 0.0000,
        "tunnus": "0911064",
        "tahtaeg": null,
        "kbm_maar": "0",
        "properties": {
          "yksus": null,
          "all_yksus": null,
          "soodustus": 0.0000,
          "lapse_taabel_id": null
        }
      }
    ]
  }
}'::JSON,
                            5435::INTEGER,
                            119::INTEGER) AS id;



SELECT *
FROM ou.rekv
WHERE id = 125

SELECT *
FROM ou.userid
WHERE rekvid = 119
  AND kasutaja = 'vlad'

*/