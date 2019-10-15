DROP FUNCTION IF EXISTS docs.sp_salvesta_arv(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_arv(data JSON,
                                                userid INTEGER,
                                                user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    arv_id         INTEGER;
    arv1_id        INTEGER;
    userName       TEXT;
    doc_id         INTEGER        = data ->> 'id';
    doc_data       JSON           = data ->> 'data';
    doc_type_kood  TEXT           = 'ARV'/*data->>'doc_type_id'*/;
    doc_type_id    INTEGER        = (SELECT id
                                     FROM libs.library
                                     WHERE kood = doc_type_kood
                                       AND library = 'DOK'
                                     LIMIT 1);

    doc_details    JSON           = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');
    doc_number     TEXT           = doc_data ->> 'number';
    doc_summa      NUMERIC(14, 4) = coalesce((doc_data ->> 'summa') :: NUMERIC, 0);
    doc_liik       INTEGER        = doc_data ->> 'liik';
    doc_operid     INTEGER        = doc_data ->> 'operid';
    doc_asutusid   INTEGER        = doc_data ->> 'asutusid';
    doc_lisa       TEXT           = doc_data ->> 'lisa';
    doc_kpv        DATE           = doc_data ->> 'kpv';
    doc_tahtaeg    DATE           = doc_data ->> 'tahtaeg';
    doc_kbmta      NUMERIC(14, 4) = coalesce((doc_data ->> 'kbmta') :: NUMERIC, 0);
    doc_kbm        NUMERIC(14, 4) = coalesce((doc_data ->> 'kbm') :: NUMERIC, 0);
    doc_muud       TEXT           = doc_data ->> 'muud';
    doc_objektid   INTEGER        = doc_data ->> 'objektid'; -- считать или не считать (если не пусто) интресс
    doc_objekt     TEXT           = doc_data ->> 'objekt';
    tnDokLausId    INTEGER        = coalesce((doc_data ->> 'doklausid') :: INTEGER, 1);
    doc_lepingId   INTEGER        = doc_data ->> 'leping_id';
    doc_aa         TEXT           = doc_data ->> 'aa'; -- eri arve
    doc_viitenr    TEXT           = doc_data ->> 'viitenr'; -- viite number
    doc_lapsid     INTEGER        = doc_data ->> 'lapsid'; -- kui arve salvestatud lapse modulis
    dok_props      JSONB          = (SELECT row_to_json(row)
                                     FROM (SELECT doc_aa AS aa, doc_viitenr AS viitenr) row);
    json_object    JSON;
    json_record    RECORD;
    new_history    JSONB;
    new_rights     JSONB;
    ids            INTEGER[];
    l_json_arve_id JSONB;
    is_import      BOOLEAN        = data ->> 'import';

    arv1_rea_json  JSONB;
BEGIN

    -- если есть ссылка на ребенка, то присвоим viitenumber
    IF doc_lapsid IS NOT NULL
    THEN
        doc_viitenr = lapsed.get_viitenumber(user_rekvid, doc_lapsid);
    END IF;

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
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    -- проверка на номер
/*
  SELECT row_to_json(row)
         INTO json_object
  FROM (SELECT
          doc_liik      AS tyyp,
          doc_number    AS number,
          year(doc_kpv) AS aasta,
          doc_asutusid  AS asutus) row;
  IF NOT docs.check_arv_number(user_rekvid::INTEGER, json_object::JSON)::BOOLEAN
  THEN
    RAISE NOTICE 'Number not valid';
    RETURN 0;
  END IF;
*/

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        SELECT row_to_json(row) INTO new_rights
        FROM (SELECT ARRAY [userId] AS "select",
                     ARRAY [userId] AS "update",
                     ARRAY [userId] AS "delete") row;

        IF doc_lepingId IS NOT NULL
        THEN
            -- will add reference to leping
            ids = array_append(ids, doc_lepingId);
        END IF;

        INSERT INTO docs.doc (doc_type_id, history, rigths, rekvId, docs_ids)
        VALUES (doc_type_id, '[]' :: JSONB || new_history, new_rights, user_rekvid, ids) RETURNING id
            INTO doc_id;

        ids = NULL;

        INSERT INTO docs.arv (parentid, rekvid, userid, liik, operid, number, kpv, asutusid, lisa, tahtaeg, kbmta, kbm,
                              summa, muud, objektid, objekt, doklausid, properties)
        VALUES (doc_id, user_rekvid, userId, doc_liik, doc_operid, doc_number, doc_kpv, doc_asutusid, doc_lisa,
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
                                            km TEXT, yksus TEXT, all_yksus TEXT, lapse_taabel_id INTEGER);


            SELECT row_to_json(row) INTO arv1_rea_json
            FROM (SELECT json_record.yksus, json_record.all_yksus, json_record.lapse_taabel_id) row;

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN

                INSERT INTO docs.arv1 (parentid, nomid, kogus, hind, kbm, kbmta, summa, kood1, kood2, kood3, kood4,
                                       kood5,
                                       konto, tunnus, tp, proj, muud, kbm_maar, properties)
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
                        arv1_rea_json) RETURNING id
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

    PERFORM docs.sp_update_arv_jaak(doc_id);

    IF doc_lepingId IS NOT NULL
    THEN
        -- will add ref.id to leping
        UPDATE docs.doc
        SET docs_ids = array_append(docs_ids, doc_id)
        WHERE id = doc_lepingId;
    END IF;

    -- lapse module

    IF doc_lapsid IS NOT NULL
    THEN
        IF NOT exists(SELECT id FROM lapsed.liidestamine WHERE parentid = doc_lapsid AND docid = doc_id)
        THEN
            INSERT INTO lapsed.liidestamine (parentid, docid) VALUES (doc_lapsid, doc_id);
        END IF;

    END IF;


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
select docs.sp_salvesta_arv('{"id":0,"data":{"id":0,"kpv":"2019-09-20T19:46:47.630Z","asutusid":4113,"lapsid":1,"aa":"AA","viitenr":"viitenumber","muud":"test muud","liik":0,"gridData":[{"id":0,"nomid":9,"kogus":1,"hind":100,"kbm":0,"summa":100,"kbm_maar":0}]}}'
, 70, 63);


select * from docs.arv where parentid = 900
select * from docs.arv1 where parentid = 331

"gridData":[{"formula":"","hind":0,"id":0,"kbm":0,"kbmta":0,"km":"","kogus":0,"konto":"","kood":"","kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","kuurs":0,"nimetus":"","nomid":0,"proj":"","soodus":0,"summa":0,"tp":"","tunnus":"","userid":0,"valuuta":"","vastisik":""}]
*/
