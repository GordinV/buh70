DROP FUNCTION IF EXISTS palk.gen_puhkuse_tkm(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION palk.gen_puhkuse_tkm(IN user_id INTEGER, IN params JSONB, OUT result INTEGER,
                                                OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_leping_id    INTEGER = params -> 'leping_id'; -- ссылка на договор
    l_kpv          DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_dokprop_id   INTEGER = params ->> 'dokprop_id'; -- индентификатор профиля для контировки
    l_params       JSON;
    l_save_params  JSON;
    tulemus        RECORD;
    l_dok_id       INTEGER = params ->> 'palk_oper_id'; -- ИД сформированной проводки
    v_palk_oper    RECORD; -- соберем все данные операции в строку
    l_tulemus_json JSON;
    v_user         RECORD;
    v_tulemus      RECORD;
    l_palk_lib_id  integer;

BEGIN
    SELECT kasutaja,
           rekvid
    INTO v_user
    FROM ou.userid u
    WHERE u.id = user_Id;

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
        l_dokprop_id = (select doklausid
                        from palk.palk_oper po
                        where po.lepingid = l_leping_id
                          and po.doklausid is not null
                        order by po.id desc
                        limit 1);
    end if;

    -- инициализируем
    SELECT NULL::INTEGER AS doc_id,
           null::text    AS error_message,
           NULL::INTEGER AS error_code
    INTO v_tulemus;

    -- делаем расчет TKM для каждой отдельной операции отпуск
    for v_palk_oper in
        select parentid                                      as id,
               ltrim(rtrim(po.kood2))                        as allikas,
               ltrim(rtrim(po.kood1))                        as tegev,
               po.tp,
               po.tunnus,
               po.kpv,
               (po.properties ->> 'kas_ettemaks')::boolean   as kas_ettemaks,
               (po.properties ->> 'ettemaksu_periood')::date as ettemaksu_periood
        from palk.palk_oper po
                 INNER JOIN libs.library lib ON po.libid = lib.id AND lib.library = 'PALK'
        where po.kpv = l_kpv
          and po.lepingid = l_leping_id
          AND ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT = 'ARVESTUSED'
          and po.konto in (select unnest(pk.puhkused_kontod)
                           from palk.palk_kulu_kontod pk)

        loop

            -- ищем ранее сделанный расчет TKM, по ид операции м удаляем его
            perform palk.sp_delete_palk_oper(user_id, po.parentid)
            from palk.palk_oper po
            where properties -> 'alus_oper_ids' @> to_jsonb(v_palk_oper.id)
              and po.rekvid = v_user.rekvid
              and po.lepingid = l_leping_id
              and po.libid in (select pk.libid
                               from palk.palk_kaart pk
                                        inner join libs.library l on l.id = pk.libid
                               -- только TKM
                               where (l.properties::jsonb ->> 'liik')::integer = 7
                                 and (l.properties::jsonb ->> 'asutusest')::integer = 1
                                 and pk.lepingid = l_leping_id)
              and po.kpv = v_palk_oper.kpv;

            -- ищем подходящиюю либу в карте начислений
            l_palk_lib_id = (select l.id
                             from palk.palk_kaart pk
                                      inner join libs.library l on l.id = pk.libid
                             where pk.lepingid = l_leping_id
                               and (l.properties::jsonb ->> 'liik')::integer = 7
                               and (l.properties::jsonb ->> 'asutusest')::integer = 1
                               and (l.properties::jsonb ->> 'allikas') in (v_palk_oper.allikas, '', null::text)
                               and (l.properties::jsonb ->> 'tegev') in (v_palk_oper.tegev, '', null::text)
                               and (l.properties::jsonb ->> 'konto') like '506%'
                             order by pk.status desc
                             limit 1);

            -- Готовим параметры для расчета
            SELECT row_to_json(row)
            INTO l_params
            FROM (SELECT l_kpv          AS kpv,
                         v_user.rekvid  AS rekvid,
                         l_leping_id    AS lepingid,
                         l_palk_lib_id  AS libid,
                         v_palk_oper.id as puhk_oper_id,
                         TRUE           as kas_puhkus) row;

            EXECUTE 'select * from palk.sp_calc_muuda($1, $2)'
                INTO STRICT tulemus
                USING user_id, l_params;

            l_tulemus_json = row_to_json(tulemus);

            IF tulemus.summa IS NOT NULL AND tulemus.summa <> 0
            THEN

                SELECT 0 :: INTEGER                           AS id,
                       l_kpv                                  AS kpv,
                       l_kpv                                  as maksekpv,
                       l_leping_id                            AS lepingid,
                       l_palk_lib_id                          AS libid,
                       tulemus.summa                          AS summa,
                       l_dokprop_id                           AS dokpropid,
                       l.tegev                                AS kood1,
                       l.allikas                              AS kood2,
                       l.artikkel                             AS kood5,
                       l.uritus                               AS kood4,
                       l.konto                                AS konto,
                       v_palk_oper.tunnus                     AS tunnus,
                       l.korrkonto                            AS korrkonto,
                       l.proj                                 AS proj,
                       v_palk_oper.tp :: TEXT                 AS tp,
                       l_tulemus_json ->> 'selg' :: TEXT      AS muud,
                       TRUE                                   AS kas_lausend,
                       FALSE                                  AS kas_arvesta_saldo,
                       l_tulemus_json -> 'ettemaksu_oper_ids' as ettemaksu_oper_ids,
                       l_tulemus_json -> 'alus_oper_ids'      as alus_oper_ids,
                       v_palk_oper.kas_ettemaks               as kas_ettemaks,
                       v_palk_oper.ettemaksu_periood          as ettemaksu_periood
                INTO v_palk_oper
                FROM palk.com_palk_lib AS l
                WHERE l.id = l_palk_lib_id;

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

GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_tkm(user_id INTEGER, params JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_tkm(user_id INTEGER, params JSONB) TO dbpeakasutaja;


/*
SELECT * from palk.gen_puhkuse_tkm(2477, '{"leping_id":27377,"kpv":"2025-07-31","dokprop_id":846}'::jsonb)

*/