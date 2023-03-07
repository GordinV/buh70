--DROP FUNCTION IF EXISTS palk.gen_palk_dok(INTEGER, JSON);
DROP FUNCTION IF EXISTS palk.gen_palk_dok_(INTEGER, JSON);


CREATE OR REPLACE FUNCTION palk.gen_palk_dok_(IN user_id INTEGER, IN params JSON, OUT result INTEGER,
                                              OUT error_code INTEGER,
                                              OUT error_message TEXT,
                                              OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    v_lib           RECORD;

    l_kpv           DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_isik_ids      JSON    = params -> 'isik_ids'; -- массив индентификаторов работников
    l_lib_ids       JSON    = params -> 'lib_ids'; -- массив индентификаторов операций
    l_osakond_ids   JSON    = params ->> 'osakond_ids'; -- массив отделов
    l_proj_ids      JSON    = params ->> 'proj_ids'; -- массив отделов
    kas_mmk         BOOLEAN = FALSE;

    v_po            RECORD;
    v_mk            RECORD;
    v_mk1           RECORD;
    ids             INTEGER[];
    l_grid_params   JSONB   = '[]';
    l_dok_id        INTEGER = 0; -- ИД сформированной проводки
    v_palk_kaart    RECORD; -- соберем все данные операции в строку
    v_user          RECORD;
    l_params        JSONB;
    l_rekv_id       INTEGER = (SELECT rekvid
                               FROM ou.userid
                               WHERE id = user_id
                               LIMIT 1);
    MK_TYYP         INTEGER = 1; -- VMK
    l_mk_number     BIGINT  = docs.sp_get_number(l_rekv_id, 'VMK', year(l_kpv), NULL);
    l_vorder_number INTEGER = docs.sp_get_number(l_rekv_id, 'VORDER'::TEXT, year(l_kpv), NULL::INTEGER);
    v_tulemus       RECORD;
    l_journal_ids   INTEGER[];
    l_po_ids        INTEGER[];
BEGIN

    SELECT 0                                  AS id,
           'VMK'                              AS doc_type_id,
           NULL::TEXT                         AS number,
           0 :: INTEGER                       AS id,
           1                                  AS opt,
           l_kpv                              AS kpv,
           l_kpv                              AS maksepaev,
           'Tasu töötamisest'                 AS muud,
           'Tasu töötamisest'                 AS selg,
           ou.get_aa(l_rekv_id, 'PALK'::TEXT) AS aaid,
           NULL::NUMERIC                      AS summa
    INTO v_mk;

    SELECT kasutaja,
           rekvid
    INTO v_user
    FROM ou.userid u
    WHERE u.id = user_Id;

    -- just for init
    SELECT 0 AS error_code, NULL::TEXT AS error_message INTO v_tulemus;

    IF v_user.kasutaja IS NULL
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;

        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

        RETURN;
    END IF;

    IF l_isik_ids IS NULL OR json_array_length(l_isik_ids) = 0
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad';
        result = 0;

        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

        RETURN;

    END IF;
    -- определяем тип платежного поручения
    kas_mmk =
            coalesce((SELECT properties ->> 'mmk' FROM palk.palk_config WHERE rekvid = v_user.rekvid LIMIT 1)::BOOLEAN,
                     FALSE);


    IF kas_mmk
    THEN
        SELECT 0                                  AS id,
               'VMK'                              AS doc_type_id,
               l_mk_number                        AS number,
               0 :: INTEGER                       AS id,
               MK_TYYP                            AS opt,
               l_kpv                              AS kpv,
               l_kpv                              AS maksepaev,
               'Tasu töötamisest'                 AS muud,
               'Tasu töötamisest'                 AS selg,
               ou.get_aa(l_rekv_id, 'PALK'::TEXT) AS aaid,
               NULL::NUMERIC                      AS summa
        INTO v_mk;

    END IF;

    -- выбираем операции для подготовки расчет
    FOR v_po IN
        SELECT rekvid,
               isikid,
               sum(summa)                                                                   AS summa,
               tunnus,
               asutus_aa,
               nimi,
               aadress,
               tp,
               is_kassa,
               array_agg(CASE WHEN docs_ids = '{}' THEN '{0}'::INTEGER[] ELSE docs_ids END) AS docs_ids,
--               array_agg(docs_ids)  AS docs_ids,
               array_agg(journalid)                                                         AS journal_ids,
               array_agg(qry.id)                                                            AS po_ids

        FROM (
                 WITH docs_types AS (
                     SELECT id, kood
                     FROM libs.library
                     WHERE library.library = 'DOK'
                       AND kood IN ('PALK_OPER', 'VMK', 'VORDER')
                 )

                 SELECT d.id,
                        d.rekvid,
                        t.parentid                              AS isikid,
                        po.summa,
                        po.tunnus,
                        po.proj,
                        po.konto,
                        po.kood1,
                        po.kood2,
                        po.kood3,
                        po.kood4,
                        po.kood5,
                        po.journalid,
                        l.properties :: JSON ->> 'konto'        AS korr_konto,
                        libs.get_asutuse_aa(a.id, 'PALK'::TEXT) AS asutus_aa,
                        -- isiku pank arve
                        a.regkood                               AS isikukood,
                        a.nimetus                               AS nimi,
                        a.aadress,
                        a.tp,
                        coalesce((SELECT aa.kassa = 0
                                  FROM ou.aa aa
                                  WHERE aa.parentid = d.rekvid
                                    AND konto = (l.properties :: JSON ->> 'konto')
                                  LIMIT 1), FALSE)              AS is_kassa,
                        d.docs_ids                              AS docs_ids
                 FROM palk.palk_oper po
                          INNER JOIN docs.doc d ON d.id = po.parentid
                          INNER JOIN palk.tooleping t ON t.id = po.lepingid
                          INNER JOIN libs.asutus a ON a.id = t.parentid
                          INNER JOIN libs.library l
                                     ON l.id = po.libid AND (l.properties :: JSONB ->> 'liik') :: INTEGER = 6 -- только выплаты
                 WHERE t.parentid IN (SELECT value :: INTEGER
                                      FROM json_array_elements_text(l_isik_ids))
                   AND po.kpv = l_kpv                                                        -- только за определенную дату
                   AND D.doc_type_id IN (SELECT id FROM docs_types WHERE kood = 'PALK_OPER') -- оптимизация
                   AND d.rekvid = v_user.rekvid
                   AND po.rekvid = v_user.rekvid                                             -- только свое учреждение
                   AND l.id IN (SELECT value :: INTEGER
                                FROM json_array_elements_text(l_lib_ids))                    -- только указанные операции
                   AND t.osakondid IN (SELECT value :: INTEGER
                                       FROM json_array_elements_text(l_osakond_ids))         -- только указанные отделы
                   AND (po.proj IS NULL OR po.proj IN (
                     SELECT kood
                     FROM (
                              SELECT id, kood
                              FROM libs.library
                              WHERE library = 'PROJ'
                                AND rekvid = v_user.rekvid
                                AND id IN (
                                  SELECT value :: INTEGER
                                  FROM json_array_elements_text(l_proj_ids::JSON))
                              UNION ALL
                              SELECT 0 AS id, '' AS kood
                          ) qry
                 ) -- только указанные проекты

                     OR json_array_length(coalesce(l_proj_ids::JSON, '[]'::JSON)) = 0
                     )

                   AND NOT
                     exists(SELECT dd.id
                            FROM docs.doc dd
                            WHERE dd.id IN (SELECT *
                                            FROM unnest(d.docs_ids))
                              AND dd.rekvid = v_user.rekvid
                              AND dd.status <> 3
                              AND dd.doc_type_id IN (SELECT id FROM docs_types WHERE kood <> 'PALK_OPER')
                         )
             ) qry
        GROUP BY rekvid, isikid, nimi, aadress, tunnus, asutus_aa, tp,
                 is_kassa

        LOOP
            -- инициализируем
            SELECT NULL::INTEGER           AS doc_id,
                   ltrim(rtrim(v_po.nimi)) AS error_message,
                   NULL::INTEGER           AS error_code
            INTO v_tulemus;

            -- создаем документ

            IF NOT v_po.is_kassa
            THEN

                IF NOT kas_mmk
                THEN
                    -- для ммк параметры созданы выше
--                    l_mk_number = docs.sp_get_number(l_rekv_id, 'VMK', year(l_kpv), NULL);
                    -- MK
                    SELECT 0                                  AS id,
                           'VMK'                              AS doc_type_id,
                           l_mk_number                        AS number,
                           0 :: INTEGER                       AS id,
                           MK_TYYP                            AS opt,
                           l_kpv                              AS kpv,
                           l_kpv                              AS maksepaev,
                           'Tasu töötamisest'                 AS muud,
                           'Tasu töötamisest'                 AS selg,
                           ou.get_aa(l_rekv_id, 'PALK'::TEXT) AS aaid,
                           v_po.summa                         AS summa
                    INTO v_mk;

                END IF;
                --MK1
                SELECT v_po.isikid    AS asutusid,
                       (SELECT id
                        FROM libs.nomenklatuur n
                        WHERE dok IN ('MK', 'VMK')
                          AND n.rekvid = v_po.rekvid
                          AND n.status < 3
                        ORDER BY id DESC
                        LIMIT 1)      AS nomid,
                       v_po.asutus_aa AS aa,
                       v_po.tunnus,
                       v_po.tp,
                       v_po.summa     AS summa
                INTO v_mk1;

                l_grid_params = l_grid_params || to_jsonb(v_mk1);


                IF NOT kas_mmk
                THEN
                    -- создаем мк, не ммк
                    v_mk.number = l_mk_number;

                    SELECT json_object_agg('data', qry.data || qry."gridData")
                    INTO l_params
                    FROM (SELECT 0                                           AS id,
                                 to_jsonb(v_mk)                              AS data,
                                 jsonb_object_agg('gridData', l_grid_params) AS "gridData") qry;

                    -- save results
                    l_dok_id = docs.sp_salvesta_mk(
                            l_params :: JSON,
                            user_id,
                            v_po.rekvid);

                    -- обнулим данные мк
                    l_grid_params = '[]'::JSONB;
                END IF;

            ELSE
                -- VORDER
                SELECT coalesce(l_dok_id, 0) AS id,
                       2                     AS tyyp,
                       l_vorder_number       AS number,
                       0 :: INTEGER          AS id,
                       l_kpv                 AS kpv,
                       v_po.isikid           AS asutusid,
                       v_po.nimi,
                       v_po.aadress,
                       'Tasu töötamisest'    AS muud,
                       'Tasu töötamisest'    AS alus,
                       v_po.summa            AS summa
                INTO v_mk;

                --MK1
                SELECT v_po.isikid AS asutusid,
                       (SELECT id
                        FROM libs.nomenklatuur n
                        WHERE dok = 'VORDER'
                          AND n.rekvid = v_po.rekvid
                          AND n.status < 3
                        ORDER BY id DESC
                        LIMIT 1)   AS nomid,
                       v_po.tunnus,
                       v_po.tp,
                       v_po.summa  AS summa
                INTO v_mk1;

                l_grid_params = l_grid_params || to_jsonb(v_mk1);

                SELECT json_object_agg('data', qry.data || qry."gridData")
                INTO l_params
                FROM (SELECT to_jsonb(v_mk)                              AS data,
                             jsonb_object_agg('gridData', l_grid_params) AS "gridData") qry;

                -- save results
                l_dok_id = docs.sp_salvesta_korder(
                        l_params :: JSON,
                        user_id,
                        v_po.rekvid);

                l_grid_params = '[]'::JSONB;

                l_vorder_number = l_vorder_number + 1;
            END IF;

            IF NOT kas_mmk
            THEN
                IF l_dok_id IS NOT NULL AND l_dok_id > 0
                THEN
                    -- добавим ссылку на PO

                    SELECT docs_ids
                    INTO ids
                    FROM docs.doc
                    WHERE id = l_dok_id;

                    ids = ids || v_po.po_ids || v_po.journal_ids;

                    UPDATE docs.doc
                    SET docs_ids = ids
                    WHERE id = l_dok_id;

                    -- добавим ссылку на VMK / Vorder
                    UPDATE docs.doc
                    SET docs_ids = array_append(docs_ids, l_dok_id)
                    WHERE id IN (SELECT unnest(v_po.po_ids));

                    result = coalesce(result, 0) + 1;
                END IF;

                -- report
            END IF;

            l_params = to_jsonb(row.*)
                       FROM (
                                SELECT l_dok_id                                                  AS doc_id,
                                       ltrim(rtrim(v_po.nimi)) || ': mk number: ' || l_mk_number AS error_message,
                                       0::INTEGER                                                AS error_code
                            ) row;
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

            -- пишем массив проводок для дальнейшей работы
            l_journal_ids = l_journal_ids || v_po.journal_ids;
            l_po_ids = l_po_ids || v_po.po_ids;

            l_mk_number = l_mk_number + 1;
        END LOOP; -- po loop

    IF kas_mmk
    THEN
        -- сохраним ммк
        SELECT json_object_agg('data', qry.data || qry."gridData")
        INTO l_params
        FROM (SELECT 0                                           AS id,
                     to_jsonb(v_mk)                              AS data,
                     jsonb_object_agg('gridData', l_grid_params) AS "gridData") qry;

        -- save results
        l_dok_id = docs.sp_salvesta_mk(
                l_params :: JSON,
                user_id,
                v_po.rekvid);

        IF l_dok_id IS NOT NULL AND l_dok_id > 0
        THEN
            -- добавим ссылку на PO

            SELECT docs_ids
            INTO ids
            FROM docs.doc
            WHERE id = l_dok_id;

            ids = ids || l_journal_ids || l_po_ids;

            UPDATE docs.doc
            SET docs_ids = ids
            WHERE id = l_dok_id;

            -- добавим ссылку на VMK / Vorder
            UPDATE docs.doc
            SET docs_ids = array_append(docs_ids, l_dok_id)
            WHERE id IN (SELECT unnest(l_po_ids));

            result = coalesce(result, 0) + 1;
        END IF;


    END IF;

    IF (coalesce(result, 0)) = 0
    THEN
        -- empty result
        l_params = to_jsonb(row.*)
                   FROM (
                            SELECT NULL                    AS doc_id,
                                   'Kehtiv makseid ei ole' AS error_message,
                                   0::INTEGER              AS error_code
                        ) row;
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

    END IF;
    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            IF v_tulemus IS NULL
            THEN
                SELECT '' AS error_message, 0 AS error_code INTO v_tulemus;
            END IF;
            v_tulemus.error_message = v_tulemus.error_message || SQLERRM;
            v_tulemus.error_code = 1;
            l_params = to_jsonb(v_tulemus);
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
            RETURN;
END;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.gen_palk_dok(user_id INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_palk_dok(user_id INTEGER, params JSON) TO dbpeakasutaja;

/*

select palk.gen_palk_dok(31, '{"isik_ids":[25531],
		"osakond_ids":null,
		"lib_ids":null,"kpv":20230131}'::json)




*/