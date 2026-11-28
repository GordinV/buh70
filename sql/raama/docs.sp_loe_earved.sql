DROP FUNCTION IF EXISTS docs.sp_loe_earved(INTEGER, JSONB);

-- Новые выходные параметры (добавлены к существующим, старые вызовы SELECT * продолжают работать):
--   imported - [{doc_id, number, rekv_id}] только реально созданные документы (по нему работает docs.get_arve_kinnitaja)
--   errors   - [{number, asutusid, error}] счета, которые не удалось импортировать (ошибка одного счета не откатывает остальные)
CREATE OR REPLACE FUNCTION docs.sp_loe_earved(IN l_user_id INTEGER, l_arved jsonb,
                                              OUT error_code INTEGER,
                                              OUT result INTEGER,
                                              OUT error_message TEXT,
                                              OUT imported jsonb,
                                              OUT errors jsonb)
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
    error_code = 0;
    result = 0;
    imported = '[]'::jsonb;
    errors = '[]'::jsonb;

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
        error_code = 4;
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
            -- Подтранзакция на каждый счет: ошибка одного счета не откатывает импорт остальных
            BEGIN
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
                      and arv.liik = 1
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
                                                -- rekv_regkood (BuyerRegNumber) не передаем: покупатель = учреждение выкачки,
                                                -- счета часто выставлены на регкод вышестоящего (проверка 'vale asutus' их бы отвергла)
                                                'doklausid', l_dokprop_id,
                                                'gridData', l_doc_details);

                l_doc_id =
                        docs.sp_salvesta_arv(jsonb_build_object('id', 0, 'data', l_json_doc::JSON)::json,
                                             l_virtual_user_id,
                                             l_rekv_id);

                if coalesce(l_doc_id, 0) <= 0 then
                    -- счет не сохранен: считаем ошибкой (документ не создан), а не "importeeritud (id: 0)"
                    raise exception 'Viga: arve ei salvestatud (docs.sp_salvesta_arv tagastas %)', coalesce(l_doc_id, 0);
                end if;

                PERFORM docs.gen_lausend_arv(l_doc_id, l_virtual_user_id);

                -- сохраним bpm omniva
                l_bpm_json = l_doc -> 'bpm';
                IF l_bpm_json IS NOT NULL AND jsonb_typeof(l_bpm_json) = 'array' AND
                   jsonb_array_length(l_bpm_json) > 0 THEN
                    PERFORM docs.sp_update_doc_bpm_data(l_doc_id::INTEGER, l_virtual_user_id::INTEGER,
                                                        jsonb_build_object('omniva', l_bpm_json));
                END IF;

                -- счет полностью импортирован (документ, проводка, bpm): фиксируем в результате
                imported = imported || jsonb_build_array(
                        jsonb_build_object('doc_id', l_doc_id, 'number', l_doc ->> 'number', 'rekv_id', l_rekv_id));
                l_log_changes = l_log_changes::jsonb || jsonb_build_object('doc_id', l_doc_id, 'doc', l_json_doc);
                error_message =
                        coalesce(error_message, '') || 'Arve nr.' || coalesce((l_doc ->> 'number')::text, '') ||
                        ' importeeritud (id: ' || l_doc_id::text || '); ';
                l_doc_details = '[]'::jsonb;
                l_json_doc = null;
            EXCEPTION
                WHEN OTHERS THEN
                    -- изменения этого счета откатываются, переменные цикла сбрасываем вручную
                    l_doc_details = '[]'::jsonb;
                    l_json_doc = null;
                    errors = errors || jsonb_build_array(
                            jsonb_build_object('number', v_arv.doc -> 'data' ->> 'number',
                                               'asutusid', v_arv.doc -> 'data' ->> 'asutusid',
                                               'rekv_id', l_rekv_id,
                                               -- бухгалтер из BPM счета (последний согласующий): получает копию письма об ошибке
                                               'raamatupidaja', nullif(btrim(
                                                       CASE
                                                           WHEN jsonb_typeof(v_arv.doc -> 'data' -> 'bpm') = 'array'
                                                               THEN v_arv.doc -> 'data' -> 'bpm' -> -1 ->> 'isik'
                                                       END), ''),
                                               'error', SQLERRM));
                    error_message = coalesce(error_message, '') || 'Arve nr.' ||
                                    coalesce(v_arv.doc -> 'data' ->> 'number', '') || ' viga: ' || SQLERRM || '; ';
            END;
        END LOOP;

    -- result = число реально созданных документов (инкремент внутри подтранзакции не годится: при откате переменная не откатывается)
    result = jsonb_array_length(imported);

    update ou.logs set changes = l_log_changes where id = l_log_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_loe_earved(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_earved(INTEGER, JSONB) TO dbpeakasutaja;
-- роль arvestaja не имеет права создавать счета: EXECUTE ей не выдается

COMMENT ON FUNCTION docs.sp_loe_earved(INTEGER, JSONB) IS 'парсит jsonb массив счетов и сохраняет счета в бд';

/*
 SELECT *
FROM docs.sp_loe_earved(
    5429,
    $$[
      {
        "id": 0,
        "data": {
          "aa": "EE652200221027849230",
          "id": 0,
          "bpm": [
            {"kpv": "2026-11-27", "isik": "NATALJA NETŠAJEVA", "rolli": "creator"},
            {"kpv": "2026-11-25 16:43:14", "isik": "ANNA ZUBOVA", "rolli": "VERIFIED"},
            {"kpv": "2026-11-27 11:39:35", "isik": "JELENA VEREŠTŠAGINA", "rolli": "VERIFIED"}
          ],
          "doc": "",
          "kbm": 0,
          "kpv": "20261127",
          "jaak": 0,
          "kmkr": "",
          "liik": 1,
          "lisa": "",
          "muud": "",
          "tyyp": "",
          "arvid": 0,
          "kbmta": 510,
          "konto": "",
          "summa": 510,
          "tasud": "        ",
          "asutus": "",
          "number": "82020126240",
          "objekt": "0921201",
          "operid": 0,
          "rekvid": 106,
          "status": "",
          "userid": 5429,
          "aadress": "",
          "created": "",
          "dokprop": "",
          "laus_nr": 0,
          "regkood": "",
          "tahtaeg": "20261130",
          "tasudok": "",
          "viitenr": "8202017",
          "asutusid": 75024314,
          "gridData": [
            {
              "id": 0,
              "km": "0",
              "tp": "800599",
              "kbm": 0,
              "hind": 510,
              "kood": "",
              "muud": "20.11.2026 Narva Kesklinna Kool  juubelikontserdi proov. Vaatesaali rent, kell 10.00-15.30",
              "proj": "",
              "uhik": "",
              "kbmta": 510,
              "kogus": 1,
              "konto": "552520",
              "kood1": "09212",
              "kood2": "LE-P",
              "kood3": "",
              "kood4": "",
              "kood5": "5525",
              "kuurs": 0,
              "nomid": 17748,
              "summa": 510,
              "objekt": "0921201",
              "soodus": 0,
              "tunnus": "",
              "userid": 0,
              "formula": "",
              "nimetus": "20.11.2026 Narva Kesklinna Kool  juubelikontserdi proov. Vaatesaali rent, kell 10.00-15.30",
              "valuuta": "",
              "vastisik": "",
              "taskuraha": 0,
              "Accounting": {
                "JournalEntry": [
                  {"Sum": "510", "CostObjective": "5525", "GeneralLedger": "552520"},
                  {"Sum": "510", "CostObjective": "09212", "GeneralLedger": "552520"},
                  {"Sum": "510", "CostObjective": "LE-P", "GeneralLedger": "552520"},
                  {"Sum": "510", "CostObjective": "800599", "GeneralLedger": "552520"},
                  {"Sum": "510", "CostObjective": "0921201", "GeneralLedger": "552520"}
                ],
                "CostObjective": []
              },
              "allikas_85": 0,
              "umardamine": 0,
              "JournalEntry": [
                {"Sum": "510", "CostObjective": "5525", "GeneralLedger": "552520"},
                {"Sum": "510", "CostObjective": "09212", "GeneralLedger": "552520"},
                {"Sum": "510", "CostObjective": "LE-P", "GeneralLedger": "552520"},
                {"Sum": "510", "CostObjective": "800599", "GeneralLedger": "552520"},
                {"Sum": "510", "CostObjective": "0921201", "GeneralLedger": "552520"}
              ],
              "allikas_muud": 0,
              "allikas_vara": 0,
              "sugulane_osa": 0,
              "CostObjective": [],
              "omavalitsuse_osa": 0,
              "allikas_taskuraha": 0
            }
          ],
          "kbmkonto": "",
          "koostaja": "",
          "objektid": 0,
          "doklausid": 1874,
          "journalid": 0,
          "kr_number": "",
          "Accounting": {
            "JournalEntry": [
              {"Sum": "510", "CostObjective": "5525", "GeneralLedger": "552520"},
              {"Sum": "510", "CostObjective": "09212", "GeneralLedger": "552520"},
              {"Sum": "510", "CostObjective": "LE-P", "GeneralLedger": "552520"},
              {"Sum": "510", "CostObjective": "800599", "GeneralLedger": "552520"},
              {"Sum": "510", "CostObjective": "0921201", "GeneralLedger": "552520"}
            ],
            "CostObjective": []
          },
          "doc_status": 0,
          "korr_konto": "201000",
          "lastupdate": "",
          "raha_saaja": "",
          "umardamine": 0,
          "doc_type_id": "",
          "JournalEntry": [
            {"Sum": "510", "CostObjective": "5525", "GeneralLedger": "552520"},
            {"Sum": "510", "CostObjective": "09212", "GeneralLedger": "552520"},
            {"Sum": "510", "CostObjective": "LE-P", "GeneralLedger": "552520"},
            {"Sum": "510", "CostObjective": "800599", "GeneralLedger": "552520"},
            {"Sum": "510", "CostObjective": "0921201", "GeneralLedger": "552520"}
          ],
          "alus_arve_id": 0,
          "rekv_regkood": "75008611",
          "CostObjective": [],
          "taskuraha_kov": 0,
          "is_show_journal": 0
        }
      }
    ]$$::jsonb
);
 */