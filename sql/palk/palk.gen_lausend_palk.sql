DROP FUNCTION IF EXISTS palk.gen_lausend_palk(INTEGER, JSON);

CREATE OR REPLACE FUNCTION palk.gen_lausend_palk(IN user_id INTEGER, IN params JSON, OUT result INTEGER,
                                                 OUT error_code INTEGER, OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_palkoper_id             INTEGER = params ->> 'id';
    l_db_konto                TEXT;
    l_kr_konto                TEXT;
    l_db_parallel_konto       TEXT;
    l_kr_parallel_konto       TEXT;
    l_lisa_selg               text    = '';
    l_parallel_lausend_id     integer;
    l_db_tp                   TEXT    = '800699';
    l_kr_tp                   TEXT    = '800699';
    v_palk_oper               RECORD;
    v_user                    RECORD;
    v_journal                 RECORD;
    v_journal1                RECORD;
    l_json                    JSON;
    new_history               JSONB;
    a_docs_ids                INTEGER[];
    DEKLAREERIMATA_SM_KONTO   text    = '202001';
    DEKLAREERIMATA_TM_KONTO   text    = '202002';
    DEKLAREERIMATA_TK_KONTO   text    = '202003';
    DEKLAREERIMATA_PM_KONTO   text    = '202004';
    ETTEMAKSU_KONTO           text    = '103930';
    SOTSMAKSU_ETTEMAKSU_KONTO TEXT    = '103931';
    TK_ETTEMAKSU_KONTO        TEXT    = '103932';
    l_ettemaksu_summa         numeric = 0;
    l_kpv                     date;
    kas_ettemaks              boolean = false;
BEGIN

    IF coalesce(l_palkoper_id, 0) = 0
    THEN
        error_code = 1;
        error_message = 'Puudub dokument';
        RETURN;
    END IF;


    SELECT
        kasutaja,
        rekvid
    INTO v_user
    FROM
        ou.userid u
    WHERE
        u.id = user_Id;

    IF v_user.kasutaja IS NULL
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        raise exception 'Viga: %', error_message;
    END IF;

    IF l_palkoper_id IS NULL
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad';
        result = 0;
        raise exception 'Viga: %', error_message;
--        RETURN;

    END IF;

    SELECT
        po.*,
        po.libid
    INTO v_palk_oper
    FROM
        palk.cur_palk_oper_lausend    po
            inner join palk.palk_oper po2 on po.id = po2.parentid
    WHERE
        po.id = l_palkoper_id;

    l_db_tp = v_palk_oper.tp;
    l_kr_tp = v_palk_oper.tp;


    IF v_palk_oper.dokpropid = 0 OR v_palk_oper.summa = 0
    THEN
        error_message = 'Konteerimine ei ole vajalik, dok tyyp ei ole defineeritud voi summa = 0 ';
        result = 1;
        RETURN;
    END IF;

    IF NOT v_palk_oper.kas_registreerida
    THEN
        error_message = 'Konteerimine ei ole vajalik';
        result = 1;
        RETURN;
    END IF;

    CASE
        WHEN v_palk_oper.palk_liik = 'ARVESTUSED'
            THEN --arv
            l_db_konto = v_palk_oper.konto;
            l_kr_konto = v_palk_oper.base_konto;

            if v_palk_oper.kas_ettemaks then
                -- puhkuse ettemaks, kasutame konto 103930
                l_db_konto = ETTEMAKSU_KONTO;
                l_db_parallel_konto = v_palk_oper.konto;
                l_kr_parallel_konto = ETTEMAKSU_KONTO;
            end if;

        WHEN v_palk_oper.palk_liik = 'KINNIPIDAMISED'
            THEN -- kinni
            l_kr_konto = v_palk_oper.konto;
            l_db_konto = v_palk_oper.base_konto;
            l_db_tp := v_palk_oper.tp;
        WHEN v_palk_oper.palk_liik = 'TULUMAKS'
            THEN -- tulumaks
            l_kr_konto := v_palk_oper.konto;
            l_db_konto := v_palk_oper.base_konto;

            if v_palk_oper.makse_paev is not null and
               get_last_day(v_palk_oper.makse_paev) > get_last_day(v_palk_oper.kpv) then
                -- не декларированные суммы
                l_kr_parallel_konto = v_palk_oper.konto;
                l_db_parallel_konto = DEKLAREERIMATA_TM_KONTO;
                l_kr_konto = DEKLAREERIMATA_TM_KONTO;
                l_lisa_selg = ' (Deklareerimata summa)';
            end if;
        WHEN v_palk_oper.palk_liik = 'SOTSMAKS'
            THEN -- sotsmaks
            l_kr_konto := v_palk_oper.korr_konto;
            l_db_konto := v_palk_oper.konto;

            if v_palk_oper.makse_paev is not null and
               get_last_day(v_palk_oper.makse_paev) > get_last_day(v_palk_oper.kpv) then
                -- не декларированные суммы
                l_kr_parallel_konto = v_palk_oper.korr_konto;
                l_db_parallel_konto = DEKLAREERIMATA_SM_KONTO;
                l_kr_konto := DEKLAREERIMATA_SM_KONTO;
                l_lisa_selg = ' (Deklareerimata summa)';

            end if;

            if v_palk_oper.kas_ettemaks then
                -- puhkuse ettemaks, kasutame konto 103932
                l_db_konto = SOTSMAKSU_ETTEMAKSU_KONTO;
                l_db_parallel_konto = v_palk_oper.konto;
                l_kr_parallel_konto = SOTSMAKSU_ETTEMAKSU_KONTO;
            end if;

        WHEN v_palk_oper.palk_liik = 'TASU'
            THEN -- tasu
            l_kr_konto := v_palk_oper.konto;
            l_db_konto := v_palk_oper.base_konto;
            l_kr_tp := (
                           SELECT
                               tp
                           FROM
                               ou.aa
                           WHERE
                                 parentid = v_palk_oper.rekvId
                             AND kassa = 1
                           ORDER BY default_ DESC
                           LIMIT 1
                       );
            l_db_tp := v_palk_oper.tp;

            IF left(l_kr_konto, 6) = '100000'
            THEN
                l_kr_tp := '';
            END IF;
        WHEN v_palk_oper.palk_liik = 'TÖÖTUSKINDLUSTUSMAKS' AND v_palk_oper.kas_asutusest
            THEN --TKA

            l_kr_konto := v_palk_oper.korr_konto;
            l_db_konto := v_palk_oper.konto;

            if v_palk_oper.makse_paev is not null and
               get_last_day(v_palk_oper.makse_paev) > get_last_day(v_palk_oper.kpv) then
                -- не декларированные суммы
                l_db_parallel_konto = DEKLAREERIMATA_TK_KONTO;
                l_kr_parallel_konto = v_palk_oper.korr_konto;
                l_kr_konto := DEKLAREERIMATA_TK_KONTO;
                l_lisa_selg = ' (Deklareerimata summa)';

            end if;

            if v_palk_oper.kas_ettemaks then
                -- puhkuse ettemaks, kasutame konto 103930
                l_db_konto = TK_ETTEMAKSU_KONTO;
                l_db_parallel_konto = v_palk_oper.konto;
                l_kr_parallel_konto = TK_ETTEMAKSU_KONTO;
            end if;


        WHEN v_palk_oper.palk_liik = 'TÖÖTUSKINDLUSTUSMAKS' AND NOT v_palk_oper.kas_asutusest
            THEN -- tookindl isik
            l_kr_konto := v_palk_oper.konto;
            l_db_konto := v_palk_oper.base_konto;

            if v_palk_oper.makse_paev is not null and
               get_last_day(v_palk_oper.makse_paev) > get_last_day(v_palk_oper.kpv) then
                -- не декларированные суммы
                l_db_parallel_konto = DEKLAREERIMATA_TK_KONTO;
                l_kr_parallel_konto = v_palk_oper.konto;
                l_kr_konto := DEKLAREERIMATA_TK_KONTO;
                l_lisa_selg = ' (Deklareerimata summa)';

            end if;

        WHEN v_palk_oper.palk_liik = 'PENSIONIMAKS'
            THEN -- pensmaks
            l_kr_konto := v_palk_oper.konto;
            l_db_konto := v_palk_oper.base_konto;

            if v_palk_oper.makse_paev is not null and
               get_last_day(v_palk_oper.makse_paev) > get_last_day(v_palk_oper.kpv) then
                -- не декларированные суммы
                l_db_parallel_konto = DEKLAREERIMATA_PM_KONTO;
                l_kr_parallel_konto = v_palk_oper.konto;
                l_kr_konto := DEKLAREERIMATA_PM_KONTO;
                l_lisa_selg = ' (Deklareerimata summa)';

            end if;

        END CASE;

    CASE
        WHEN left(l_kr_konto, 3) = '203' AND l_kr_konto <> '203690'
            THEN l_kr_tp := '014001';
        WHEN l_kr_konto = '203690'
            THEN l_kr_tp := '800399';
        WHEN l_kr_konto = '203640'
            THEN l_kr_tp := '800699';
        ELSE
        END CASE;

    IF l_db_konto = '103560'
    THEN
        l_db_tp := '016001';
    END IF;

    -- запомним переменные (отпуск) для дальнейшей обработки
    l_kpv = v_palk_oper.kpv;
    kas_ettemaks = v_palk_oper.kas_ettemaks;

    if v_palk_oper.kohustuse_kpv is not null and
       get_last_day(v_palk_oper.kohustuse_kpv) < get_last_day(v_palk_oper.kpv) then
        -- имеется признак предоплаты. подменяем дату и назначаем операцию предоплатой
        l_kpv = v_palk_oper.kohustuse_kpv;
        kas_ettemaks = true;
    end if;

    -- если расчет датирован периодом позже, т.е. выплата в следующем месяце, расход должен быть отражен все таки в том периоде, на который он приходится
-- Изменить в Päevaraamat дату расходов для первого месяца отпуска
    if not kas_ettemaks and v_palk_oper.ettemaksu_periood is not null and
       v_palk_oper.kpv > v_palk_oper.ettemaksu_periood then
        l_kpv = v_palk_oper.ettemaksu_periood;
    end if;


    -- готовим параметры
    SELECT
        v_palk_oper.journalid                            AS id,
        'JOURNAL'                                        AS doc_type_id,
        l_kpv                                            AS kpv,
        coalesce(v_palk_oper.selg, 'PALK') + l_lisa_selg AS selg,
        v_palk_oper.muud                                 AS muud,
        v_palk_oper.isikId                               AS asutusid
    INTO v_journal;

    SELECT
        0                                                  AS id,
        coalesce(v_palk_oper.summa, 0) - l_ettemaksu_summa AS summa,
        l_db_konto                                         AS deebet,
        l_db_tp                                            AS lisa_d,
        l_kr_konto                                         AS kreedit,
        l_kr_tp                                            AS lisa_k,
        v_palk_oper.tunnus                                 AS tunnus,
        coalesce(v_palk_oper.proj, '')                     AS proj,
        coalesce(v_palk_oper.kood1, '')                    AS kood1,
        coalesce(v_palk_oper.kood2, '')                    AS kood2,
        coalesce(v_palk_oper.kood3, '')                    AS kood3,
        coalesce(v_palk_oper.kood4, '')                    AS kood4,
        coalesce(v_palk_oper.kood5, '')                    AS kood5,
        coalesce(v_palk_oper.objekt, '')                   AS objekt
    INTO v_journal1;

    l_json = ('{"data":' || trim(TRAILING FROM (row_to_json(v_journal))::TEXT, '}') :: TEXT || ',"gridData":[' ||
              (row_to_json(v_journal1)) || ']}}');

    /* salvestan lausend */

    if v_journal1.summa <> 0 then
        result = docs.sp_salvesta_journal(l_json :: JSON, user_id, v_palk_oper.rekvId);
    end if;

    IF result IS NOT NULL AND result > 0
    THEN
        /*
        ajalugu
        */

        SELECT
            row_to_json(row)
        INTO new_history
        FROM
            (
                SELECT
                    now()           AS updated,
                    v_user.kasutaja AS user
            ) row;

        -- will add docs into doc's pull
        -- arve

        UPDATE docs.doc
        SET
            docs_ids   = array(SELECT DISTINCT unnest(array_append(v_palk_oper.docs_ids, result))),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || new_history
        WHERE
            id = v_palk_oper.parentId;

        -- lausend
        SELECT
            docs_ids
        INTO a_docs_ids
        FROM
            docs.doc
        WHERE
            id = result;

        -- add new id into docs. ref. array
        a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_palk_oper.parentId)));

        UPDATE docs.doc
        SET
            docs_ids = a_docs_ids
        WHERE
            id = result;

        -- сохраним ссылку на основную проводку
        UPDATE palk.palk_oper
        SET
            journalId = result
        WHERE
            parentid = v_palk_oper.id;

        -- если не декларируемый налог, то делаем параллельную проводку
        if v_palk_oper.makse_paev is not null and
           get_last_day(v_palk_oper.makse_paev) > get_last_day(v_palk_oper.kpv) and
           l_db_parallel_konto is not null then

            CASE
                WHEN left(l_kr_parallel_konto, 3) = '203' AND l_kr_parallel_konto <> '203690'
                    THEN l_kr_tp := '014001';
                WHEN l_kr_parallel_konto = '203690'
                    THEN l_kr_tp := '800399';
                WHEN l_kr_parallel_konto = '203640'
                    THEN l_kr_tp := '800699';
                END CASE;


            -- готовим параметры
            SELECT
                coalesce(v_palk_oper.parallel_lausend_id, 0) AS id,
                'JOURNAL'                                    AS doc_type_id,
                v_palk_oper.makse_paev                       AS kpv,
                coalesce(v_palk_oper.selg, 'PALK')           AS selg,
                'Parallel lausend'                           AS muud,
                v_palk_oper.isikId                           AS asutusid
            INTO v_journal;

            SELECT
                0                                AS id,
                coalesce(v_palk_oper.summa, 0)   AS summa,
                l_db_parallel_konto              AS deebet,
                '800699'                         AS lisa_d,
                l_kr_parallel_konto              AS kreedit,
                l_kr_tp                          AS lisa_k,
                v_palk_oper.tunnus               AS tunnus,
                coalesce(v_palk_oper.proj, '')   AS proj,
                coalesce(v_palk_oper.kood1, '')  AS kood1,
                coalesce(v_palk_oper.kood2, '')  AS kood2,
                coalesce(v_palk_oper.kood3, '')  AS kood3,
                coalesce(v_palk_oper.kood4, '')  AS kood4,
                coalesce(v_palk_oper.kood5, '')  AS kood5,
                coalesce(v_palk_oper.objekt, '') AS objekt
            INTO v_journal1;

            l_json =
                    ('{"data":' || trim(TRAILING FROM (row_to_json(v_journal))::TEXT, '}') :: TEXT || ',"gridData":[' ||
                     (row_to_json(v_journal1)) || ']}}');

            /* salvestan lausend */
            l_parallel_lausend_id = docs.sp_salvesta_journal(l_json :: JSON, user_id, v_palk_oper.rekvId);

            IF l_parallel_lausend_id IS NOT NULL AND l_parallel_lausend_id > 0
            THEN
                update palk.palk_oper
                set
                    properties = properties || jsonb_build_object('parallel_lausedn_id', l_parallel_lausend_id)
                where
                    parentid = l_palkoper_id;

                -- пропишем зависимости
                SELECT
                    docs_ids
                INTO a_docs_ids
                FROM
                    docs.doc
                WHERE
                    id = l_parallel_lausend_id;

                -- add new id into docs. ref. array
                a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_palk_oper.parentId)));

                UPDATE docs.doc
                SET
                    docs_ids = a_docs_ids
                WHERE
                    id = l_parallel_lausend_id;

            end if;

        end if;

        -- делаем проводку на сумму предоплаты
        -- если предоплата (ртпуск) др доп. проводка
        if kas_ettemaks and l_db_parallel_konto is not null and
           v_palk_oper.ettemaksu_periood is not null then

            CASE
                WHEN left(l_kr_parallel_konto, 3) = '203' AND l_kr_parallel_konto <> '203690'
                    THEN l_kr_tp := '014001';
                WHEN l_kr_parallel_konto = '203690'
                    THEN l_kr_tp := '800399';
                WHEN l_kr_parallel_konto = '203640'
                    THEN l_kr_tp := '800699';
                ELSE l_kr_tp := '800699';
                END CASE;

            -- готовим параметры
            SELECT
                coalesce(v_palk_oper.parallel_lausend_id, 0) AS id,
                'JOURNAL'                                    AS doc_type_id,
                v_palk_oper.ettemaksu_periood                AS kpv,
                coalesce(v_palk_oper.selg, 'PALK')           AS selg,
                'Parallel lausend'                           AS muud,
                v_palk_oper.isikId                           AS asutusid
            INTO v_journal;

            SELECT
                0                                AS id,
                coalesce(v_palk_oper.summa, 0)   AS summa,
                l_db_parallel_konto              AS deebet,
                '800699'                         AS lisa_d,
                l_kr_parallel_konto              AS kreedit,
                l_kr_tp                          AS lisa_k,
                v_palk_oper.tunnus               AS tunnus,
                coalesce(v_palk_oper.proj, '')   AS proj,
                coalesce(v_palk_oper.kood1, '')  AS kood1,
                coalesce(v_palk_oper.kood2, '')  AS kood2,
                coalesce(v_palk_oper.kood3, '')  AS kood3,
                coalesce(v_palk_oper.kood4, '')  AS kood4,
                coalesce(v_palk_oper.kood5, '')  AS kood5,
                coalesce(v_palk_oper.objekt, '') AS objekt
            INTO v_journal1;

            l_json =
                    ('{"data":' || trim(TRAILING FROM (row_to_json(v_journal))::TEXT, '}') :: TEXT ||
                     ',"gridData":[' ||
                     (row_to_json(v_journal1)) || ']}}');

            /* salvestan lausend */
            l_parallel_lausend_id = docs.sp_salvesta_journal(l_json :: JSON, user_id, v_palk_oper.rekvId);

            IF l_parallel_lausend_id IS NOT NULL AND l_parallel_lausend_id > 0
            THEN
                update palk.palk_oper
                set
                    properties = properties || jsonb_build_object('parallel_lausedn_id', l_parallel_lausend_id)
                where
                    parentid = l_palkoper_id;

                -- пропишем зависимости
                SELECT
                    docs_ids
                INTO a_docs_ids
                FROM
                    docs.doc
                WHERE
                    id = l_parallel_lausend_id;

                -- add new id into docs. ref. array
                a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, v_palk_oper.parentId)));

                UPDATE docs.doc
                SET
                    docs_ids = a_docs_ids
                WHERE
                    id = l_parallel_lausend_id;

            end if;

        end if;

    else
        raise exception 'Viga: konteerimise viga';

    END IF;
    RETURN;
END;

$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.gen_lausend_palk(INTEGER, JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_lausend_palk(INTEGER, JSON) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_lausend_palk(INTEGER, JSON) TO taabel;

/*
SELECT palk.gen_lausend_palk_(2477, '{"id": 1427}' :: JSON)
*/