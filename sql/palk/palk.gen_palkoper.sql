DROP FUNCTION IF EXISTS palk.gen_palkoper(INTEGER, JSON);
--tnlepingid integer, tnlibid integer, tndoklausid integer, tdkpv date, tnavans integer, tnminpalk integer
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
    l_dokprop_id           INTEGER = params -> 'dokprop'; -- индентификатор профиля для контировки
    is_delete_prev_oper    BOOLEAN = params -> 'kas_kustuta'; -- предварительное удаление прежнего расчета
    is_calc_min_sots       BOOLEAN = params -> 'kas_arvesta_minsots'; -- расчет мин. соц. налога

    v_tooleping            RECORD;
    l_params               JSON;
    l_save_params          JSON;
    l_function             TEXT;
    tulemus                RECORD;
    l_dok_id               INTEGER; -- ИД сформированной проводки
    v_palk_oper            RECORD; -- соберем все данные операции в строку
    l_tulemus_json         JSON;
    v_user                 RECORD;
    v_tulemus              RECORD;
    l_sm_lib               INTEGER; -- ид операции СН
    l_viimane_summa        NUMERIC;
    l_arv_kogus            INTEGER = 0;
    l_viimane_params       JSON;
    l_kasutatud_umardamine BOOLEAN = FALSE;


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

    -- выбираем договора для подготовки расчет

    -- проверка на удаление прежнего расчета
    IF is_delete_prev_oper IS NOT NULL AND is_delete_prev_oper
    THEN

        -- delete
        PERFORM palk.sp_delete_palk_oper(user_id, id, FALSE)
        FROM
            palk.cur_palkoper
        WHERE
              kpv = l_kpv
          AND lepingid IN (
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
                          )
          AND palk_liik NOT IN ('TASU');

    END IF;

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
                    pk.libid                     AS id,
                    pk.liik,
                    empty(pk.asutusest::INTEGER) AS is_asutusest,
                    pk.tululiik,
                    empty(percent_::INTEGER)     AS is_percent,
                    pk.tunnus,
                    pk.tunnusid::INTEGER         AS tunnusid,
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
                                V_lib.id           AS libid
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

                    IF v_lib.liik = 5 AND NOT empty(v_lib.minsots)
                    THEN
                        -- SM
                        l_sm_lib = v_lib.id;
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
                        LIMIT 1;

                        SELECT
                            coalesce(l_dok_id, 0) :: INTEGER                              AS id,
                            l_kpv                                                         AS kpv,
                            l_makse_kpv                                                   as maksekpv,
                            v_tooleping.id                                                AS lepingid,
                            V_lib.id                                                      AS libid,
                            tulemus.summa                                                 AS summa,
                            l_dokprop_id                                                  AS dokpropid,
                            l.tegev                                                       AS kood1,
                            l.allikas                                                     AS kood2,
                            l.artikkel                                                    AS kood5,
                            l.uritus                                                      AS kood4,
                            l.konto                                                       AS konto,
                            v_lib.tunnus                                                  AS tunnus,
                            v_lib.tunnusid                                                AS tunnusid,
                            l.korrkonto                                                   AS korrkonto,
                            l.proj                                                        AS proj,
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
                                        v_tooleping.rekvid);
                        IF (coalesce(l_dok_id, 0) > 0)
                        THEN
                            result = coalesce(result, 0) + 1;
                        END IF;

                    END IF;


                END LOOP;
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
                  AND po.sotsmaks <> 0;

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
                            TRUE               AS kas_min_sots
                    ) row;

                SELECT *
                FROM
                    palk.sp_calc_sots(user_id, l_params::JSON)
                INTO tulemus;

                IF tulemus.summa > 0
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
EXCEPTION
    WHEN OTHERS
        THEN
            v_tulemus.
                error_message = v_tulemus.error_message || SQLERRM;
            v_tulemus.error_code = 1;
            l_params = to_jsonb(v_tulemus);
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;
            RETURN;
END ;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.gen_palkoper(user_id INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_palkoper(user_id INTEGER, params JSON) TO dbpeakasutaja;

/*
SELECT * from palk.gen_palkoper(66, '{"osakond_ids":[54833],
				"isik_ids":[30984],
				"lib_ids":[135395,135488,135560,136062,136064,136073,136074,136078,136079,136080,136081,136082,136085,136087,136216,136322,138226,138227,138228,138840,139557,139803,140137,140273,140340,140341,140699,140899,140900,140905,140907,140908,140909,140910,140911,140912,140913,140914,140915,140916,140917,140919,141125,141544,141545,141546,141556,141622,141738,141739,141740,141760,141885,141950,141973,141974,144631,145312,145403,145650,145899,145900,145903,145906,145909,145910,145911,145915,145916,145917,145918,146103,146104,146117,147959,148596,149253,149567,149605,149826,149896,149966,150139,150300,150432,150551,150554,150555,150558,150559,150560,150561,150562,150563,150564,150565,150610,151209,151223,151224,151225,151228,151275,151298,151301,151356,151439,152010,152161,154265,154267,154268,154269,154270,154271,230115,230116,230126,230238,250602,272619,281366],
				"kpv":20250430,
				"maksekpv":20250531,
				"kas_kustuta":true,
				"kas_arvesta_minsots":true,
				"dokprop":846
				}')

*/