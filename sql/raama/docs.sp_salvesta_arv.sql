﻿DROP FUNCTION IF EXISTS docs.sp_salvesta_arv(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_arv(data JSON,
                                                user_id INTEGER,
                                                user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    arv_id                 INTEGER;
    arv1_id                INTEGER;
    userName               TEXT;
    doc_id                 INTEGER        = data ->> 'id';
    doc_data               JSON           = data ->> 'data';
    doc_type_kood          TEXT           = 'ARV';
    doc_type_id            INTEGER        = (
                                                SELECT
                                                    id
                                                FROM
                                                    libs.library
                                                WHERE
                                                      kood = doc_type_kood
                                                  AND library = 'DOK'
                                                LIMIT 1
                                            );
    doc_details            JSON           = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');
    doc_number             TEXT           = doc_data ->> 'number';
    doc_summa              NUMERIC(14, 4) = coalesce((doc_data ->> 'summa') :: NUMERIC, 0);
    doc_liik               INTEGER        = doc_data ->> 'liik';
    doc_operid             INTEGER        = doc_data ->> 'operid';
    doc_asutusid           INTEGER        = doc_data ->> 'asutusid';
    doc_lisa               TEXT           = doc_data ->> 'lisa';
    doc_kpv                DATE           = doc_data ->> 'kpv';
    doc_tahtaeg_text       TEXT           = CASE
                                                WHEN (trim(doc_data ->> 'tahtaeg')::TEXT)::TEXT = '' THEN current_date::TEXT
                                                ELSE ((doc_data ->> 'tahtaeg')::TEXT) END;
    doc_tahtaeg            DATE           = doc_tahtaeg_text::DATE;
    doc_kbmta              NUMERIC(14, 4) = coalesce((doc_data ->> 'kbmta') :: NUMERIC, 0);
    doc_kbm                NUMERIC(14, 4) = coalesce((doc_data ->> 'kbm') :: NUMERIC, 0);
    doc_muud               TEXT           = doc_data ->> 'muud';
    doc_objektid           INTEGER        = doc_data ->> 'objektid'; -- считать или не считать (если не пусто) интресс
    doc_objekt             TEXT           = doc_data ->> 'objekt';
    tnDokLausId            INTEGER        = coalesce((doc_data ->> 'doklausid') :: INTEGER, 1);
    doc_lepingId           INTEGER        = doc_data ->> 'leping_id';
    doc_aa                 TEXT           = doc_data ->> 'aa'; -- eri arve
    doc_viitenr            TEXT           = doc_data ->> 'viitenr'; -- viite number
    doc_lapsid             INTEGER        = doc_data ->> 'lapsid'; -- kui arve salvestatud lapse modulis
    doc_type               TEXT           = doc_data ->> 'tyyp'; -- ETTEMAKS - если счет на предоплату, hooldekodu
    doc_print              JSONB          = coalesce((doc_data ->> 'print')::JSONB, '[]'::JSONB); -- '["paber","email","earve"]'
    doc_ettemaksu_period   INTEGER        = doc_data ->> 'ettemaksu_period'; -- период в месяцах для счета на предоплату или номер периода в доходных
    doc_ettemaksu_arve_id  INTEGER        = doc_data ->> 'ettemaksu_arve_id'; -- ссылка на счет предоплатв
    doc_asendus_id         INTEGER        = doc_data ->> 'asendus_id'; -- на основании импортированного табеля из замещения
    doc_taskuraha_kov      NUMERIC        = doc_data ->> 'taskuraha_kov'; -- сумма карманных денег, по алгоритму замещения
    doc_alus_arve_id       INTEGER        = doc_data ->> 'alus_arve_id'; -- ссылка на базовый счет (кредиоовые счета)
    doc_kas_peata_saatmine BOOLEAN        = doc_data ->> 'kas_peata_saatmine'; --запрет на электронную рассылку
    doc_kreedit_arved      JSONB          = doc_data ->> 'kreedit_arved'; -- ссылка на крелитовые счета при переносе долга

-- Hooldekodu
    doc_isik_id            INTEGER        = doc_data ->> 'isik_id'; -- kui arve salvestatud hooldekodu modulist

    dok_props              JSONB;
    json_object            JSON;
    json_record            RECORD;
    new_history            JSONB;
    new_rights             JSONB;
    ids                    INTEGER[];
    l_json_arve_id         JSONB;
    is_import              BOOLEAN        = data ->> 'import';
    arv1_rea_json          JSONB;
    l_jaak                 NUMERIC;
    l_mks                  RECORD;
    v_aasta                RECORD;
    l_osaliselt_suletatud  BOOLEAN        = FALSE;
    l_suletatud            BOOLEAN        = FALSE;
    l_raha_saaja           TEXT; -- PayToName for export
    l_umardamine           numeric        = 0; -- округление

BEGIN
    -- если есть ссылка на ребенка, то присвоим viitenumber
    IF doc_lapsid IS NOT NULL
    THEN
        doc_viitenr = lapsed.get_viitenumber(user_rekvid, doc_lapsid);
    END IF;

    IF user_rekvid = 132
    THEN
        l_raha_saaja = (
                           SELECT ltrim(rtrim(muud)) AS raha_saaja FROM ou.rekv WHERE id = 64 LIMIT 1
                       );
    END IF;
    dok_props = (
                    SELECT
                        row_to_json(row)
                    FROM
                        (
                            SELECT
                                doc_aa                                  AS aa,
                                doc_viitenr                             AS viitenr,
                                doc_type                                AS tyyp,
                                doc_ettemaksu_period                    AS ettemaksu_period,
                                doc_isik_id                             AS isik_id,
                                doc_asendus_id                          AS asendus_id,
                                doc_taskuraha_kov                       AS taskuraha_kov,
                                l_raha_saaja                            AS raha_saaja,
                                doc_print                               AS print,
                                l_umardamine                            as umardamine,
                                coalesce(doc_kas_peata_saatmine, FALSE) AS kas_peata_saatmine
                        ) row
                );

    IF doc_kreedit_arved IS NOT NULL
    THEN
        dok_props = dok_props || jsonb_build_object('doc_kreedit_arved', doc_kreedit_arved);
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

    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
          u.rekvid = user_rekvid
      AND u.id = user_id;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF NOT ou.fnc_aasta_kontrol(user_rekvid, doc_kpv)
    THEN
        IF (doc_id IS NULL OR doc_id = 0) AND doc_liik = 1
        THEN
            -- проверяем период
            -- То есть тогда, если вдруг по каким-то причинам период закрыт, то алгоритм должен это учитывать и делать проводки в первом месяце открытого периода.
            SELECT *
            INTO v_aasta
            FROM
                ou.aasta
            WHERE
                  rekvid = user_rekvid
              AND aasta = year(doc_kpv)
              AND kinni = 1
            ORDER BY make_date(aasta, kuu, 1) DESC
            LIMIT 1;
            doc_kpv = gomonth(make_date(v_aasta.aasta, v_aasta.kuu, 1)::DATE, 1);
            --        ELSE
--            RAISE EXCEPTION 'Viga, Period on kinni, doc_kpv %', doc_kpv;
        END IF;
    END IF;

    l_suletatud = (
                      SELECT NOT ou.fnc_aasta_kontrol(user_rekvid, doc_kpv)
                  );
    IF (l_suletatud)
    THEN
        l_osaliselt_suletatud = ou.is_last_quarter_opened(user_rekvid, doc_kpv);
    END IF;

    IF is_import IS NULL AND l_suletatud AND NOT l_osaliselt_suletatud
    THEN
        RAISE EXCEPTION 'Viga, Period on kinni, doc_kpv %', doc_kpv;
    END IF;


-- установим срок оплаты, если не задан
    IF doc_tahtaeg IS NULL OR doc_tahtaeg < doc_kpv
    THEN
        doc_tahtaeg = doc_kpv + coalesce((
                                             SELECT
                                                 tahtpaev
                                             FROM
                                                 ou.config
                                             WHERE
                                                 rekvid = user_rekvid
                                             LIMIT 1
                                         ), 14);
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN
        IF is_import IS NULL AND l_suletatud AND l_osaliselt_suletatud
        THEN
            RAISE EXCEPTION 'Viga, Period on kinni, doc_kpv %', doc_kpv;
        END IF;

        SELECT
            row_to_json(row)
        INTO new_history
        FROM
            (
                SELECT
                    now()    AS created,
                    userName AS user
            ) row;

        SELECT
            row_to_json(row)
        INTO new_rights
        FROM
            (
                SELECT
                    ARRAY [user_id] AS "select",
                    ARRAY [user_id] AS "update",
                    ARRAY [user_id] AS "delete"
            ) row;

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
        INSERT INTO
            docs.arv (parentid, rekvid, userid, liik, operid, number, kpv, asutusid, lisa, tahtaeg, kbmta, kbm,
                      summa, muud, objektid, objekt, doklausid, properties)
        VALUES
            (doc_id, user_rekvid, user_id, doc_liik, doc_operid, doc_number, doc_kpv, doc_asutusid, doc_lisa,
             doc_tahtaeg,
             doc_kbmta, doc_kbm, doc_summa,
             doc_muud, doc_objektid, doc_objekt, tnDokLausId, dok_props)
        RETURNING id
            INTO arv_id;

    ELSE
        -- history
        SELECT
            row_to_json(row)
        INTO new_history
        FROM
            (
                SELECT
                    now()    AS updated,
                    userName AS user
            ) row;

        IF NOT l_suletatud
        THEN
            -- не допустимо при закрытии периода

            UPDATE docs.doc
            SET
                lastupdate = now(),
                history    = coalesce(history, '[]') :: JSONB || new_history,
                rekvid     = user_rekvid
            WHERE
                id = doc_id;

            IF doc_lepingId IS NOT NULL
            THEN
                -- will add reference to leping
                UPDATE docs.doc
                SET
                    docs_ids = array_append(docs_ids, doc_lepingId)
                WHERE
                    id = doc_id;
            END IF;

            UPDATE docs.arv
            SET
                liik       = doc_liik,
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
            WHERE
                parentid = doc_id
            RETURNING id
                INTO arv_id;

        END IF;

    END IF;

    -- вставка в таблицы документа
    FOR json_object IN
        SELECT *
        FROM
            json_array_elements(doc_details)
        LOOP
            SELECT *
            INTO json_record
            FROM
                json_to_record(
                        json_object) AS x (id TEXT, nomId INTEGER, kogus NUMERIC(14, 4), hind NUMERIC(14, 4),
                                           kbm NUMERIC(14, 4),
                                           kbmta NUMERIC(14, 4),
                                           summa NUMERIC(14, 4), kood TEXT, nimetus TEXT, kood1 TEXT, kood2 TEXT,
                                           kood3 TEXT,
                                           kood4 TEXT, kood5 TEXT,
                                           konto TEXT, tunnus TEXT, tp TEXT, proj TEXT, arve_id INTEGER, muud TEXT,
                                           km TEXT, yksus TEXT, all_yksus TEXT, lapse_taabel_id INTEGER,
                                           asendus_id INTEGER,
                                           soodustus NUMERIC(14, 4), soodus NUMERIC(14, 4),
                                           allikas_85 NUMERIC(12, 2),
                                           allikas_vara NUMERIC(12, 2), allikas_muud NUMERIC(12, 2),
                                           allikas_taskuraha NUMERIC(12, 2),
                                           umardamine NUMERIC(12, 2), sugulane_osa NUMERIC(12, 2),
                                           omavalitsuse_osa NUMERIC(12, 2), objekt TEXT);


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


            SELECT
                row_to_json(row)
            INTO arv1_rea_json
            FROM
                (
                    SELECT
                        json_record.yksus,
                        json_record.all_yksus,
                        json_record.lapse_taabel_id,
                        json_record.asendus_id,
                        CASE
                            WHEN json_record.soodustus IS NULL OR empty(json_record.soodustus)
                                THEN coalesce(json_record.soodus, 0)
                            ELSE json_record.soodustus END         AS soodustus,
                        coalesce(json_record.allikas_85, 0)        AS allikas_85,
                        coalesce(json_record.allikas_vara, 0)      AS allikas_vara,
                        coalesce(json_record.allikas_muud, 0)      AS allikas_muud,
                        coalesce(json_record.allikas_taskuraha, 0) AS allikas_taskuraha,
                        coalesce(json_record.umardamine, 0)        AS umardamine,
                        coalesce(json_record.sugulane_osa, 0)      AS sugulane_osa,
                        coalesce(json_record.omavalitsuse_osa, 0)  AS omavalitsuse_osa
                ) row;

            IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
            THEN
                IF empty(coalesce(json_record.km, ''))
                THEN
                    json_record.kbm = 0;
                END IF;

                IF coalesce(json_record.km, '') NOT IN ('0', '5', '9', '10', '20', '22', '24')
                THEN
                    json_record.km = '0';
                END IF;

                IF NOT l_osaliselt_suletatud
                THEN

                    INSERT INTO
                        docs.arv1 (parentid, nomid, kogus, hind, kbm, kbmta, summa, kood1, kood2, kood3, kood4,
                                   kood5,
                                   konto, tunnus, objekt, tp, proj, muud, kbm_maar, properties, soodus)
                    VALUES
                        (arv_id, json_record.nomid,
                         coalesce(json_record.kogus, 1),
                         coalesce(json_record.hind, 0),
                         coalesce(json_record.kbm, 0),
                         coalesce(json_record.kbmta, coalesce(json_record.kogus, 1) * coalesce(json_record.hind, 0)),
                         coalesce(json_record.summa,
                                  (coalesce(json_record.kogus, 1) * coalesce(json_record.hind, 0)) +
                                  coalesce(json_record.kbm, 0)),
                         coalesce(json_record.kood1, ''),
                         coalesce(json_record.kood2, ''),
                         coalesce(json_record.kood3, ''),
                         coalesce(json_record.kood4, ''),
                         coalesce(json_record.kood5, ''),
                         coalesce(json_record.konto, ''),
                         coalesce(json_record.tunnus, ''),
                         json_record.objekt,
                         coalesce(json_record.tp, ''),
                         coalesce(json_record.proj, ''),
                         coalesce(json_record.muud, ''),
                         CASE
                             WHEN doc_kpv >= '2024-01-01' AND coalesce(json_record.km, '') = '20' THEN '22'
                             ELSE coalesce(json_record.km, '') END,
                         arv1_rea_json,
                         CASE
                             WHEN json_record.soodustus IS NULL OR empty(json_record.soodustus)
                                 THEN coalesce(json_record.soodus, 0)
                             ELSE json_record.soodustus END ::NUMERIC(14, 4))
                    RETURNING id
                        INTO arv1_id;

                    -- add new id into array of ids
                    ids = array_append(ids, arv1_id);
                END IF;

            ELSE
                IF coalesce(json_record.km, '') NOT IN ('0', '5', '9', '10', '20', '22', '24')
                THEN
                    json_record.km = '0';
                END IF;

                IF empty(coalesce(json_record.km, ''))
                THEN
                    json_record.kbm = 0;
                END IF;

                IF l_osaliselt_suletatud
                THEN
                    -- допустимо менять только доп. классификаторы
                    UPDATE docs.arv1
                    SET
                        kood4  = coalesce(json_record.kood4, ''),
                        tunnus = coalesce(json_record.tunnus, ''),
                        objekt = json_record.objekt,
                        proj   = coalesce(json_record.proj, '')
                    WHERE
                        id = json_record.id :: INTEGER
                    RETURNING id
                        INTO arv1_id;

                ELSE

                    UPDATE docs.arv1
                    SET
                        parentid   = arv_id,
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
                        objekt     = json_record.objekt,
                        tp         = coalesce(json_record.tp, ''),
                        proj       = coalesce(json_record.proj, ''),
                        kbm_maar   = CASE
                                         WHEN doc_kpv >= '2024-01-01' AND coalesce(json_record.km, '') = '20' THEN '22'
                                         ELSE coalesce(json_record.km, '') END,

                        muud       = json_record.muud,
                        soodus     = CASE
                                         WHEN json_record.soodustus IS NULL OR empty(json_record.soodustus)
                                             THEN coalesce(json_record.soodus, 0)
                                         ELSE json_record.soodustus END::NUMERIC(14, 4),
                        properties = coalesce(properties, '{}'::JSONB) || arv1_rea_json
                    WHERE
                        id = json_record.id :: INTEGER
                    RETURNING id
                        INTO arv1_id;

                    -- add new id into array of ids
                    ids = array_append(ids, arv1_id);
                END IF;

            END IF;

            IF (arv1_id IS NOT NULL AND NOT empty(arv1_id) AND json_record.arve_id IS NOT NULL AND
                NOT l_osaliselt_suletatud)
            THEN
                -- в параметрах есть ссылки на другие счета
                l_json_arve_id = (
                                     SELECT
                                         row_to_json(row)
                                     FROM
                                         (
                                             SELECT json_record.arve_id AS arve_id
                                         ) row
                                 )::JSONB;
                UPDATE docs.arv1
                SET
                    properties = coalesce(properties::JSONB, '{}'::JSONB)::JSONB || l_json_arve_id
                WHERE
                    id = arv1_id;

                -- установим связь со счетом , на который выписан интрес
                UPDATE docs.doc
                SET
                    docs_ids = array_append(docs_ids, doc_id)
                WHERE
                    id = json_record.arve_id;

            END IF;

            -- есои задан параметр json_record.lapse_kaart_id то устанавливаем статус табеля = 2 (закрыт)
            IF json_record.lapse_taabel_id IS NOT NULL AND NOT l_osaliselt_suletatud
            THEN
                UPDATE lapsed.lapse_taabel SET staatus = 2 WHERE id = json_record.lapse_taabel_id;
            END IF;


        END LOOP;

    -- delete record which not in json
    IF array_length(ids, 1) > 0 AND NOT l_osaliselt_suletatud
    THEN
        -- проверить на наличие ссылок на другие счета и снять ссылку
        IF exists
        (
            SELECT
                d.id
            FROM
                docs.doc d
            WHERE
                d.id IN (
                            SELECT
                                (properties ->> 'arve_id')::INTEGER
                            FROM
                                docs.arv1 a1
                            WHERE
                                  a1.parentid = arv_id
                              AND a1.id NOT IN (
                                                   SELECT unnest(ids)
                                               )
                        )
        )
        THEN
            -- есть ссылка, надо снять
            UPDATE docs.doc
            SET
                docs_ids = array_remove(docs_ids, doc_id)
            WHERE
                id IN (
                          SELECT
                              (a1.properties ->> 'arve_id')::INTEGER
                          FROM
                              docs.arv1               a1
                                  INNER JOIN docs.arv a ON a.id = a1.parentid
                          WHERE
                                a.parentid = doc_id
                            AND a1.id NOT IN (
                                                 SELECT unnest(ids)
                                             )
                      );
        END IF;

        DELETE
        FROM
            docs.arv1
        WHERE
              parentid = arv_id
          AND id NOT IN (
                            SELECT unnest(ids)
                        );
    END IF;

    IF NOT l_osaliselt_suletatud
    THEN
        -- update arv summad
        SELECT
            sum(summa) AS summa,
            sum(kbm)   AS kbm
        INTO doc_summa, doc_kbm
        FROM
            docs.arv1
        WHERE
            parentid = arv_id;

        -- округление после 2025 года
        if coalesce((
                        select
                            c.properties ->> 'round_arve' as umardamine
                        from
                            ou.config c
                        where
                            c.rekvid = user_rekvid
                        limit 1
                    )::integer, 0) > 0
            and doc_kpv >= '2025-01-01'::date
            and doc_liik = 0 -- только исходящие счета
        then
            -- расчет ТП кода
            if exists
            (
                select a.id from libs.asutus a where a.id = doc_asutusid and a.tp = '800699'
            ) then
                -- частное лицо, округляем

                -- итоговую сумму правим на округление до 5 центов
                doc_taskuraha_kov = coalesce(doc_taskuraha_kov, 0);
                l_umardamine = fnc_round_5(doc_summa - doc_taskuraha_kov) - (doc_summa - doc_taskuraha_kov);
                --doc_summa = doc_summa + coalesce(l_umardamine,0);

                -- В.Б. 19.02.2025. снять округление со счетов
                l_umardamine = 0;

                UPDATE docs.arv
                SET
                    properties = properties::jsonb || jsonb_build_object('umardamine', l_umardamine)
                where
                    parentid = doc_id;
            end if;


        end if;

        UPDATE docs.arv
        SET
            kbmta = coalesce(doc_summa, 0) - coalesce(doc_kbm, 0),
            kbm   = coalesce(doc_kbm, 0),
            summa = coalesce(doc_summa, 0)
        WHERE
            parentid = doc_id;

        IF (doc_ettemaksu_arve_id IS NOT NULL)
        THEN
            -- will add reference to ettemaksu arve
            UPDATE docs.doc
            SET
                docs_ids = array_append(docs_ids, doc_ettemaksu_arve_id)
            WHERE
                id = doc_id;

            UPDATE docs.doc
            SET
                docs_ids = array_append(docs_ids, doc_id)
            WHERE
                id = doc_ettemaksu_arve_id;


        END IF;

        -- lapse module

        IF doc_lapsid IS NOT NULL
        THEN
            IF NOT exists
            (
                SELECT id FROM lapsed.liidestamine WHERE parentid = doc_lapsid AND docid = doc_id
            )
            THEN
                INSERT INTO lapsed.liidestamine (parentid, docid) VALUES (doc_lapsid, doc_id);
            END IF;

        END IF;

        -- расчет сальдо счета
        l_jaak = docs.sp_update_arv_jaak(doc_id);

        IF doc_id IS NOT NULL AND doc_id > 0 AND l_jaak > 0
        THEN
            -- проверить на наличие предоплат
            PERFORM docs.sp_loe_arv(doc_id, user_id);
        END IF;

        -- если счет отрицательный, то возможно это кредитоввый счет
        IF doc_id IS NOT NULL AND doc_id > 0 AND doc_summa < 0
            and not exists
           (
               select
                   at.id
               from
                   docs.arvtasu at
               where
                     at.doc_tasu_id = doc_id
                 and at.status < 3
           )
        THEN
            PERFORM docs.kas_kreedit_arve(doc_id, user_id, doc_alus_arve_id);
        END IF;

        -- уточним дату счета в оплатах , если он кредитовый
        IF doc_id IS NOT NULL AND doc_id > 0 AND doc_summa < 0 then
            update docs.arvtasu set kpv = doc_kpv where doc_tasu_id = doc_id and status < 3;
        end if;


        -- если это доходный счет, созданный на основе предоплатного
        IF doc_ettemaksu_arve_id IS NULL AND doc_ettemaksu_period IS NOT NULL
        THEN
            doc_ettemaksu_arve_id = (
                                        SELECT
                                            d.id
                                        FROM
                                            docs.doc                d
                                                INNER JOIN docs.arv a ON d.id = a.parentid
                                        WHERE
                                              d.id IN (
                                                          SELECT
                                                              unnest((
                                                                         SELECT
                                                                             d.docs_ids
                                                                         FROM
                                                                             docs.arv                a
                                                                                 INNER JOIN docs.doc d ON d.id = a.parentid
                                                                         WHERE
                                                                             parentid = doc_id
                                                                     ))
                                                      )
                                          AND a.properties ->> 'tyyp' IS NOT NULL
                                          AND a.properties ->> 'tyyp' = 'ETTEMAKS'
                                        LIMIT 1
                                    );

        END IF;

        IF doc_ettemaksu_arve_id IS NOT NULL
        THEN
            -- проверим оплату счета
            IF exists
            (
                SELECT
                    id
                FROM
                    docs.arv
                WHERE
                    parentid = doc_ettemaksu_arve_id
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

    END IF;
    RETURN doc_id;
END ;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

--GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(JSON, INTEGER, INTEGER) TO ladukasutaja;
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