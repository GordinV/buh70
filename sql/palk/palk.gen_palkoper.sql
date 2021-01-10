DROP FUNCTION IF EXISTS palk.gen_palkoper(INTEGER, JSON);
--tnlepingid integer, tnlibid integer, tndoklausid integer, tdkpv date, tnavans integer, tnminpalk integer
CREATE OR REPLACE FUNCTION palk.gen_palkoper(IN user_id INTEGER, IN params JSON, OUT result INTEGER,
                                             OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    v_lib               RECORD;

    l_leping_ids        JSON    = params -> 'leping_ids'; -- массив индентификаторов договоров
    l_lib_ids           JSON    = params -> 'lib_ids'; -- массив индентификаторов договоров
    l_kpv               DATE    = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_osakond_ids       JSON    = params -> 'osakond_ids'; -- массив индентификаторов договоров
    l_isik_ids          JSON    = params -> 'isik_ids'; -- массив индентификаторов договоров
    l_dokprop_id        INTEGER = params -> 'dokprop'; -- индентификатор профиля для контировки
    is_delete_prev_oper BOOLEAN = params -> 'kas_kustuta'; -- предварительное удаление прежнего расчета
    is_calc_min_sots    BOOLEAN = params -> 'kas_arvesta_minsots'; -- расчет мин. соц. налога

    v_tooleping         RECORD;
    l_params            JSON;
    l_save_params       JSON;
    l_function          TEXT;
    tulemus             RECORD;
    l_dok_id            INTEGER; -- ИД сформированной проводки
    v_palk_oper         RECORD; -- соберем все данные операции в строку
    l_tulemus_json      JSON;
    v_user              RECORD;
    v_tulemus           RECORD;

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

    -- выбираем договора для подготовки расчет

    -- проверка на удаление прежнего расчета
    IF is_delete_prev_oper IS NOT NULL AND is_delete_prev_oper
    THEN

        -- delete
        PERFORM palk.sp_delete_palk_oper(user_id, id, FALSE)
        FROM palk.cur_palkoper
        WHERE kpv = l_kpv
          AND lepingid IN (
            SELECT t.id
            FROM palk.tooleping t
            WHERE (t.id IN (SELECT value :: INTEGER
                            FROM json_array_elements_text(l_leping_ids))
                OR (t.parentid IN (SELECT value :: INTEGER
                                   FROM json_array_elements_text(l_isik_ids))
                    AND osakondid IN (SELECT value :: INTEGER
                                      FROM json_array_elements_text(l_osakond_ids))
                       ))
              AND t.algab <= l_kpv
              AND (t.lopp IS NULL OR t.lopp >= l_kpv)
              AND t.rekvid IN (SELECT rekvid
                               FROM ou.userid u
                               WHERE u.id = user_id)
              AND t.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
        );

    END IF;

    FOR v_tooleping IN
        SELECT t.id,
               t.rekvid,
               t.parentId,
               ltrim(rtrim(a.nimetus)) AS nimi
        FROM palk.tooleping t
                 INNER JOIN libs.asutus a ON a.id = t.parentid
        WHERE (t.id IN (SELECT value :: INTEGER
                        FROM json_array_elements_text(l_leping_ids))
            OR (t.parentid IN (SELECT value :: INTEGER
                               FROM json_array_elements_text(l_isik_ids))
                AND osakondid IN (SELECT value :: INTEGER
                                  FROM json_array_elements_text(l_osakond_ids))
                   ))
          AND t.algab <= l_kpv
          AND (t.lopp IS NULL OR t.lopp >= l_kpv)
          AND t.rekvid IN (SELECT rekvid
                           FROM ou.userid u
                           WHERE u.id = user_id)
          AND t.status <> array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
            ORDER BY t.pohikoht DESC
        LOOP
            -- инициализируем
            SELECT NULL::INTEGER                  AS doc_id,
                   ltrim(rtrim(v_tooleping.nimi)) AS error_message,
                   NULL::INTEGER                  AS error_code
                   INTO v_tulemus;


            FOR V_lib IN
                SELECT pk.libid                     AS id,
                       pk.liik,
                       empty(pk.asutusest::INTEGER) AS is_asutusest,
                       pk.tululiik,
                       empty(percent_::INTEGER)     AS is_percent,
                       pk.tunnus
                FROM palk.cur_palk_kaart pk
                WHERE lepingid = v_tooleping.id
                  AND status = 1
                  AND pk.libid IN (SELECT value :: INTEGER
                                   FROM json_array_elements_text(l_lib_ids))
                    ORDER BY pk.liik
                    , CASE
                          WHEN empty(pk.tululiik)
                              THEN 99 :: TEXT
                          ELSE pk.tululiik END
                    , Pk.percent_ DESC
                    , pk.summa DESC
                LOOP
                    -- Готовим параметры для расчета
                    SELECT row_to_json(row) INTO l_params
                    FROM (SELECT l_kpv              AS kpv,
                                 v_tooleping.rekvid AS rekvid,
                                 v_tooleping.id     AS lepingid,
                                 V_lib.id           AS libid) row;

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

                    -- вызов процедура расчета
                    EXECUTE 'select * from ' || l_function || '($1, $2)'
                        INTO STRICT tulemus
                        USING user_id, l_params;

                    l_tulemus_json = row_to_json(tulemus);

                    IF tulemus.summa IS NOT NULL AND tulemus.summa <> 0
                    THEN
                        -- поиск аналогичной операции
                        SELECT parentid INTO l_dok_id
                        FROM palk.palk_oper po
                        WHERE po.lepingid = v_tooleping.id
                          AND po.libid = V_lib.id
                          AND kpv = l_kpv
                            LIMIT 1;

                        SELECT l_dok_id :: INTEGER                                           AS id,
                               l_kpv                                                         AS kpv,
                               v_tooleping.id                                                AS lepingid,
                               V_lib.id                                                      AS libid,
                               tulemus.summa                                                 AS summa,
                               l_dokprop_id                                                  AS dokpropid,
                               l.tegev                                                       AS kood1,
                               l.allikas                                                     AS kood2,
                               l.artikkel                                                    AS kood5,
                               l.uritus                                                      AS kood4,
                               l.konto                                                       AS konto,
                               l.tunnusid                                                    AS tunnusid,
                               v_lib.tunnus                                                  AS tunnus,
                               l.korrkonto                                                   AS korrkonto,
                               l.proj                                                        AS proj,
                               '800699' :: TEXT                                              AS tp,
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
                        FROM palk.com_palk_lib AS l
                        WHERE l.id = V_lib.id;

                        l_save_params = row_to_json(v_palk_oper);

                        -- save results
                        l_dok_id =
                                palk.sp_salvesta_palk_oper(('{"lausend":true,"data":' || l_save_params || '}') :: JSON,
                                                           user_id,
                                                           v_tooleping.rekvid);
                        IF (coalesce(l_dok_id, 0) > 0)
                        THEN
                            result = coalesce(result, 0) + 1;
                        END IF;

                    END IF;

                    -- umardamine
                    IF v_lib.liik = 1 AND tulemus.summa <> 0
                        AND -- tulud rohkem kui 1
                       (
                           SELECT count(po.id)
                           FROM palk.cur_palkoper po
                           WHERE po.lepingId IN (SELECT id
                                                 FROM palk.tooleping t
                                                 WHERE t.parentId = v_tooleping.parentid
                           )
                             AND po.rekvId = v_tooleping.rekvid
                             AND po.summa <> 0
                             AND po.palk_liik = 'ARVESTUSED'
                             AND year(kpv) = year(l_kpv)
                             AND month(kpv) = month(l_kpv)
                       ) > 1


                    THEN
                        -- umardamine
                        PERFORM palk.sp_calc_umardamine(user_id, l_params);
                    END IF;

                END LOOP;
            --libs loop
            -- report
            l_params = to_jsonb(row.*)
                       FROM (
                                SELECT l_dok_id                       AS doc_id,
                                       ltrim(rtrim(v_tooleping.nimi)) AS error_message,
                                       0::INTEGER                     AS error_code
                            ) row;
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

            -- расчет сальдо
            PERFORM palk.sp_update_palk_jaak(l_kpv::DATE, v_tooleping.id::INTEGER);

        END LOOP; -- leping loop
    IF (coalesce(result, 0)) = 0
    THEN
        -- empty result
        l_params = to_jsonb(row.*)
                   FROM (
                            SELECT NULL                             AS doc_id,
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

GRANT EXECUTE ON FUNCTION palk.gen_palkoper(user_id INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_palkoper(user_id INTEGER, params JSON) TO dbpeakasutaja;

/*
SELECT * from palk.gen_palkoper(1, null::json)
SELECT * from palk.gen_palkoper(1, '{"leping_ids": [3,4]}')
SELECT palk.gen_palkoper(1, '{"kpv":20180508,"leping_ids": [3,4],"lib_ids":[525, 526, 528, 529, 530, 531, 524]}')
SELECT palk.gen_palkoper(1, '{"kpv":20180508,"isik_ids": [56,57],"osakond_ids":[374,377],"lib_ids":[525, 526, 528, 529, 530, 531, 524]}')
SELECT palk.gen_palkoper(1, '{"osakond_ids":[374],
				"isik_ids":[56],
				"lib_ids":[384,386,390,391,524,525,526,528,529,530],
				"kpv":20180508,
				"kas_kustuta":false,
				"kas_arvesta_minsots":false,
				"dokprop":22
				}')
SELECT * from palk.gen_palkoper(1, '{"leping_ids": [3,4], "kas_kustuta":true}')



*/