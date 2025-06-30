DROP FUNCTION IF EXISTS palk.gen_puhkuse_oper(INTEGER, JSON);
DROP FUNCTION IF EXISTS palk.gen_puhkuse_oper(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION palk.gen_puhkuse_oper(IN user_id INTEGER, IN params JSONB, OUT result INTEGER,
                                                 OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    v_lib                      RECORD;
    l_leping_id                INTEGER = params -> 'leping_id'; -- ссылка на договор
    l_isik_id                  INTEGER = (select parentid
                                          from palk.tooleping
                                          where id = l_leping_id);
    l_kpv                      DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_summa                    NUMERIC = params ->> 'summa'; -- расчитанная сумма отпускных
    l_tegev                    text    = params ->> 'tegev';
    l_allikas                  text    = coalesce(params ->> 'allikas', 'LE-P');
    l_artikkel                 text    = params ->> 'artikkel';
    l_tunnus                   text    = params ->> 'tunnus';
    l_tp                       text    = (select tp
                                          from libs.asutus
                                          where id in (select parentid
                                                       from palk.tooleping
                                                       where id = l_leping_id
                                                       limit 1));
    l_puudumise_id             integer = params -> 'puudumise_id'; -- ссылка на запись об отпуске
    l_dokprop_id               INTEGER = params ->> 'dokprop_id'; -- индентификатор профиля для контировки
    is_delete_prev_oper        BOOLEAN = params -> 'kas_kustuta'; -- предварительное удаление прежнего расчета
    l_algorithm                text    = params ->> 'algorithm';
    l_amet                     text    = params ->> 'amet';
    l_avg_paeva_summa          numeric = params ->> 'avg_paeva_summa';
    l_arv_paevad_perioodis     integer = params ->> 'arv_paevad_perioodis';
    l_selg                     text    = params ->> 'selg';
    l_params_kpv1              date    = params ->> 'kpv1';
    l_params_kpv2              date    = params ->> 'kpv2';
    l_makse_kpv                date    = params ->> 'makse_kpv';
    l_params                   JSON;
    l_save_params              JSON;
    l_function                 TEXT;
    tulemus                    RECORD;
    l_dok_id                   INTEGER = params ->> 'palk_oper_id'; -- ИД сформированной проводки
    v_palk_oper                RECORD; -- соберем все данные операции в строку
    l_tulemus_json             JSON;
    v_user                     RECORD;
    v_tulemus                  RECORD;
    l_sm_lib                   INTEGER; -- ид операции СН
    l_viimane_summa            NUMERIC;
    l_arv_kogus                INTEGER = 0;
    l_viimane_params           JSON;
    v_puudumine                record;
    l_periods                  integer;
    l_perioodi_kpv             date    = l_kpv;
    l_alg_kpv_perioodis        date ;
    l_lopp_kpv_perioodis       date ;
    l_kohustuse_alg_paev       date; -- дата начала обязательства по выплате
    l_kalendi_paevad_perioodis integer = (l_lopp_kpv_perioodis - l_alg_kpv_perioodis) + 1 ;
    l_too_paevad_perioodis     integer;
    l_pidu_paevad_perioodis    integer = (select count(id)
                                          from cur_tahtpaevad t
                                          where rekvid = 63 -- беру данные фин. департамента
                                            and make_date(t.aasta, t.kuu, t.paev) between
                                              l_alg_kpv_perioodis and l_lopp_kpv_perioodis);
    l_pohi_dok_id              integer;
    l_ettemaksu_dok_ids        integer[];
    l_kas_ettemaks             boolean = false; -- определяет это предоплата иди нет

    v_kesk_palk                record; -- расчет среднего
    v_palk                     record;
    l_summa_text               text;
    l_puhkuse_periodi_osa      date;

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

        RETURN;
    END IF;

    IF l_leping_id IS NULL
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad. Puudub leping';
        result = 0;
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

        RETURN;

    END IF;

    -- get periods
    select p.kpv2,
           p.kpv1,
           (p.properties ->> 'avg_paeva_summa')::numeric as avg_paeva_summa,
           p.puudumiste_liik,
           p.tyyp,
           p.id
    into v_puudumine
    from palk.puudumine p
    where p.id = l_puudumise_id;


    raise notice 'l_algorithm %, l_isik_id %, l_kohustuse_alg_paev %, l_params_kpv1 %',l_algorithm, l_isik_id, l_kohustuse_alg_paev, l_params_kpv1;

    for v_kesk_palk in (select *
                        from palk.calc_avg_income_vacation(user_id::INTEGER,
                                                           jsonb_build_object('alg_kpv', l_params_kpv1, 'lopp_kpv',
                                                                              l_params_kpv2, 'isik_id',
                                                                              l_isik_id):: JSON) a
                        where ltrim(rtrim(a.algorithm))::text = l_algorithm::text)
        loop

            -- расчет даты начала расчета отпускных
            if l_alg_kpv_perioodis is null then
                l_alg_kpv_perioodis = v_puudumine.kpv1;
                l_lopp_kpv_perioodis = v_puudumine.kpv2;
                l_params_kpv1 = v_puudumine.kpv1;
                l_params_kpv2 = v_puudumine.kpv2;
            end if;

            if l_kohustuse_alg_paev is null then
                l_kohustuse_alg_paev =
                        palk.arvuta_puhkuse_vm_paev(jsonb_build_object('puudumise_id', l_puudumise_id, 'alg_kpv',
                                                                       l_alg_kpv_perioodis, 'makse_kpv',
                                                                       l_makse_kpv));
            end if;
            l_avg_paeva_summa = v_kesk_palk.avg_paeva_summa;
            raise notice 'v_kesk_palk %, l_algorithm %, l_avg_paeva_summa %', v_kesk_palk.leping_id, l_algorithm, l_avg_paeva_summa;

            if l_dokprop_id is null then
                -- берем последний профиль этого учреждения для контирования
                l_dokprop_id = (select doklausid
                                from palk.palk_oper po
                                where po.lepingid = v_kesk_palk.leping_id
                                  and po.doklausid is not null
                                order by po.id desc
                                limit 1);
            end if;

            -- инициализируем
            SELECT NULL::INTEGER AS doc_id,
                   null::text    AS error_message,
                   NULL::INTEGER AS error_code
            INTO v_tulemus;

            SELECT pk.libid                           AS id,
                   pk.liik,
                   empty(pk.asutusest::INTEGER)       AS is_asutusest,
                   pk.tululiik,
                   empty(percent_::INTEGER)           AS is_percent,
                   pk.tunnus,
                   pk.tunnusid::INTEGER               AS tunnusid,
                   pk.minsots,
                   pk.objekt,
                   l.properties::jsonb ->> 'konto'    as konto,
                   l.properties::jsonb ->> 'tegev'    as tegev,
                   l.properties::jsonb ->> 'artikkel' as artikkel,
                   l.properties::jsonb ->> 'allikas'  as allikas

            into v_lib
            FROM palk.cur_palk_kaart pk
                     inner join libs.library l on pk.libid = l.id
            where
              -- только начисления
                l.properties::jsonb ->> 'liik' = '1'
              -- только отпуска
              and l.properties::jsonb ->> 'konto' in (select unnest(puhkused_kontod)
                                                      from palk.palk_kulu_kontod)
              and lepingid = v_kesk_palk.leping_id
              AND pk.status < 3
            limit 1;

            if v_lib.id is null then
                raise exception 'Viga: puudub puhkuse kood palgakaardis';
            end if;

            -- проверка на удаление прежней операции с такими параметрами
            IF is_delete_prev_oper IS NOT NULL AND is_delete_prev_oper and l_puudumise_id is not null
            THEN
                -- поиск аналогичной операции*
                for v_palk_oper in
                    SELECT parentid as dok_id
                    FROM palk.palk_oper po
                    WHERE po.lepingid = v_kesk_palk.leping_id
                      and coalesce((po.properties ->> 'puudumise_id')::integer, 0) in (select id
                                                                                       from palk.puudumine p
                                                                                       where p.lepingid = v_kesk_palk.leping_id
                                                                                         and p.puudumiste_liik = v_puudumine.puudumiste_liik
                                                                                         and p.tyyp = v_puudumine.tyyp
                                                                                         and p.kpv1 = v_puudumine.kpv1
                                                                                         and p.kpv2 = v_puudumine.kpv2
                                                                                         and p.status <> 'deleted')
                    loop

                        -- delete
                        PERFORM palk.sp_delete_palk_oper(user_id, v_palk_oper.dok_id, FALSE);
                    end loop;
            END IF;

            -- рассчитаем запись отсутствия для данного договора
            select id, coalesce((p.properties ->> 'arvestatud_paevad')::integer, p.paevad) as arvestatud_paevad
            into l_puudumise_id, l_arv_paevad_perioodis
            from palk.puudumine p
            where p.lepingid = v_kesk_palk.leping_id
              and p.puudumiste_liik = v_puudumine.puudumiste_liik
              and p.tyyp = v_puudumine.tyyp
              and p.kpv1 = v_puudumine.kpv1
              and p.kpv2 = v_puudumine.kpv2
              and p.status <> 'deleted'
            limit 1;

            -- получим сумму отпускных
            l_summa = l_avg_paeva_summa * l_arv_paevad_perioodis;

            l_periods =
                    (select (year(v_puudumine.kpv2) - year(v_puudumine.kpv1)) * 12 +
                            (month(v_puudumine.kpv2) - month(v_puudumine.kpv1) + 1));

            -- если отпуск в одном периоде. то дату оставляем датой начало отпуска
            if l_periods = 1 then
                l_kpv = l_alg_kpv_perioodis;

                if get_last_day(l_kohustuse_alg_paev) < get_last_day(l_alg_kpv_perioodis) then
                    -- дата наступления обязательства раньще
                    l_alg_kpv_perioodis = gomonth(l_alg_kpv_perioodis, (-1));
                    l_alg_kpv_perioodis = make_date(year(l_alg_kpv_perioodis), month(l_alg_kpv_perioodis), 1);
                    l_kas_ettemaks = true;

                    -- запомним дату реального отпуска (его части)
                    l_puhkuse_periodi_osa = l_kpv;
                    l_kpv = l_kohustuse_alg_paev;
                    raise notice 'l_kohustuse_alg_paev %, l_periods %, l_puhkuse_periodi_osa %',l_kohustuse_alg_paev, l_periods, l_puhkuse_periodi_osa;

                end if;
            end if;

            FOR i IN 1..l_periods
                LOOP
                    raise notice 'i %, l_periods %', i, l_periods;
                    if l_periods > 1 then
                        -- arvestame summa periodis ja paevad
                        if i > 1 then
                            l_alg_kpv_perioodis = gomonth(l_alg_kpv_perioodis, (i - 1));
                            l_alg_kpv_perioodis = make_date(year(l_alg_kpv_perioodis), month(l_alg_kpv_perioodis), 1);
                            l_kas_ettemaks = true;
                        end if;

                        l_lopp_kpv_perioodis = get_last_day(l_alg_kpv_perioodis:: DATE);

                        if l_lopp_kpv_perioodis > l_params_kpv2 then
                            l_lopp_kpv_perioodis = l_params_kpv2;
                        end if;

                        -- поправка на расчет в календарных днях
                        l_arv_paevad_perioodis =
                                (select palk.get_days_of_month_in_period(month(l_alg_kpv_perioodis)::INTEGER,
                                                                         year(l_alg_kpv_perioodis)::INTEGER,
                                                                         l_alg_kpv_perioodis:: DATE,
                                                                         l_lopp_kpv_perioodis:: DATE,
                                                                         false:: BOOLEAN, true:: BOOLEAN));

                        l_summa = l_avg_paeva_summa * l_arv_paevad_perioodis;
                    end if;

                    -- контроль периода для модуля ЗП
                    IF NOT (ou.fnc_aasta_palk_kontrol(v_user.rekvid, l_lopp_kpv_perioodis))
                    THEN
                        error_code = 6;
                        error_message = 'Viga, periodi kontrol. palk kinni %' , l_lopp_kpv_perioodis;
                        result = 0;
                        SELECT error_message, error_code INTO v_tulemus;
                        l_params = to_jsonb(v_tulemus);
                        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
                        RETURN;
                        RAISE EXCEPTION 'Viga, periodi kontrol. palk kinni';
                    END IF;

                    -- расчет для алгоритма продолжение ЗП
                    if l_algorithm = 'Palk' then

                        -- ищем подходящий период в расчете
                        l_summa = (select (value ->> 'summa')::numeric
                                   from jsonb_array_elements(v_kesk_palk.data::jsonb) a
                                   where month((value ->> 'period_start')::date) = month(l_puhkuse_periodi_osa)
                                     and year((value ->> 'period_start')::date) = year(l_puhkuse_periodi_osa)
                                   limit 1);

                    end if;

                    raise notice 'palk finish l_summa % ',l_summa;

                    -- Готовим параметры для расчета
                    SELECT row_to_json(row)
                    INTO l_params
                    FROM (SELECT case when l_periods = 1 then l_lopp_kpv_perioodis else get_last_day(l_kpv) end AS kpv,
                                 v_user.rekvid                                                                  AS rekvid,
                                 v_kesk_palk.leping_id                                                          AS lepingid,
                                 V_lib.id                                                                       AS libid,
                                 l_summa                                                                        as alus_summa) row;


                    raise notice 'arv params %',l_params;

                    -- определяем расчетную процедуру
                    l_function = 'palk.sp_calc_arv';

                    -- вызов процедура расчета

                    EXECUTE 'select * from ' || l_function || '($1, $2)'
                        INTO STRICT tulemus
                        USING user_id, l_params;

                    l_tulemus_json = row_to_json(tulemus);

                    IF v_lib.liik = 1 AND tulemus.summa IS NOT NULL AND tulemus.summa <> 0
                    THEN
                        l_viimane_summa = tulemus.summa;
                        l_viimane_params = l_params;
                    END IF;

                    if l_kpv < l_kohustuse_alg_paev then
                        l_kpv = l_kohustuse_alg_paev;
                    end if;

                    IF tulemus.summa IS NOT NULL AND tulemus.summa <> 0
                    THEN

                        SELECT 0 :: INTEGER                                                  AS id,
                               l_kpv                                                         AS kpv,
                               l_kpv                                                         as maksekpv,
                               v_kesk_palk.leping_id                                         AS lepingid,
                               V_lib.id                                                      AS libid,
                               tulemus.summa                                                 AS summa,
                               l_dokprop_id                                                  AS dokpropid,
                               case
                                   when empty(v_kesk_palk.tegev) then v_lib.tegev
                                   else v_kesk_palk.tegev end                                AS kood1,
                               case
                                   when empty(v_kesk_palk.allikas) then v_lib.allikas
                                   else v_kesk_palk.allikas end                              AS kood2,
                               case
                                   when empty(v_kesk_palk.artikkel) then v_lib.artikkel
                                   else v_kesk_palk.artikkel end                             AS kood5,
                               null                                                          AS kood4,
                               v_lib.konto                                                   AS konto,
                               v_kesk_palk.tunnus                                            AS tunnus,
                               v_lib.tunnusid                                                AS tunnusid,
                               null                                                          AS korrkonto,
                               l.proj                                                        AS proj,
                               V_lib.objekt                                                  AS objekt,
                               l_tp :: TEXT                                                  AS tp,
                               coalesce((l_tulemus_json ->> 'tm') :: NUMERIC, 0) :: NUMERIC  AS tulumaks,
                               coalesce((l_tulemus_json ->> 'sm') :: NUMERIC, 0) :: NUMERIC  AS sotsmaks,
                               coalesce((l_tulemus_json ->> 'tki') :: NUMERIC, 0) :: NUMERIC AS tootumaks,
                               coalesce((l_tulemus_json ->> 'tka') :: NUMERIC, 0) :: NUMERIC AS tka,
                               coalesce((l_tulemus_json ->> 'pm') :: NUMERIC, 0) :: NUMERIC  AS pensmaks,
                               coalesce((l_tulemus_json ->> 'mvt') :: NUMERIC, 0) :: NUMERIC AS tulubaas,
                               v_lib.tululiik                                                AS tululiik,
                               l_tulemus_json ->> 'selg' :: TEXT                             AS muud,
                               TRUE                                                          AS kas_lausend,
                               FALSE                                                         AS kas_kas_arvesta_saldo,
                               l_puudumise_id                                                as puudumise_id,
                               l_kas_ettemaks                                                as kas_ettemaks,
                               l_lopp_kpv_perioodis                                          as ettemaksu_periood
                        INTO v_palk_oper
                        FROM palk.com_palk_lib AS l
                        WHERE l.id = V_lib.id;

                        l_save_params = row_to_json(v_palk_oper);

                        raise notice 'l_save_params % ', l_save_params;

                        -- save results
                        l_dok_id =
                                palk.sp_salvesta_palk_oper(('{"lausend":true,"data":' || l_save_params || '}') :: JSON,
                                                           user_id,
                                                           v_user.rekvid);

                        raise notice 'l_dok_id %, l_save_params %', l_dok_id, l_save_params;

                        IF (coalesce(l_dok_id, 0) > 0)
                        THEN
                            if i = 1 then
                                l_pohi_dok_id = l_dok_id;
                            else
                                l_ettemaksu_dok_ids = array_append(l_ettemaksu_dok_ids, l_dok_id);
                            end if;

                            if v_puudumine.id = l_puudumise_id then
                                -- результат будет только для того отсутствия, которое задано в параметрах
                                result = l_pohi_dok_id;
                            end if;

                            --  вернем значение параметров расчета обратно
                            l_params_kpv1 = (params ->> 'kpv1')::date;
                            l_params_kpv2 = (params ->> 'kpv2')::date;

                            -- сохраним ссылку на операцию
                            update palk.puudumine
                            set properties = coalesce(properties, '{}'::jsonb) ||
                                             jsonb_build_object('palk_oper_id', l_pohi_dok_id,
                                                                'ettemaksud_ids', l_ettemaksu_dok_ids,
                                                                'algorithm', l_algorithm,
                                                                'amet', v_kesk_palk.amet,
                                                                'avg_paeva_summa', l_avg_paeva_summa,
                                                                'arv_paevad_perioodis',
                                                                (params ->> 'arv_paevad_perioodis'),
                                                                'selg', l_selg,
                                                                'allikas', v_kesk_palk.allikas,
                                                                'tegev', v_kesk_palk.tegev,
                                                                'artikkel', v_kesk_palk.artikkel,
                                                                'tunnus', v_kesk_palk.tunnus,
                                                                'kpv1', l_params_kpv1,
                                                                'kpv2', l_params_kpv2
                                             )
                            where id = l_puudumise_id;

                        else
                            result = 0;
                            error_code = 9;
                            error_message = 'Viga: palgaoperatsioon salvestamine ebaõnnestus ';
                            raise exception '%', error_message;
                        END IF;
                    END IF;
                    -- расчет сальдо
--            PERFORM palk.sp_update_palk_jaak(l_kpv::DATE, l_leping_id::INTEGER);

                END LOOP;
        end loop; -- kesk palk arvestus


    RETURN;
END ;
$BODY$ LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_oper(user_id INTEGER, params JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_oper(user_id INTEGER, params JSONB) TO dbpeakasutaja;


/*
SELECT * from palk.gen_puhkuse_oper(2477, '{
   "kpv": "20250731",
   "leping_id": 27377,
   "palk_oper_id": null,
   "summa": 3702.72,
   "tegev": "01112",
   "allikas": "LE-P",
   "artikkel": "5001",
   "tunnus": "",
   "puudumise_id": 156315,
   "kas_kustuta": true,
   "algorithm":"Arveldus",
   "amet":"osakonna juhataja",
   "avg_paeva_summa":115.71,
   "arv_paevad_perioodis":173,
   "selg":"Kalendri päevad periodis:181 pidupäavad:8 puudumised:, Arveldused kokku:20017.50 kasutatud koodid: PALK012,LISA012",
   "kpv1":"20250101",
   "kpv2":"20250630"
    }'::jsonb)

*/