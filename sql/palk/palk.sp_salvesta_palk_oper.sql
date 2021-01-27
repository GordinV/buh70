DROP FUNCTION IF EXISTS palk.sp_salvesta_palk_oper(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION palk.sp_salvesta_palk_oper(data JSON,
                                                      userid INTEGER,
                                                      user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    oper_id           INTEGER;
    userName          TEXT;
    doc_id            INTEGER = data ->> 'id';
    doc_data          JSON    = data ->> 'data';
    kas_lausend       BOOLEAN = coalesce((doc_data ->> 'kas_lausend') :: BOOLEAN, FALSE);
    doc_type_kood     TEXT    = 'PALK_OPER';

    doc_type_id       INTEGER = (SELECT id
                                 FROM libs.library
                                 WHERE ltrim(rtrim(upper(kood))) = ltrim(rtrim(upper(doc_type_kood)))
                                   AND library = 'DOK'
                                 LIMIT 1);
    doc_libid         INTEGER = doc_data ->> 'libid';
    doc_lepingid      INTEGER = doc_data ->> 'lepingid';
    doc_kpv           DATE    = doc_data ->> 'kpv';
    doc_summa         NUMERIC = doc_data ->> 'summa';
    doc_dokpropid     INTEGER = doc_data ->> 'dokpropid';
    doc_kood1         TEXT    = doc_data ->> 'kood1';
    doc_kood2         TEXT    = doc_data ->> 'kood2';
    doc_kood3         TEXT    = doc_data ->> 'kood3';
    doc_kood4         TEXT    = doc_data ->> 'kood4';
    doc_kood5         TEXT    = doc_data ->> 'kood5';
    doc_konto         TEXT    = doc_data ->> 'konto';
    doc_tp            TEXT    = doc_data ->> 'tp';
    doc_tunnus        TEXT    = doc_data ->> 'tunnus';
    doc_tunnus_id     INTEGER = doc_data ->> 'tunnusid';
    doc_proj          TEXT    = doc_data ->> 'proj';
    doc_tulumaks      NUMERIC = doc_data ->> 'tulumaks';
    doc_sotsmaks      NUMERIC = doc_data ->> 'sotsmaks';
    doc_tootumaks     NUMERIC = doc_data ->> 'tootumaks';
    doc_pensmaks      NUMERIC = doc_data ->> 'pensmaks';
    doc_tulubaas      NUMERIC = doc_data ->> 'tulubaas';
    doc_tka           NUMERIC = doc_data ->> 'tka';
    doc_period        DATE    = doc_data ->> 'period';
    doc_pohjus        TEXT    = doc_data ->> 'pohjus';
    doc_pohjus_selg   TEXT    = doc_data ->> 'pohjus_selg'; -- пояснение к причине корректировки
    doc_tululiik      TEXT    = doc_data ->> 'tululiik';
    doc_muud          TEXT    = doc_data ->> 'muud';
    kas_arvesta_saldo BOOLEAN = doc_data ->> 'kas_arvesta_saldo';
    new_history       JSONB;
    docs              INTEGER[];
    l_params          JSON;
    l_result          INTEGER;
    is_import         BOOLEAN = data ->> 'import';
    l_props           JSONB;
    kas_arvestus      BOOLEAN = FALSE;
    v_palk_oper       RECORD;
    l_leping_ids      INTEGER[];
    l_lib_ids         INTEGER[]; -- для перерасчета налогов
    l_lib_id          INTEGER;
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

    IF doc_pohjus IS NOT NULL AND NOT empty(doc_pohjus) AND doc_summa > 0
    THEN
        -- корректировка
        RAISE EXCEPTION 'Korrigeerimised summa ainult < 0';
    END IF;

    IF doc_tululiik IS NULL AND doc_libid IN (
        SELECT id
        FROM com_palklib
        WHERE liik = 1
          AND rekvid = user_rekvid
    )
    THEN
        -- не проставлен вид дохода
        doc_tululiik = (SELECT properties::JSONB ->> 'tululiik'
                        FROM libs.library
                        WHERE rekvid = user_rekvid
                          AND id = doc_libid
                        LIMIT 1);

    END IF;

    -- доп. данные
    IF doc_period IS NULL
    THEN
        -- нет периода корректировки , то не нужено и описание
        doc_pohjus_selg = NULL;
        doc_pohjus = NULL;
    END IF;

    l_props = (SELECT row_to_json(row)
               FROM (SELECT doc_pohjus_selg AS pohjus_selg) row);


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
        VALUES (doc_type_id, '[]' :: JSONB || new_history, user_rekvid, 1);
--        RETURNING id  INTO doc_id;

        SELECT currval('docs.doc_id_seq') INTO doc_id;

        INSERT INTO palk.palk_oper (parentid, rekvid, libid, lepingid, kpv, summa, doklausid,
                                    kood1, kood2, kood3, kood4, kood5, konto, tp, tunnus, proj,
                                    tulumaks, sotsmaks, tootumaks, pensmaks, tulubaas, tka, period, pohjus, tululiik,
                                    ajalugu, muud, properties)

        VALUES (doc_id, user_rekvid, doc_libid, doc_lepingid, doc_kpv, doc_summa, doc_dokpropid,
                doc_kood1, doc_kood2, doc_kood3, doc_kood4, doc_kood5, doc_konto, doc_tp, doc_tunnus, doc_proj,
                doc_tulumaks, doc_sotsmaks, doc_tootumaks, doc_pensmaks,
                doc_tulubaas, doc_tka, doc_period, doc_pohjus, doc_tululiik,
                new_history, doc_muud, l_props);
--                RETURNING id INTO oper_id;

    ELSE
        -- определим , это начисление или ?
        IF ((doc_tululiik IS NOT NULL AND NOT empty(doc_tululiik)) OR exists(SELECT id
                                                                             FROM com_palklib
                                                                             WHERE liik = 1
                                                                               AND id = doc_libid
                                                                               AND rekvid = user_rekvid)
            )
        THEN
            -- делаем копию
            SELECT * INTO v_palk_oper FROM palk.palk_oper po WHERE po.parentid = doc_id LIMIT 1;
            IF exists(SELECT id
                      FROM com_palklib
                      WHERE liik = 1
                        AND id = doc_libid
                        AND rekvid = user_rekvid)
            THEN
                -- проверяем были ли изменения на налогах
                -- tm
                IF v_palk_oper.tulumaks <> doc_tulumaks
                THEN
                    kas_arvestus = TRUE;

                    -- была правка ТМ
                    -- надо найти в карте ПН
                    l_lib_id = (SELECT pk.libid
                                FROM palk.palk_kaart pk
                                WHERE lepingid = doc_lepingid
                                  AND libid IN (
                                    SELECT id
                                    FROM libs.library l
                                    WHERE (l.properties::JSONB ->> 'liik')::INTEGER = 4
                                      AND l.library = 'PALK'
                                      AND l.rekvid = user_rekvid
                                      AND l.status = 1
                                    --id = 149054
                                )
                                  AND status = 1
                                LIMIT 1);

                    IF l_lib_id IS NOT NULL
                    THEN
                        l_lib_ids = array_append(l_lib_ids, l_lib_id);
                    END IF;
                END IF;

                --sm
                IF v_palk_oper.sotsmaks <> doc_sotsmaks
                THEN
                    kas_arvestus = TRUE;

                    -- была правка ТМ
                    -- надо найти в карте ПН
                    l_lib_id = (SELECT pk.libid
                                FROM palk.palk_kaart pk
                                WHERE lepingid = doc_lepingid
                                  AND libid IN (
                                    SELECT id
                                    FROM libs.library l
                                    WHERE (l.properties::JSONB ->> 'liik')::INTEGER = 5 -- sm
                                      AND l.library = 'PALK'
                                      AND l.rekvid = user_rekvid
                                      AND l.status = 1
                                    --id = 149054
                                )
                                  AND status = 1
                                LIMIT 1);

                    IF l_lib_id IS NOT NULL
                    THEN
                        l_lib_ids = array_append(l_lib_ids, l_lib_id);
                    END IF;
                END IF;

                --tki
                IF v_palk_oper.tootumaks <> doc_tootumaks
                THEN
                    kas_arvestus = TRUE;

                    -- была правка ТKI
                    -- надо найти в карте ПН
                    l_lib_id = (SELECT pk.libid
                                FROM palk.palk_kaart pk
                                WHERE lepingid = doc_lepingid
                                  AND libid IN (
                                    SELECT id
                                    FROM libs.library l
                                    WHERE (l.properties::JSONB ->> 'liik')::INTEGER = 7      -- tk
                                      AND (l.properties::JSONB ->> 'asutusest')::INTEGER = 0 -- tki
                                      AND l.library = 'PALK'
                                      AND l.rekvid = user_rekvid
                                      AND l.status = 1
                                    --id = 149054
                                )
                                  AND status = 1
                                LIMIT 1);

                    IF l_lib_id IS NOT NULL
                    THEN
                        l_lib_ids = array_append(l_lib_ids, l_lib_id);
                    END IF;
                END IF;

                --tka

                IF v_palk_oper.tka <> doc_tka
                THEN
                    kas_arvestus = TRUE;

                    -- была правка ТKA
                    -- надо найти в карте ПН
                    l_lib_id = (SELECT pk.libid
                                FROM palk.palk_kaart pk
                                WHERE lepingid = doc_lepingid
                                  AND libid IN (
                                    SELECT id
                                    FROM libs.library l
                                    WHERE (l.properties::JSONB ->> 'liik')::INTEGER = 7      -- tk
                                      AND (l.properties::JSONB ->> 'asutusest')::INTEGER = 1 -- tka
                                      AND l.library = 'PALK'
                                      AND l.rekvid = user_rekvid
                                      AND l.status = 1
                                    --id = 149054
                                )
                                  AND status = 1
                                LIMIT 1);

                    RAISE NOTICE 'l_lib_id %', l_lib_id;
                    IF l_lib_id IS NOT NULL
                    THEN
                        l_lib_ids = array_append(l_lib_ids, l_lib_id);
                    END IF;
                END IF;


                --PM
                IF v_palk_oper.pensmaks <> doc_pensmaks
                THEN
                    kas_arvestus = TRUE;

                    -- была правка PM
                    -- надо найти в карте ПН
                    l_lib_id = (SELECT pk.libid
                                FROM palk.palk_kaart pk
                                WHERE lepingid = doc_lepingid
                                  AND libid IN (
                                    SELECT id
                                    FROM libs.library l
                                    WHERE (l.properties::JSONB ->> 'liik')::INTEGER = 8 -- pm
                                      AND l.library = 'PALK'
                                      AND l.rekvid = user_rekvid
                                      AND l.status = 1
                                    --id = 149054
                                )
                                  AND status = 1
                                LIMIT 1);

                    IF l_lib_id IS NOT NULL
                    THEN
                        l_lib_ids = array_append(l_lib_ids, l_lib_id);
                    END IF;
                END IF;

            END IF;
        END IF;


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
        SET kpv        = doc_kpv,
            libid      = doc_libid,
            lepingid   = doc_lepingid,
            summa      = doc_summa,
            doklausid  = doc_dokpropid,
            kood1      = doc_kood1,
            kood2      = doc_kood2,
            kood3      = doc_kood3,
            kood4      = doc_kood4,
            kood5      = doc_kood5,
            konto      = doc_konto,
            tp         = doc_tp,
            tunnus     = doc_tunnus,
            proj       = doc_proj,
            tulumaks   = doc_tulumaks,
            sotsmaks   = doc_sotsmaks,
            tootumaks  = doc_tootumaks,
            pensmaks   = doc_pensmaks,
            tulubaas   = doc_tulubaas,
            tka        = doc_tka,
            period     = doc_period,
            pohjus     = doc_pohjus,
            ajalugu    = new_history,
            muud       = doc_muud,
            properties = l_props
        WHERE parentid = doc_id;
        --RETURNING id             INTO oper_id;

        IF kas_arvestus
        THEN
            -- были изменены налоги, делаем их перерасчет

            -- готовим параметры
            l_leping_ids = array_append(l_leping_ids, doc_lepingid);

            SELECT row_to_json(row) INTO l_params
            FROM (SELECT l_leping_ids  AS leping_ids,
                         l_lib_ids     AS lib_ids,
                         doc_kpv       AS kpv,
                         doc_dokpropid AS dokprop,
                         FALSE         AS is_delete_prev_oper
                 ) row;

            PERFORM palk.gen_palkoper(userid, l_params:: JSON);

        END IF;

    END IF;


    -- расчет сальдо
    IF kas_arvesta_saldo IS NULL OR (kas_arvesta_saldo)
    THEN
        PERFORM palk.sp_update_palk_jaak(doc_kpv::DATE, doc_lepingid::INTEGER);
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
SELECT palk.sp_salvesta_palk_oper('{"id":2490650,"data":{"tulumaks":12.59,"pensmaks":11.67,"tootumaks":9.33,"sotsmaks":192.71,"tka":4.66,"asutusest":0,"bpm":null,"created":"20.01.2021 11:01:52","doc":"Palga operatsioonid","docs_ids":"{2490651}","doc_type_id":"PALK_OPER","dokprop":"Palk","dokpropid":1786,"id":2490650,"journalid":2490651,"kas_lausend":1,"konto":"50028001","kood1":"08102","kood2":"LE-P","kood3":null,"kood4":null,"kood5":"5002","koostaja":"jelena.igolkina","korr_konto":"202000","kpv":"20210131","lastupdate":"20.01.2021 11:01:52","lausend":192,"lepingid":31524,"libid":139396,"liik":1,"muud":"Kokku tunnid kuues,:160.00(r)Palk kokku:584.00(r)Tunni hind:3.65(r)parandamine:3.65*100.00 * 0.01 *160.000(r)TKI arvestus:584.00*0.0160*1.60*1(r)PM arvestus:584.00*0.0200*1*1(r)SM arvestus:584.00*0.3300*1(r)TKA arvestus:584.00*0.0080(r)TM arvestus:12.60(r)","parentid":7987,"period":null,"pohjus":null,"pohjus_selg":null,"proj":"","rekvid":125,"status":"Aktiivne","summa":584,"tp":"800699","tulubaas":500,"tululiik":"10","tunnus":"0810202"}}',
 3311, 125);

select * from ou.userid where rekvid = 125 and kasutaja = 'vlad'

*/
