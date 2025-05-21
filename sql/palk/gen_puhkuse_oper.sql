DROP FUNCTION IF EXISTS palk.gen_puhkuse_oper(INTEGER, JSON);
DROP FUNCTION IF EXISTS palk.gen_puhkuse_oper(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION palk.gen_puhkuse_oper(IN user_id INTEGER, IN params JSONB, OUT result INTEGER,
                                                 OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    v_lib               RECORD;
    l_leping_id         INTEGER = params -> 'leping_id'; -- ссылка на договор
    l_kpv               DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_summa             NUMERIC = params ->> 'summa'; -- расчитанная сумма отпускных
    l_tegev             text    = params ->> 'tegev';
    l_allikas           text    = params ->> 'allikas';
    l_artikkel          text    = params ->> 'artikkel';
    l_tunnus            text    = params ->> 'tunnus';
    l_tp                text    = (
                                      select
                                          tp
                                      from
                                          libs.asutus
                                      where
                                          id in (
                                                    select
                                                        parentid
                                                    from
                                                        palk.tooleping
                                                    where
                                                        id = l_leping_id
                                                    limit 1
                                                )
                                  );
    l_puudumise_id      integer = params -> 'puudumise_id'; -- ссылка на запись об отпуске
    l_dokprop_id        INTEGER = params ->> 'dokprop_id'; -- индентификатор профиля для контировки
    is_delete_prev_oper BOOLEAN = params -> 'kas_kustuta'; -- предварительное удаление прежнего расчета
    l_algorithm text = params ->>'algorithm';
    l_amet text = params ->>'amet';
    l_avg_paeva_summa numeric = params ->> 'avg_paeva_summa';
    l_arv_paevad_perioodis integer = params ->>'arv_paevad_perioodis';
    l_selg text =  params->>'selg';
    l_params_kpv1 date = params ->>'kpv1';
    l_params_kpv2 date = params ->>'kpv2';

    l_params            JSON;
    l_save_params       JSON;
    l_function          TEXT;
    tulemus             RECORD;
    l_dok_id            INTEGER = params->>'palk_oper_id'; -- ИД сформированной проводки
    v_palk_oper         RECORD; -- соберем все данные операции в строку
    l_tulemus_json      JSON;
    v_user              RECORD;
    v_tulemus           RECORD;
    l_sm_lib            INTEGER; -- ид операции СН
    l_viimane_summa     NUMERIC;
    l_arv_kogus         INTEGER = 0;
    l_viimane_params    JSON;


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

    -- проверка на удаление прежней операции с такими параметрами
    IF is_delete_prev_oper IS NOT NULL AND is_delete_prev_oper and l_puudumise_id is not null and l_dok_id is null
    THEN
        -- поиск аналогичной операции
        l_dok_id = (SELECT
            parentid
        FROM
            palk.palk_oper po
        WHERE
              po.lepingid = l_leping_id
          and (po.properties ->> 'puudumise_id')::integer = l_puudumise_id limit 1);

        -- delete
        if l_dok_id is not null then
            PERFORM palk.sp_delete_palk_oper(user_id, l_dok_id, FALSE);
        end if;

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

    SELECT
        pk.libid                        AS id,
        pk.liik,
        empty(pk.asutusest::INTEGER)    AS is_asutusest,
        pk.tululiik,
        empty(percent_::INTEGER)        AS is_percent,
        pk.tunnus,
        pk.tunnusid::INTEGER            AS tunnusid,
        pk.minsots,
        pk.objekt,
        l.properties::jsonb ->> 'konto' as konto

    into v_lib
    FROM
        palk.cur_palk_kaart         pk
            inner join libs.library l on pk.libid = l.id
    where
          -- только начисления
          l.properties::jsonb ->> 'liik' = '1'
          -- только отпуска
      and l.properties::jsonb ->> 'konto' in (
                                                 select
                                                     unnest(puhkused_kontod)
                                                 from
                                                     palk.palk_kulu_kontod
                                             )
      and lepingid = l_leping_id
      AND pk.status < 3
    limit 1;

    -- Готовим параметры для расчета
    SELECT
        row_to_json(row)
    INTO l_params
    FROM
        (
            SELECT
                l_kpv         AS kpv,
                v_user.rekvid AS rekvid,
                l_leping_id   AS lepingid,
                V_lib.id      AS libid,
                l_summa       as alus_summa
        ) row;

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

    IF tulemus.summa IS NOT NULL AND tulemus.summa <> 0
    THEN

        SELECT
            coalesce(l_dok_id, 0) :: INTEGER                              AS id,
            l_kpv                                                         AS kpv,
            l_kpv                                                         as maksekpv,
            l_leping_id                                                   AS lepingid,
            V_lib.id                                                      AS libid,
            tulemus.summa                                                 AS summa,
            l_dokprop_id                                                  AS dokpropid,
            l_tegev                                                       AS kood1,
            l_allikas                                                     AS kood2,
            l_artikkel                                                    AS kood5,
            null                                                          AS kood4,
            v_lib.konto                                                   AS konto,
            l_tunnus                                                      AS tunnus,
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
            FALSE                                                         AS kas_kas_arvesta_saldo
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
                        v_user.rekvid);
        IF (coalesce(l_dok_id, 0) > 0)
        THEN
            result = l_dok_id;
            -- сохраним ссылку на операцию
            update palk.puudumine
            set
                properties = coalesce(properties,'{}'::jsonb) || jsonb_build_object('palk_oper_id', l_dok_id,
                                                                 'algorithm', l_algorithm,
                                                                 'amet', l_amet,
                                                                 'avg_paeva_summa', l_avg_paeva_summa,
                                                                 'arv_paevad_perioodis', l_arv_paevad_perioodis,
                                                                 'selg', l_selg,
                                                                 'allikas', l_allikas,
                                                                 'tegev', l_tegev,
                                                                 'artikkel', l_artikkel,
                                                                 'tunnus', l_tunnus,
                                                                 'kpv1',l_params_kpv1,
                                                                 'kpv2',l_params_kpv2
                                                                 )
            where
                id = l_puudumise_id;
        else
            result = 0;
            error_code = 9;
            error_message = 'Viga: palgaoperatsioon salvestamine ebaõnnestus';
        END IF;

    END IF;

    -- расчет сальдо
    PERFORM palk.sp_update_palk_jaak(l_kpv::DATE, l_leping_id::INTEGER);

    RETURN;
END ;
$BODY$ LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_oper(user_id INTEGER, params JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_oper(user_id INTEGER, params JSONB) TO dbpeakasutaja;

/*
SELECT * from palk.gen_puhkuse_oper(2477, '{
   "kpv": "20250331",
   "leping_id": 28310,
   "summa": 52.43,
   "tegev": "01112",
   "allikas": "60",
   "artikkel": "5001",
   "tunnus": "",
   "puudumise_id": 152061,
   "kas_kustuta": true
    }'::jsonb)

*/