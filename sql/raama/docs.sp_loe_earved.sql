DROP FUNCTION IF EXISTS docs.sp_loe_earved(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.sp_loe_earved(IN l_user_id INTEGER, l_arved jsonb,
                                              OUT error_code INTEGER,
                                              OUT result INTEGER,
                                              OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_arv             RECORD; -- е-счет в формате json
    v_arv_details     record;
    v_arv_journal     record;
    l_doc             jsonb;
    l_rekv_id         integer;
    l_virtual_user_id integer = l_user_id; -- подменим на виртуального робота
    l_json_doc        jsonb   = '{}'::jsonb;
    l_json_details    jsonb   = '[]'::jsonb;
    l_asutus_id       integer;
    l_dokprop_id      integer;
    l_korr_konto      text;
    l_nom_id          integer;
    l_doc_id          integer;
    l_bpm_json        jsonb   = '[]'::jsonb;
    l_doc_details     jsonb   = '[]'::jsonb;
    l_kood            text;
    l_log_id          integer;
    l_log_changes     jsonb   = '[]'::jsonb;

BEGIN

    -- проверка размерности массива
    IF l_arved is null or jsonb_array_length(l_arved) = 0
    THEN
        -- нет счетов, выходим
        result = 0;
        error_message = 'Arved ei ole';
        RETURN;
    END IF;

    -- проверка пользователя
    select
        u.rekvid
    into l_rekv_id
    from
        ou.userid u
    where
          u.id = l_user_id
      and (u.roles ->> 'is_kasutaja')::boolean
      and u.status < 3;

    if l_rekv_id is null then
        -- нет прав, выходим
        result = 0;
        error_message = 'Puudub õigused';
        RETURN;
    end if;

    if (
           select
               kasutaja
           from
               ou.userid
           where
               id = l_user_id
       ) in ('vlad', 'temp')
    then
        -- ищем пользователя робот
        select
            id
        into l_virtual_user_id
        from
            ou.userid
        where
              rekvid = l_rekv_id
          and status < 3
          and kasutaja ilike '%robot%'
        order by id desc
        limit 1;
    end if;

    l_virtual_user_id = coalesce(l_virtual_user_id, l_user_id);

    -- logs
    insert into ou.logs (rekvid, user_id, propertis)
    values (l_rekv_id, l_virtual_user_id, jsonb_build_object('e-arve', l_arved))
    returning id into l_log_id;

    -- проходим по массиву счетов
    FOR v_arv IN SELECT doc FROM jsonb_array_elements(l_arved) AS doc
        LOOP
            -- Извлекаем поля шапки документа
            l_doc = v_arv.doc -> 'data';

            -- ищем счет в бд
            -- 	Locate For Alltrim(Upper(Number)) = Alltrim(Upper(v_xml_arv.Number)) and YEAR(tmpArved.kpv) = YEAR(v_xml_arv.kpv) ;
            -- 		AND ALLTRIM(tmpArved.regkood) = ALLTRIM(v_xml_arv.regkood)
            if exists
            (
                select
                    a.id
                from
                    docs.arv                   arv
                        inner join libs.asutus a on a.id = arv.asutusid
                where
                      arv.number = l_doc ->> 'number'
                  and arv.rekvid = l_rekv_id
                  and year((l_doc ->> 'kpv')::date) = year(arv.kpv)
                  and a.regkood = ALLTRIM(l_doc ->> 'asutusid')
            ) then
                -- счет уже импортирован, пропускам
                continue ;
            end if;
            -- ищем в бд контрагента
            l_asutus_id = (
                              select
                                  id
                              from
                                  libs.asutus a
                              where
                                    a.regkood = ALLTRIM(l_doc ->> 'asutusid')
                                and a.staatus < 3
                              order by id desc
                              limit 1
                          );
            if l_asutus_id is null then
                raise exception 'Viga: asutus ei leidnud, regkood %', (l_doc ->> 'asutusid');
            end if;

            -- ищем корр счета и параметры для контирования
            l_korr_konto = l_doc ->> 'korr_konto';
            if l_korr_konto is null then
                l_korr_konto = coalesce(l_doc -> 'gridData' -> '0' ->> 'korr_konto', '201000');
            end if;

            l_json_details = l_doc -> 'gridData';

            FOR v_arv_details IN SELECT arv_rea FROM jsonb_array_elements(l_json_details) AS arv_rea
                loop
                    IF v_arv_details.arv_rea -> 'Accounting' -> 'JournalEntry' IS NOT NULL
                        AND jsonb_typeof(v_arv_details.arv_rea -> 'Accounting' -> 'JournalEntry') = 'array' THEN
                        FOR v_arv_journal in SELECT
                                                 arv_journal
                                             FROM
                                                 jsonb_array_elements(v_arv_details.arv_rea -> 'Accounting' -> 'JournalEntry') AS arv_journal
                            loop
                            -- разбираем классификаторы
                            -- 1.  kas artikkel  v_arv_journal {"Sum": "23.8", "CostObjective": "LE-P", "GeneralLedger": "550010"}
                                l_kood = v_arv_journal.arv_journal ->> 'CostObjective';
                                if exists
                                (
                                    select
                                        id
                                    from
                                        libs.library l
                                    where
                                          l.kood = l_kood
                                      and l.status < 3
                                      and l.library = 'TULUDEALLIKAD'
                                ) then
                                    -- artikkel
                                    v_arv_details.arv_rea =
                                            v_arv_details.arv_rea::jsonb || jsonb_build_object('kood5', l_kood);
                                elsif
                                    --tegev
                                    exists
                                    (
                                        select
                                            id
                                        from
                                            libs.library l
                                        where
                                              l.kood = l_kood
                                          and l.status < 3
                                          and l.library = 'TEGEV'
                                    ) then
                                    v_arv_details.arv_rea =
                                            v_arv_details.arv_rea::jsonb || jsonb_build_object('kood1', l_kood);
                                elsif
                                    --allikas
                                    exists
                                    (
                                        select
                                            id
                                        from
                                            libs.library l
                                        where
                                              l.kood = l_kood
                                          and l.status < 3
                                          and l.library = 'ALLIKAD'
                                    ) then
                                    v_arv_details.arv_rea =
                                            v_arv_details.arv_rea::jsonb || jsonb_build_object('kood2', l_kood);

                                elsif
                                    --rahavoog
                                    exists
                                    (
                                        select
                                            id
                                        from
                                            libs.library l
                                        where
                                              l.kood = l_kood
                                          and l.status < 3
                                          and l.library = 'RAHA'
                                    ) then
                                    v_arv_details.arv_rea =
                                            v_arv_details.arv_rea::jsonb || jsonb_build_object('kood3', l_kood);

                                elsif
                                    --tunnus
                                    exists
                                    (
                                        select
                                            id
                                        from
                                            libs.library l
                                        where
                                              l.kood = l_kood
                                          and l.status < 3
                                          and l.library = 'TUNNUS'
                                          and l.rekvid = l_rekv_id
                                    ) then
                                    v_arv_details.arv_rea =
                                            v_arv_details.arv_rea::jsonb || jsonb_build_object('tunnus', l_kood);
                                elsif
                                    --PROJ
                                    exists
                                    (
                                        select
                                            id
                                        from
                                            libs.library l
                                        where
                                              l.kood = l_kood
                                          and l.status < 3
                                          and l.library = 'PROJ'
                                          and l.rekvid = l_rekv_id
                                    ) then
                                    v_arv_details.arv_rea =
                                            v_arv_details.arv_rea::jsonb || jsonb_build_object('proj', l_kood);

                                elsif
                                    --uritus
                                    exists
                                    (
                                        select
                                            id
                                        from
                                            libs.library l
                                        where
                                              l.kood = l_kood
                                          and l.status < 3
                                          and l.library = 'URITUS'
                                          and l.rekvid = l_rekv_id
                                    ) then
                                    v_arv_details.arv_rea =
                                            v_arv_details.arv_rea::jsonb || jsonb_build_object('kood4', l_kood);
                                elsif
                                    --objekt
                                    exists
                                    (
                                        select
                                            id
                                        from
                                            libs.library l
                                        where
                                              l.kood = l_kood
                                          and l.status < 3
                                          and l.library = 'OBJEKT'
                                          and l.rekvid = l_rekv_id
                                    ) then
                                    v_arv_details.arv_rea =
                                            v_arv_details.arv_rea::jsonb || jsonb_build_object('objekt', l_kood);

                                elsif
                                    --TP
                                    exists
                                    (
                                        select
                                            id
                                        from
                                            libs.library l
                                        where
                                              l.kood = l_kood
                                          and l.status < 3
                                          and l.library = 'TP'
                                    ) then
                                    v_arv_details.arv_rea =
                                            v_arv_details.arv_rea::jsonb || jsonb_build_object('tp', l_kood);

                                end if;
                            end loop;
                    END IF;
                    l_doc_details = coalesce(l_doc_details, '[]')::jsonb || v_arv_details.arv_rea;
                end loop;


            if l_nom_id is null then
                l_nom_id = (
                               select
                                   id
                               from
                                   libs.nomenklatuur n
                               where
                                     n.rekvid = l_rekv_id
                                 and n.status < 3
                                 and n.dok = 'ARV'
                                 AND n.kood = 'OMNIVA'
                               order by id desc
                               limit 1
                           );
            end if;

            if l_nom_id is null then
                raise exception 'Viga: nomenklatuuri kood OMNIVA ei leidnud %', l_nom_id;
            end if;


            l_dokprop_id = (
                               select
                                   dp.id
                               from
                                   libs.dokprop dp
                               where
                                     dp.rekvid = l_rekv_id
                                 and parentid = 53 -- arve
                                 and registr = 1 -- ищем счета под регистрацию проводки
                                 and status < 3 -- не удаленные
                                 and details ->> 'konto' = l_korr_konto
                               order by id desc
                               limit 1
                           );

            -- собираем параметры для сохранения

            l_json_doc = jsonb_build_object('id', 0,
                                            'number', l_doc ->> 'number',
                                            'summa', l_doc -> 'summa',
                                            'kbmta', l_doc -> 'kbmta',
                                            'kbm', l_doc -> 'kbm',
                                            'liik', 1,
                                            'kpv', (l_doc ->> 'kpv')::date,
                                            'tahtaeg', (l_doc ->> 'tahtaeg')::date,
                                            'asutusid', l_asutus_id,
                                            'aa', l_doc ->> 'aa',
                                            'lisa', l_doc ->> 'lisa',
                                            'viitenr', l_doc ->> 'viitenr',
                                            'doklausid', l_dokprop_id,
                                            'gridData', l_doc_details);

            l_doc_id =
                    docs.sp_salvesta_arv(jsonb_build_object('id', 0, 'data', l_json_doc::JSON)::json, l_virtual_user_id,
                                         l_rekv_id);

            if coalesce(l_doc_id, 0) > 0 then
                PERFORM docs.gen_lausend_arv(l_doc_id, l_virtual_user_id);

                -- сохраним bpm omniva
                l_bpm_json = l_doc -> 'bpm';
                IF l_bpm_json IS NOT NULL AND jsonb_typeof(l_bpm_json) = 'array' AND
                   jsonb_array_length(l_bpm_json) > 0 THEN
                    PERFORM docs.sp_update_doc_bpm_data(l_doc_id::INTEGER, l_virtual_user_id::INTEGER,
                                                        jsonb_build_object('omniva', l_bpm_json));
                END IF;
            end if;
            l_log_changes = l_log_changes::jsonb || jsonb_build_object('doc_id', l_doc_id, 'doc', l_json_doc);
            error_message =
                    coalesce(error_message, '') || 'Arve nr.' || (l_doc ->> 'number')::text || ' importeeritud' + '\r';
            l_doc_details = '[]'::jsonb;
            l_json_doc = null;
        END LOOP;
    update ou.logs set changes = l_log_changes where id = l_log_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_loe_earved(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_earved(INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_earved(INTEGER, JSONB) TO arvestaja;

COMMENT ON FUNCTION docs.sp_loe_earved(INTEGER, JSONB) IS 'парсит jsonb массив счетов и сохраняет счета в бд';
