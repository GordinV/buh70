DROP FUNCTION IF EXISTS palk.gen_puhkuse_sm(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION palk.gen_puhkuse_sm(IN user_id INTEGER, IN params JSONB, OUT result INTEGER,
                                               OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_leping_id        INTEGER = params -> 'leping_id'; -- ссылка на договор
    l_kpv              DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_dokprop_id       INTEGER = params ->> 'dokprop_id'; -- индентификатор профиля для контировки
    l_params           JSON;
    l_save_params      JSON;
    tulemus            RECORD;
    l_alus_dok_id      INTEGER = params ->> 'palk_oper_id'; -- ИД сформированной проводки
    l_dok_id           INTEGER ; -- ИД сформированной проводки
    v_palk_oper        RECORD; -- соберем все данные операции в строку
    l_tulemus_json     JSON;
    v_user             RECORD;
    v_tulemus          RECORD;
    l_palk_lib_id      integer;
    l_tunnus           text;
    l_tp               text;
    l_kas_ettemaks     boolean;
    l_ettemaksu_period date;
    l_kohustuse_kpv    date;
    l_puudumise_id     integer;

BEGIN
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
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
        raise exception 'Viga %', error_message;
    END IF;


    IF l_leping_id IS NULL
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad. Puudub leping';
        result = 0;
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
        raise exception 'Viga %', error_message;
    END IF;

    if l_dokprop_id is null then
        -- берем последний профиль этого учреждения для контирования
        l_dokprop_id = (
                           select
                               doklausid
                           from
                               palk.palk_oper po
                           where
                                 po.lepingid = l_leping_id
                             and po.doklausid is not null
                           order by po.id desc
                           limit 1
                       );
    end if;

    -- инициализируем
    SELECT
        NULL::INTEGER AS doc_id,
        null::text    AS error_message,
        NULL::INTEGER AS error_code
    INTO v_tulemus;

    -- делаем расчет соц.налога для каждой отдельной операции отпуск
    for v_palk_oper in
        select
            parentid                                      as id,
            ltrim(rtrim(po.kood2))                        as allikas,
            ltrim(rtrim(po.kood1))                        as tegev,
            po.tp,
            po.tunnus,
            po.kpv,
            (po.properties ->> 'kas_ettemaks')::boolean   as kas_ettemaks,
            (po.properties ->> 'ettemaksu_periood')::date as ettemaksu_periood,
            (po.properties ->> 'kohustuse_kpv')::date     as kohustuse_kpv,
            po.properties ->> 'puudumise_id'              as puudumise_id,
            po.lepingid
        from
            palk.palk_oper              po
                INNER JOIN libs.library lib ON po.libid = lib.id AND lib.library = 'PALK'
        where
            po.parentid = l_alus_dok_id
        loop

            -- сохраним данные операции
            l_kpv = v_palk_oper.kpv;
            l_tunnus = v_palk_oper.tunnus;
            l_tp = v_palk_oper.tp;
            l_kas_ettemaks = v_palk_oper.kas_ettemaks;
            l_ettemaksu_period = v_palk_oper.ettemaksu_periood;
            l_kohustuse_kpv = v_palk_oper.kohustuse_kpv;
            l_puudumise_id = v_palk_oper.puudumise_id;
            l_leping_id = v_palk_oper.lepingid;


            -- ищем ранее сделанный расчет сн, по ид операции м удаляем его
            perform palk.sp_delete_palk_oper(user_id, po.parentid)
            from
                palk.palk_oper po
            where
                  properties -> 'alus_oper_ids' @> to_jsonb(v_palk_oper.id)
              and po.rekvid = v_user.rekvid
              and po.lepingid = l_leping_id
              and po.libid in (
                                  select
                                      pk.libid
                                  from
                                      palk.palk_kaart             pk
                                          inner join libs.library l on l.id = pk.libid
                                  -- только SM
                                  where
                                        (l.properties::jsonb ->> 'liik')::integer = 5
                                    and pk.lepingid = l_leping_id
                              )
              and po.kpv = v_palk_oper.kpv;


            -- ищем подходящиюю либу в карте начислений
            l_palk_lib_id = (
                                select
                                    l.id
                                from
                                    palk.palk_kaart             pk
                                        inner join libs.library l on l.id = pk.libid
                                where
                                      pk.lepingid = l_leping_id
                                  and (l.properties::jsonb ->> 'liik')::integer = 5
                                  and (l.properties::jsonb ->> 'allikas') in (v_palk_oper.allikas, '', null::text)
                                  and (l.properties::jsonb ->> 'tegev') in (v_palk_oper.tegev, '', null::text)
                                  and (l.properties::jsonb ->> 'konto') like '506%'
                                order by pk.status desc
                                limit 1
                            );

            if l_palk_lib_id is null then
                l_palk_lib_id = (
                                    select
                                        l.id
                                    from
                                        palk.palk_kaart             pk
                                            inner join libs.library l on l.id = pk.libid
                                    where
                                          pk.lepingid = l_leping_id
                                      and (l.properties::jsonb ->> 'liik')::integer = 5
                                      and (l.properties::jsonb ->> 'konto') like '506%'
                                    order by pk.status desc
                                    limit 1
                                );

            end if;

            -- Готовим параметры для расчета
            SELECT
                row_to_json(row)
            INTO l_params
            FROM
                (
                    SELECT
                        v_palk_oper.kpv AS kpv,
                        v_user.rekvid   AS rekvid,
                        l_leping_id     AS lepingid,
                        l_palk_lib_id   AS libid,
                        l_alus_dok_id   as puhk_oper_id,
                        TRUE            as kas_puhkus
                ) row;

            EXECUTE 'select * from palk.sp_calc_sots($1, $2)'
                INTO STRICT tulemus
                USING user_id, l_params;

            l_tulemus_json = row_to_json(tulemus);

            IF tulemus.summa IS NOT NULL AND tulemus.summa <> 0
            THEN

                SELECT
                    0 :: INTEGER                           AS id,
                    l_kpv                                  AS kpv,
                    l_kpv                                  as maksekpv,
                    l_leping_id                            AS lepingid,
                    l_palk_lib_id                          AS libid,
                    tulemus.summa                          AS summa,
                    l_dokprop_id                           AS dokpropid,
                    v_palk_oper.tegev                      AS kood1,
                    v_palk_oper.allikas                    AS kood2,
                    l.artikkel                             AS kood5,
                    l.uritus                               AS kood4,
                    l.konto                                AS konto,
                    l_tunnus                               AS tunnus,
                    l.korrkonto                            AS korrkonto,
                    l.proj                                 AS proj,
                    l_tp :: TEXT                           AS tp,
                    l_tulemus_json ->> 'selg' :: TEXT      AS muud,
                    TRUE                                   AS kas_lausend,
                    FALSE                                  AS kas_arvesta_saldo,
                    l_tulemus_json -> 'ettemaksu_oper_ids' as ettemaksu_oper_ids,
                    l_tulemus_json -> 'alus_oper_ids'      as alus_oper_ids,
                    l_kas_ettemaks                         as kas_ettemaks,
                    l_kohustuse_kpv                        as kohustuse_kpv,
                    l_ettemaksu_period                     as ettemaksu_periood,
                    l_puudumise_id                         as puudumise_id

                INTO v_palk_oper
                FROM
                    palk.com_palk_lib AS l
                WHERE
                    l.id = l_palk_lib_id;

                l_save_params = row_to_json(v_palk_oper);

                -- save results
                l_dok_id =
                        palk.sp_salvesta_palk_oper(
                                ('{"lausend":true,"data":' || l_save_params || '}') :: JSON,
                                user_id,
                                v_user.rekvid);
                IF (coalesce(l_dok_id, 0) > 0)
                THEN
                    result = coalesce(result, 0) + 1;
                END IF;

            END IF;
        end loop;
    RETURN;
END ;
$BODY$ LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_sm(user_id INTEGER, params JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_sm(user_id INTEGER, params JSONB) TO dbpeakasutaja;


/*
SELECT * from palk.gen_puhkuse_sm(2477, '{"leping_id":27377,"kpv":"2025-07-31","dokprop_id":846}'::jsonb)

*/