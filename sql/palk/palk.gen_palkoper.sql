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
        )
          AND palk_liik NOT IN ('TASU');

    END IF;

    FOR v_tooleping IN
        SELECT t.id,
               t.rekvid,
               t.parentId,
               ltrim(rtrim(a.nimetus)) AS nimi,
               CASE
                   WHEN coalesce(a.tp, '800699') LIKE '800%' THEN '800699'
                   ELSE a.tp END       AS tp -- берем за основу клиентский ТП код. если пусто, то 800699
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
        ORDER BY t.pohikoht DESC, t.koormus DESC
        LOOP
            -- инициализируем
            l_arv_kogus = 0;
            l_kasutatud_umardamine = FALSE;


            SELECT NULL::INTEGER                  AS doc_id,
                   ltrim(rtrim(v_tooleping.nimi)) AS error_message,
                   NULL::INTEGER                  AS error_code
            INTO v_tulemus;


            l_sm_lib = NULL;

            FOR V_lib IN
                SELECT pk.libid                     AS id,
                       pk.liik,
                       empty(pk.asutusest::INTEGER) AS is_asutusest,
                       pk.tululiik,
                       empty(percent_::INTEGER)     AS is_percent,
                       pk.tunnus,
                       pk.tunnusid::INTEGER         AS tunnusid,
                       pk.minsots
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
                        , (CASE WHEN pk.summa < 0 THEN 1 ELSE 0 END) DESC, pk.summa DESC
                LOOP

                    -- umardamine
                    IF v_lib.liik > 1 AND l_viimane_summa <> 0
                    THEN
                        IF (l_arv_kogus = 1 AND NOT l_kasutatud_umardamine)
                        THEN
                            -- проверим есть ли округления в периоде

                            l_arv_kogus = (SELECT count(po.id)
                                           FROM palk.palk_oper po
                                                    INNER JOIN palk.tooleping t ON po.lepingid = t.id
                                           WHERE kpv >= make_date(year(l_kpv), month(l_kpv), 1)::DATE
                                             AND kpv <= l_kpv::DATE
                                             AND t.parentid = v_tooleping.parentid
                                             AND t.rekvid = v_tooleping.rekvid
                                             AND po.libid IN (
                                               SELECT id
                                               FROM libs.library l
                                               WHERE library = 'PALK'
                                                 AND l.rekvid = po.rekvid
                                                 AND (l.properties::JSONB ->> 'liik')::INTEGER = 1
                                           ));

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
                    SELECT row_to_json(row)
                    INTO l_params
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
                        SELECT parentid
                        INTO l_dok_id
                        FROM palk.palk_oper po
                        WHERE po.lepingid = v_tooleping.id
                          AND po.libid = V_lib.id
                          AND kpv = l_kpv
                        LIMIT 1;

                        SELECT coalesce(l_dok_id, 0) :: INTEGER                              AS id,
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
                               v_lib.tunnus                                                  AS tunnus,
                               v_lib.tunnusid                                                AS tunnusid,
                               l.korrkonto                                                   AS korrkonto,
                               l.proj                                                        AS proj,
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
                        FROM palk.com_palk_lib AS l
                        WHERE l.id = V_lib.id;

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
                       FROM (
                                SELECT l_dok_id                       AS doc_id,
                                       ltrim(rtrim(v_tooleping.nimi)) AS error_message,
                                       0::INTEGER                     AS error_code
                            ) row;
            data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

            -- дорасчет мин СН

            IF (is_calc_min_sots) AND l_sm_lib IS NOT NULL
            THEN
                -- удаляем предыдущий расчет мин.СН
                SELECT id
                INTO l_dok_id
                FROM palk.cur_palkoper po
                WHERE year(po.kpv) = year(l_kpv)
                  AND month(po.kpv) = month(l_kpv)
                  AND po.period IS NULL
                  AND po.lepingid IN (SELECT t.id
                                      FROM palk.tooleping t
                                      WHERE t.parentid = v_tooleping.parentid
                                        AND t.rekvid = v_tooleping.rekvId)
                  AND po.palk_liik :: TEXT = 'SOTSMAKS'
                  AND po.sotsmaks IS NOT NULL
                  AND po.sotsmaks <> 0;

                -- Готовим параметры для расчета
                SELECT row_to_json(row)
                INTO l_params
                FROM (SELECT l_kpv              AS kpv,
                             v_tooleping.rekvid AS rekvid,
                             v_tooleping.id     AS lepingid,
                             l_sm_lib           AS libid,
                             TRUE               AS kas_min_sots) row;

                SELECT *
                FROM palk.sp_calc_sots(user_id, l_params::JSON)
                INTO tulemus;

                IF tulemus.summa > 0
                THEN
                    l_tulemus_json = row_to_json(tulemus);
                    -- есть дорасчет с мин. соц.налога
                    SELECT pk.libid             AS id,
                           pk.liik,
                           pk.tunnus,
                           pk.tunnusid::INTEGER AS tunnusid
                    INTO v_lib
                    FROM palk.cur_palk_kaart pk
                    WHERE lepingid = v_tooleping.id
                      AND status = 1
                      AND pk.libid = l_sm_lib;

                    SELECT coalesce(l_dok_id, 0) :: INTEGER                                      AS id,
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
                           v_tooleping.tp :: TEXT                                                AS tp,
                           coalesce((l_tulemus_json ->> 'sm') :: NUMERIC, tulemus.sm) :: NUMERIC AS sotsmaks,
                           l_tulemus_json ->> 'selg' :: TEXT                                     AS muud,
                           TRUE                                                                  AS kas_lausend,
                           FALSE                                                                 AS kas_kas_arvesta_saldo
                    INTO v_palk_oper
                    FROM palk.com_palk_lib AS l
                    WHERE l.id = V_lib.id;

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
SELECT * from palk.gen_palkoper(5175, '{"osakond_ids":[274678,235990],
				"isik_ids":[1110],
				"lib_ids":[236121,236122,236124,236125,236126,236130,236133,236134,236142,236143,236145,236147,236149,236150,236153,236154,236158,236159,236160,236161,236162,236163,236170,236173,236174,236175,236180,236185,236186,236188,236190,236192,236193,236199,236204,236205,236216,236220,236222,236234,236244,236250,236255,236256,236263,236270,236271,236273,236274,236275,236276,236277,236279,236280,236281,236282,236283,236284,236286,236287,236291,236294,236300,236304,236305,236320,236321,236322,236325,236327,236332,236349,236350,236352,236353,236357,236358,236360,236362,236374,236377,236387,236396,236400,236415,236424,236427,236436,236437,236453,236458,236459,236467,236472,236482,236483,236484,236488,236490,236491,236494,236502,236506,236512,236535,236537,236538,236548,236553,236562,236563,236566,236570,236571,236579,236580,236581,236591,236593,236594,236603,236604,236608,236610,236612,236618,236620,236625,236626,236627,236628,236629,236634,236635,236639,236641,236642,236643,236646,236656,236657,236660,236662,236663,236664,236665,236669,236670,236671,236672,236673,236674,236675,236676,236677,236678,236679,236680,236681,236682,236683,236684,236685,236686,236687,236688,236689,236690,236691,236692,236693,236694,236700,236701,236702,236703,236704,236705,236706,236707,236709,236711,236713,236715,236716,236717,236718,236719,236720,236721,236722,236723,236724,236725,236727,236728,236733,236734,236739,236740,236742,236743,236753,236755,236756,236757,236761,236762,236763,236764,236765,236766,236775,236776,236777,236781,236782,236783,236784,236785,236786,236787,236788,236789,236790,236791,236792,236793,236795,236796,236798,236799,236800,236801,236803,236804,236807,236808,236809,236810,236812,236813,236815,236816,236820,236821,236822,236823,236824,236826,236827,236828,236829,236830,236831,236832,236833,236834,236835,236836,236837,236840,236843,236844,236846,236847,236849,236851,236852,236853,236854,236855,236856,236857,236859,236860,236866,236869,236870,236871,236872,236874,236875,236876,236877,236879,236880,236881,236882,236883,236887,236890,236903,236904,236905,236906,236907,236908,236909,236910,236912,236913,236914,236920,236921,236934,236936,236937,236938,236940,237197,248935,248936,250120,251403,251932,251936,251937,253168,253187,253498,253625,253626,253627,253628,253629,254356,254576,254666,254667,254668,254669,254670,254760,254761,254762,254763,254764,255094,255097,255098,255099,255108,255314,255315,255640,255642,255643,255645,255685,255687,256051,256052,256053,256054,256055,256056,256057,259978,259980,259983,260092,260093,260107,260111,260113,260124,260572,260578,260579,260844,261052,261053,261054,261243,261575,261580,261654,261718,262004,262408,262627,262637,262774,262839,262880,263578,264840,264913,267639,268494,270262,272983,273086,273091,273092,273094,273095,273096,273097,273098,273099,273100,273101,273102,273103,273104,273106,273107,273108,273109,273432,273433,273434,273435,273436,273438,273483,273484,274386,274681,274682,274683,274684,274685,274886,274887,274888,274889,274890,274891,274892,274893],
				"kpv":20231030,
				"kas_kustuta":true,
				"kas_arvesta_minsots":true,
				"dokprop":2417
				}')

*/