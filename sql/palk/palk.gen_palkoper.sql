DROP FUNCTION IF EXISTS palk.gen_palkoper(INTEGER, JSON);

CREATE OR REPLACE FUNCTION palk.gen_palkoper(IN user_id INTEGER, IN params JSON, OUT result INTEGER,
                                             OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    v_lib                  RECORD;
    l_leping_ids           JSON    = params -> 'leping_ids'; -- массив индентификаторов договоров
    l_lib_ids              JSON    = params -> 'lib_ids'; -- массив индентификаторов договоров
    l_kpv                  DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_makse_kpv            DATE    = coalesce((params ->> 'maksekpv') :: DATE, null);
    l_osakond_ids          JSON    = params -> 'osakond_ids'; -- массив индентификаторов договоров
    l_isik_ids             JSON    = params -> 'isik_ids'; -- массив индентификаторов договоров
    l_dokprop_id           INTEGER = case
                                         when params ->> 'dokprop' = 'null' then to_json(null::integer)
                                         else params -> 'dokprop' end; -- индентификатор профиля для контировки
    is_delete_prev_oper    BOOLEAN = params -> 'kas_kustuta'; -- предварительное удаление прежнего расчета
    is_calc_min_sots       BOOLEAN = params -> 'kas_arvesta_minsots'; -- расчет мин. соц. налога
    l_puudumine_id         integer = params ->> 'puudumine_id'; -- ссылка на отсутствие (отпуск или больничный) для отдельного расчета налогов
    l_palk_oper_id         integer = params ->> 'palk_oper_id'; -- ссылка на операцию (отпуск или больничный) для отдельного расчета налогов

    v_tooleping            RECORD;
    l_params               JSON;
    l_save_params          JSON;
    l_function             TEXT;
    tulemus                RECORD;
    l_dok_id               INTEGER; -- ИД сформированной проводки
    v_palk_oper            RECORD; -- соберем все данные операции в строку
    v_alus_palk_oper       RECORD; -- соберем все данные базовой операции в строку
    l_tulemus_json         JSON;
    v_user                 RECORD;
    v_tulemus              RECORD;
    l_sm_lib               INTEGER; -- ид операции СН
    l_viimane_summa        NUMERIC;
    l_arv_kogus            INTEGER = 0;
    l_viimane_params       JSON;
    l_kasutatud_umardamine BOOLEAN = FALSE;
    kas_puhkused           boolean = params -> 'kas_puhkused'; -- ставим метку если у нас есть операции с отпуском params -> 'kas_puhkused'; -- ставим метку если у нас есть операции с отпуском
    v_puhkused             record;
    kas_vm                 boolean = false;

BEGIN
    -- проверка пользователя
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

        RETURN;
    END IF;

    -- проверка параметров
    IF l_isik_ids IS NULL AND l_leping_ids IS NULL
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad';
        result = 0;
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

        RETURN;

    END IF;

    -- контроль периода для модуля ЗП
    IF NOT (ou.fnc_aasta_palk_kontrol(v_user.rekvid, l_kpv))
    THEN
        error_code = 6;
        error_message = 'Viga, periodi kontrol. palk kinni';
        result = 0;
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
        RETURN;
        RAISE EXCEPTION 'Viga, periodi kontrol. palk kinni';
    END IF;

    -- проверка массива отделов
    if jsonb_array_length(coalesce(l_osakond_ids::jsonb, '[]'::jsonb)) = 0 then
        select
            json_agg(t.osakondid)
        into l_osakond_ids
        from
            palk.tooleping t
        where
            t.id in (
                        select json_array_elements_text(l_leping_ids)::integer
                    );
    end if;

    -- выбираем договора для подготовки расчет

    -- проверка на удаление прежнего расчета
    IF is_delete_prev_oper IS NOT NULL AND is_delete_prev_oper
    THEN

        -- delete

        PERFORM palk.sp_delete_palk_oper(user_id, po.id, FALSE)
        FROM
            (
                SELECT
                    d.id,
                    p.kpv,
                    p.libid,
                    p.rekvid,
                    p.lepingid,
                    p.konto,
                    t.osakondid,
                    ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT AS palk_liik,
                    p.properties -> 'alus_oper_ids'                                                            as alus_oper_ids,
                    (p.properties ->> 'puudumise_id')::integer                                                 as puudumise_id
                FROM
                    docs.doc                      d
                        INNER JOIN palk.palk_oper p ON p.parentid = d.id
                        INNER JOIN libs.library   lib ON p.libid = lib.id AND lib.library = 'PALK'
                        INNER JOIN palk.tooleping t ON p.lepingid = t.id
                        INNER JOIN libs.asutus    a ON t.parentid = a.id
                WHERE
                      d.doc_type_id IN (
                                           SELECT
                                               id
                                           FROM
                                               libs.library l
                                           WHERE
                                                 l.library = 'DOK'
                                             AND l.kood = 'PALK_OPER'
                                       )
                  AND d.status <> 3
            ) po
        WHERE
              po.kpv = l_kpv
          AND po.lepingid IN (
                                 SELECT
                                     t.id
                                 FROM
                                     palk.tooleping t
                                 WHERE
                                       (t.id IN (
                                                    SELECT
                                                        value :: INTEGER
                                                    FROM
                                                        json_array_elements_text(l_leping_ids)
                                                )
                                           OR (t.parentid IN (
                                                                 SELECT
                                                                     value :: INTEGER
                                                                 FROM
                                                                     json_array_elements_text(l_isik_ids)
                                                                 where
                                                                     l_isik_ids is not null
                                                             )
                                               AND osakondid IN (
                                                                    SELECT
                                                                        value :: INTEGER
                                                                    FROM
                                                                        json_array_elements_text(l_osakond_ids)
                                                                    where
                                                                        l_osakond_ids is not null
                                                                )
                                            )
                                           )
                                   AND t.algab <= l_kpv
                                   AND (t.lopp IS NULL OR t.lopp >= l_kpv)
                                   AND t.rekvid IN (
                                                       SELECT
                                                           rekvid
                                                       FROM
                                                           ou.userid u
                                                       WHERE
                                                           u.id = user_id
                                                   )
                                   AND t.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
                             )
          AND po.palk_liik NOT IN ('TASU')
              -- без отпускных
          and not exists
              (
                  select 1 from palk.palk_kulu_kontod pkk where pkk.puhkused_kontod @> array [po.konto::text]
              )
              -- без надогов на отпускные или на отдельные расчеты
          and not exists
              (
                  select
                      id
                  from
                      palk.palk_oper ppo
                  where
                        to_jsonb(parentid) <@ coalesce(po.alus_oper_ids, to_jsonb(po.id))
                    and exists
                        (
                            select
                                1
                            from
                                palk.palk_kulu_kontod pkk
                            where
                                pkk.puhkused_kontod @> array [ppo.konto::text]
                        )
              )
              -- без связанных с регистром отсутствий расчетов (больничные, обучение и т.д.)
          and (po.puudumise_id is null or
               not exists
               (
                   select 1 from palk.puudumine pd where pd.id = po.puudumise_id and pd.status <> 'deleted'
               )
                  );

    END IF;

    -- грузим ПО , если задан параметр palk_oper_id , для дальнейшего использования классификаторов
    select
        po.parentid as doc_id,
        po.kood1,
        po.kood2,
        po.kood5,
        po.kood5,
        po.proj,
        po.summa
    into v_alus_palk_oper
    from
        palk.palk_oper po
    where
          po.parentid = l_palk_oper_id
      and l_palk_oper_id is not null;

    FOR v_tooleping IN
        SELECT
            t.id,
            t.rekvid,
            t.parentId,
            ltrim(rtrim(a.nimetus)) AS nimi,
            CASE
                WHEN coalesce(a.tp, '800699') LIKE '800%' THEN '800699'
                ELSE a.tp END       AS tp -- берем за основу клиентский ТП код. если пусто, то 800699
        FROM
            palk.tooleping             t
                INNER JOIN libs.asutus a ON a.id = t.parentid
        WHERE
              (t.id IN (
                           SELECT
                               value :: INTEGER
                           FROM
                               json_array_elements_text(l_leping_ids)
                       )
                  OR (t.parentid IN (
                                        SELECT
                                            value :: INTEGER
                                        FROM
                                            json_array_elements_text(l_isik_ids)
                                    )
                      AND osakondid IN (
                                           SELECT
                                               value :: INTEGER
                                           FROM
                                               json_array_elements_text(l_osakond_ids)
                                       )
                   ))
          AND t.algab <= l_kpv
          AND (t.lopp IS NULL OR t.lopp >= l_kpv)
          AND t.rekvid IN (
                              SELECT
                                  rekvid
                              FROM
                                  ou.userid u
                              WHERE
                                  u.id = user_id
                          )
          AND t.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
        ORDER BY t.pohikoht DESC, t.koormus DESC
        LOOP


            --            проверим наличие выплат в параметрах

            if exists
            (
                select
                    id
                from
                    palk.com_palk_lib
                where
                      rekvid IN (
                                    SELECT
                                        rekvid
                                    FROM
                                        ou.userid u
                                    WHERE
                                        u.id = user_id
                                )
                  and liik = 6
                  and id in
                      (
                          SELECT
                              value :: INTEGER
                          FROM
                              json_array_elements_text(l_lib_ids)
                      )
            ) then
                kas_puhkused = false;
                kas_vm = true;
            end if;

            -- инициализируем
            l_arv_kogus = 0;
            l_kasutatud_umardamine = FALSE;


            SELECT
                NULL::INTEGER                  AS doc_id,
                ltrim(rtrim(v_tooleping.nimi)) AS error_message,
                NULL::INTEGER                  AS error_code
            INTO v_tulemus;


            l_sm_lib = NULL;

            FOR V_lib IN
                SELECT
                    pk.libid                         AS id,
                    pk.liik,
                    NOT empty(pk.asutusest::INTEGER) AS is_asutusest,
                    pk.tululiik,
                    empty(percent_::INTEGER)         AS is_percent,
                    pk.tunnus,
                    pk.tunnusid::INTEGER             AS tunnusid,
                    pk.minsots,
                    pk.objekt
                FROM
                    palk.cur_palk_kaart pk
                WHERE
                      lepingid = v_tooleping.id
                  AND status = 1
                  AND pk.libid IN (
                                      SELECT
                                          value :: INTEGER
                                      FROM
                                          json_array_elements_text(l_lib_ids)
                                  )
                ORDER BY
                    pk.liik
                  , CASE
                        WHEN empty(pk.tululiik)
                            THEN 99 :: TEXT
                        ELSE pk.tululiik END
                  , Pk.percent_ DESC
                  , (CASE WHEN pk.summa < 0 THEN 1 ELSE 0 END) DESC, pk.summa DESC
                LOOP
                    -- umardamine
                    IF v_lib.liik > 1 AND l_viimane_summa <> 0
                    THEN
                        IF (l_arv_kogus = 1 AND NOT l_kasutatud_umardamine)
                        THEN
                            -- проверим есть ли округления в периоде

                            l_arv_kogus = (
                                              SELECT
                                                  count(po.id)
                                              FROM
                                                  palk.palk_oper                po
                                                      INNER JOIN palk.tooleping t ON po.lepingid = t.id
                                              WHERE
                                                    kpv >= make_date(year(l_kpv), month(l_kpv), 1)::DATE
                                                AND kpv <= l_kpv::DATE
                                                AND t.parentid = v_tooleping.parentid
                                                AND t.rekvid = v_tooleping.rekvid
                                                AND po.libid IN (
                                                                    SELECT
                                                                        id
                                                                    FROM
                                                                        libs.library l
                                                                    WHERE
                                                                          library = 'PALK'
                                                                      AND l.rekvid = po.rekvid
                                                                      AND (l.properties::JSONB ->> 'liik')::INTEGER = 1
                                                                )
                                          );

                        END IF;

                        IF l_arv_kogus > 1 AND NOT l_kasutatud_umardamine
                        THEN

                            -- отчечаем об использованном округлении
                            l_arv_kogus = 0;
                            l_kasutatud_umardamine = TRUE;
                            -- прокинем дату декларирования, если задана
                            if l_makse_kpv is not null then
                                l_viimane_params =
                                        l_viimane_params::jsonb || jsonb_build_object('maksekpv', l_makse_kpv)::jsonb;
                            end if;
                            -- umardamine
                            PERFORM palk.sp_calc_umardamine(user_id, l_viimane_params);
                        END IF;

                    END IF;

                    -- Готовим параметры для расчета
                    SELECT
                        row_to_json(row)
                    INTO l_params
                    FROM
                        (
                            SELECT
                                l_kpv              AS kpv,
                                v_tooleping.rekvid AS rekvid,
                                v_tooleping.id     AS lepingid,
                                false              as kas_puhkus, -- только обычную ЗП, отпуска вынесем отдельно
                                V_lib.id           AS libid,
                                l_palk_oper_id     as puhk_oper_id -- считаем только на это начисление
                        ) row;

                    -- определяем расчетную процедуру
                    l_function = CASE
                                     WHEN v_lib.liik = 1
                                         THEN 'palk.sp_calc_arv'
                                     WHEN v_lib.liik = 2 OR v_lib.liik = 8
                                         THEN 'palk.sp_calc_kinni'
                                     WHEN v_lib.liik = 3
                                         THEN 'palk.sp_calc_muuda'
                                     WHEN v_lib.liik = 4
                                         THEN 'palk.sp_calc_tulumaks'
                                     WHEN v_lib.liik = 5
                                         THEN 'palk.sp_calc_sots'
                                     WHEN v_lib.liik = 6
                                         THEN 'palk.sp_calc_tasu'
                                     WHEN v_lib.liik = 7 AND v_lib.is_asutusest
                                         THEN 'palk.sp_calc_muuda'
                                     WHEN v_lib.liik = 7 AND NOT v_lib.is_asutusest
                                         THEN 'palk.sp_calc_kinni'
                                     WHEN v_lib.liik = 6
                                         THEN 'palk.sp_calc_tasu'
                        END;

                    IF v_lib.liik = 5
                    THEN
                        -- SM
                        if NOT empty(v_lib.minsots) then
                            l_sm_lib = v_lib.id;
                        end if;


                    END IF;

                    -- вызов процедура расчета


                    EXECUTE 'select * from ' || l_function || '($1, $2)'
                        INTO STRICT tulemus
                        USING user_id, l_params;

                    l_tulemus_json = row_to_json(tulemus);

                    IF v_lib.liik = 1 AND tulemus.summa IS NOT NULL AND tulemus.summa <> 0
                    THEN
                        l_viimane_summa = tulemus.summa;
                        l_arv_kogus = l_arv_kogus + 1;
                        l_viimane_params = l_params;
                    END IF;

                    IF tulemus.summa IS NOT NULL AND tulemus.summa <> 0
                    THEN
                        -- поиск аналогичной операции
                        SELECT
                            parentid
                        INTO l_dok_id
                        FROM
                            palk.palk_oper po
                        WHERE
                            po.lepingid = v_tooleping.id
                          AND po.libid = V_lib.id
                          AND kpv = l_kpv
                          and not coalesce((po.properties ->> 'kas_eri_arvestus')::boolean, false) -- только на обычные операции
                          and (l_palk_oper_id is null or (po.properties ->> 'alus_palk_oper_id')::integer =
                                                         l_palk_oper_id) -- выдклим отдельный расчет
                        LIMIT 1;

                        SELECT
                            coalesce(l_dok_id, 0) :: INTEGER                              AS id,
                            l_kpv                                                         AS kpv,
                            l_makse_kpv                                                   as maksekpv,
                            v_tooleping.id                                                AS lepingid,
                            V_lib.id                                                      AS libid,
                            tulemus.summa                                                 AS summa,
                            l_dokprop_id                                                  AS dokpropid,
                            case
                                when l_palk_oper_id is not null then v_alus_palk_oper.kood1
                                else l.tegev end                                          as kood1,
                            case
                                when l_palk_oper_id is not null then v_alus_palk_oper.kood2
                                else l.allikas end                                        as kood2,
                            case
                                when l_palk_oper_id is not null then v_alus_palk_oper.kood5
                                else l.artikkel end                                       as kood5,

                            l.uritus                                                      AS kood4,
                            l.konto                                                       AS konto,
                            v_lib.tunnus                                                  AS tunnus,
                            v_lib.tunnusid                                                AS tunnusid,
                            l.korrkonto                                                   AS korrkonto,
                            case
                                when l_palk_oper_id is not null then v_alus_palk_oper.proj
                                else l.proj end                                           as proj,
                            V_lib.objekt                                                  AS objekt,
                            v_tooleping.tp :: TEXT                                        AS tp,
                            coalesce((l_tulemus_json ->> 'tm') :: NUMERIC, 0) :: NUMERIC  AS tulumaks,
                            coalesce((l_tulemus_json ->> 'sm') :: NUMERIC, 0) :: NUMERIC  AS sotsmaks,
                            coalesce((l_tulemus_json ->> 'tki') :: NUMERIC, 0) :: NUMERIC AS tootumaks,
                            coalesce((l_tulemus_json ->> 'tka') :: NUMERIC, 0) :: NUMERIC AS tka,
                            coalesce((l_tulemus_json ->> 'pm') :: NUMERIC, 0) :: NUMERIC  AS pensmaks,
                            coalesce((l_tulemus_json ->> 'mvt') :: NUMERIC, 0) :: NUMERIC AS tulubaas,
                            v_lib.tululiik                                                AS tululiik,
                            l_tulemus_json ->> 'selg' :: TEXT                             AS muud,
                            TRUE                                                          AS kas_lausend,
                            FALSE                                                         AS kas_arvesta_saldo,
                            l_tulemus_json -> 'ettemaksu_oper_ids'                        as ettemaksu_oper_ids,
                            tulemus.alus_oper_ids                                         as alus_oper_ids,
                            (l_palk_oper_id is not null)::boolean                         as kas_eri_arvestus, -- чтобы разделить расчет налогов
                            l_puudumine_id                                                as puudumise_id      -- если задан отдельный расчет для данного отсутствия

                        INTO v_palk_oper
                        FROM
                            palk.com_palk_lib AS l
                        WHERE
                            l.id = V_lib.id;

                        if l_kpv is not null and tulemus.summa is not null then

                            l_save_params = row_to_json(v_palk_oper);

                            -- save results
                            l_dok_id =
                                    palk.sp_salvesta_palk_oper(
                                            ('{"lausend":true,"data":' || l_save_params || '}') :: JSON,
                                            user_id,
                                            v_tooleping.rekvid);
                        end if;
                        IF (coalesce(l_dok_id, 0) > 0)
                        THEN
                            result = coalesce(result, 0) + 1;
                        END IF;

                    END IF;

                END LOOP;
            -- libs

            -- проверим наличие отпускных
            if kas_puhkused is null and not exists
            (
                select
                    id
                from
                    palk.palk_oper po
                where
                      po.lepingid = v_tooleping.id
                  and po.kpv = l_kpv
                  and po.konto in (
                                      select
                                          unnest(pk.puhkused_kontod)
                                      from
                                          palk.palk_kulu_kontod pk
                                  )
            ) then
                -- метка о доп. расчете для операций отпуска
                kas_puhkused = false;
            else
                -- отметка что есть отпускные и нужна проверка на дорасчет налогов
                kas_puhkused = true;
            end if;

            kas_puhkused = coalesce(kas_puhkused, false);

            -- проверяем на налоги для отпускных
            if kas_puhkused and not kas_vm then
                -- ищем отпускные без налогов
                for v_puhkused in
                    select
                        po.parentid as puhkuse_oper_id
                    from
                        palk.palk_oper              po
                            inner join libs.library l on l.id = po.libid
                    where
                          (l.properties::jsonb ->> 'liik')::integer = 1
                      and po.konto in (
                                          select
                                              unnest(pk.puhkused_kontod)
                                          from
                                              palk.palk_kulu_kontod pk
                                      )
                      and po.kpv = l_kpv
                      and po.lepingid = v_tooleping.id
                    loop
                        -- SM
                        if not exists
                        (
                            select
                                1
                            from
                                palk.palk_oper              po
                                    inner join libs.library l on l.id = po.libid
                            where
                                  po.properties -> 'alus_oper_ids' @>
                                  ('[]'::jsonb || to_jsonb(v_puhkused.puhkuse_oper_id))
                              and (l.properties::jsonb ->> 'liik')::integer = 5
--                                          and (l.properties::jsonb ->> 'liik')::integer  = 7 and l.properties::jsonb -> 'asutusest' = to_jsonb(1) -- tka
                        ) then

                            -- расчет соц. налога
                            perform palk.gen_puhkuse_sm(user_id,
                                                        jsonb_build_object('leping_id', v_tooleping.id,
                                                                           'kpv', l_kpv,
                                                                           'dokprop_id', l_dokprop_id,
                                                                           'palk_oper_id', v_puhkused.puhkuse_oper_id
                                                        )
                                    );

                            if coalesce(result, 0) = 0 then
                                result = 1;
                            end if;


                        end if;

                        -- TKA
                        if not exists
                        (
                            select
                                1
                            from
                                palk.palk_oper              po
                                    inner join libs.library l on l.id = po.libid
                            where
                                  po.properties -> 'alus_oper_ids' @> ('[]'::jsonb || to_jsonb(2260))
                              and (l.properties::jsonb ->> 'liik')::integer = 7
                              and l.properties::jsonb -> 'asutusest' = to_jsonb(1) -- tka

                        ) then

                            -- расчет TKA
                            perform palk.gen_puhkuse_tkm(user_id,
                                                         jsonb_build_object('leping_id', v_tooleping.id,
                                                                            'kpv', l_kpv,
                                                                            'dokprop_id', l_dokprop_id,
                                                                            'palk_oper_id', v_puhkused.puhkuse_oper_id
                                                         )
                                    );
                            if coalesce(result, 0) = 0 then
                                result = 1;
                            end if;


                        end if;

                    end loop;


            end if;


            -- umardamine kontrol
            -- umardamine

            IF l_viimane_summa <> 0
                AND -- tulud rohkem kui 1
               l_arv_kogus > 1 AND NOT l_kasutatud_umardamine
            THEN
                l_arv_kogus = 0;

                l_kasutatud_umardamine = TRUE;
                -- вызываем округление так как его еще нет
                -- umardamine
                -- прокинем дату декларирования, если задана
                if l_makse_kpv is not null then
                    l_viimane_params =
                            l_viimane_params::jsonb || jsonb_build_object('maksekpv', l_makse_kpv)::jsonb;
                end if;

                PERFORM palk.sp_calc_umardamine(user_id, l_viimane_params);
            END IF;


            --libs loop
            -- report
            l_params = to_jsonb(row.*)
                       FROM
                           (
                               SELECT
                                   l_dok_id                       AS doc_id,
                                   ltrim(rtrim(v_tooleping.nimi)) AS error_message,
                                   0::INTEGER                     AS error_code
                           ) row;
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

            -- дорасчет мин СН
            IF (is_calc_min_sots) AND l_sm_lib IS NOT NULL
            THEN
                -- удаляем предыдущий расчет мин.СН
                SELECT
                    id
                INTO l_dok_id
                FROM
                    palk.cur_palkoper po
                WHERE
                      year(po.kpv) = year(l_kpv)
                  AND month(po.kpv) = month(l_kpv)
                  AND po.period IS NULL
                  AND po.lepingid IN (
                                         SELECT
                                             t.id
                                         FROM
                                             palk.tooleping t
                                         WHERE
                                               t.parentid = v_tooleping.parentid
                                           AND t.rekvid = v_tooleping.rekvId
                                     )
                  AND po.palk_liik :: TEXT = 'SOTSMAKS'
                  AND po.sotsmaks IS NOT NULL
                  AND po.sotsmaks <> 0
                limit 1;

                -- Готовим параметры для расчета
                SELECT
                    row_to_json(row)
                INTO l_params
                FROM
                    (
                        SELECT
                            l_kpv              AS kpv,
                            v_tooleping.rekvid AS rekvid,
                            v_tooleping.id     AS lepingid,
                            l_sm_lib           AS libid,
                            FALSE              as kas_puhkus, -- на отпуск считаем отдельно
                            TRUE               AS kas_min_sots
                    ) row;

                SELECT *
                FROM
                    palk.sp_calc_sots(user_id, l_params::JSON)
                INTO tulemus;

                IF tulemus.summa > 0 and l_kpv is not null
                THEN
                    l_tulemus_json = row_to_json(tulemus);
                    -- есть дорасчет с мин. соц.налога
                    SELECT
                        pk.libid             AS id,
                        pk.liik,
                        pk.tunnus,
                        pk.tunnusid::INTEGER AS tunnusid,
                        pk.objekt            AS objekt
                    INTO v_lib
                    FROM
                        palk.cur_palk_kaart pk
                    WHERE
                          lepingid = v_tooleping.id
                      AND status = 1
                      AND pk.libid = l_sm_lib;

                    SELECT
                        coalesce(l_dok_id, 0) :: INTEGER                                      AS id,
                        l_kpv                                                                 AS kpv,
                        v_tooleping.id                                                        AS lepingid,
                        v_lib.id                                                              AS libid,
                        tulemus.summa                                                         AS summa,
                        l_dokprop_id                                                          AS dokpropid,
                        l.tegev                                                               AS kood1,
                        l.allikas                                                             AS kood2,
                        l.artikkel                                                            AS kood5,
                        l.uritus                                                              AS kood4,
                        l.konto                                                               AS konto,
                        v_lib.tunnus                                                          AS tunnus,
                        v_lib.tunnusid                                                        AS tunnusid,
                        l.korrkonto                                                           AS korrkonto,
                        l.proj                                                                AS proj,
                        v_lib.objekt,
                        v_tooleping.tp :: TEXT                                                AS tp,
                        coalesce((l_tulemus_json ->> 'sm') :: NUMERIC, tulemus.sm) :: NUMERIC AS sotsmaks,
                        l_tulemus_json ->> 'selg' :: TEXT                                     AS muud,
                        TRUE                                                                  AS kas_lausend,
                        FALSE                                                                 AS kas_kas_arvesta_saldo
                    INTO v_palk_oper
                    FROM
                        palk.com_palk_lib AS l
                    WHERE
                        l.id = V_lib.id;

                    l_save_params = row_to_json(v_palk_oper);

                    -- save results
                    l_dok_id =
                            palk.sp_salvesta_palk_oper(
                                    ('{"lausend":true,"data":' || l_save_params || '}') :: JSON,
                                    user_id,
                                    v_tooleping.rekvid);
                    IF (coalesce(l_dok_id, 0) > 0)
                    THEN
                        result = coalesce(result, 0) + 1;
                    END IF;
                ELSE
                    -- сумма доп. СН равна нулю
                    IF l_dok_id IS NOT NULL
                    THEN
                        -- удаляем
                        PERFORM palk.sp_delete_palk_oper(user_id, l_dok_id, FALSE);
                    END IF;


                END IF;

            END IF;


            -- расчет сальдо
            PERFORM palk.sp_update_palk_jaak(l_kpv::DATE, v_tooleping.id::INTEGER);

        END LOOP; -- leping loop
    IF (coalesce(result, 0)) = 0
    THEN
        -- empty result
        l_params = to_jsonb(row.*)
                   FROM
                       (
                           SELECT
                               NULL                             AS doc_id,
                               'Kehtiv palga arveldused ei ole' AS error_message,
                               0::INTEGER                       AS error_code
                       ) row;
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

    END IF;

    result = 1;
    RETURN;
END ;
$BODY$ LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.gen_palkoper(user_id INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_palkoper(user_id INTEGER, params JSON) TO dbpeakasutaja;

/*
SELECT * from palk.gen_palkoper(2, '				{"osakond_ids":[272674],
				"isik_ids":[137],
				"lib_ids":[272676,272677,272678,272679,272683,272684,272685,272686,272687,272688,272689,272690,272691,272692,272693,272694,272698,272729,272730,272731],
				"kpv":20260131,
				"maksekpv":20260131,
				"kas_kustuta":true,
				"kas_arvesta_minsots":true,
				"dokprop":5
				}')

select * from ou.userid where kasutaja = 'vlad' and rekvid = 132

*/