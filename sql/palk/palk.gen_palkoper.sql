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

    -- контроль периода для модуля ЗП
    IF NOT (ou.fnc_aasta_palk_kontrol(v_user.rekvid, l_kpv))
    THEN
        RAISE EXCEPTION 'Viga, periodi kontrol. palk kinni';
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
                       pk.minsots,
                       pk.objekt
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
                           pk.tunnusid::INTEGER AS tunnusid,
                           pk.objekt            AS objekt
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
                           v_lib.objekt,
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
SELECT * from palk.gen_palkoper(66, '{"osakond_ids":[124172],
				"isik_ids":[30128],
				"lib_ids":[135269,135282,135384,135385,135412,135431,135432,135433,135434,135435,135436,135437,135438,135439,135440,135496,135747,135845,135848,135849,135902,135983,136095,136205,136321,136324,136396,136402,136404,136405,136406,136407,136408,136409,136410,136411,136412,136413,136414,136415,136416,136417,136418,136753,136795,136797,136798,136799,136800,136805,136806,136807,136808,136809,136810,136812,136814,136815,136816,136817,136849,136850,136851,136852,136853,136903,136906,136909,136981,136983,136988,136990,136995,137072,137073,137074,137075,137078,137079,137082,137084,137085,137534,137553,137762,137763,137764,137765,137766,137767,137769,137770,137793,137796,137797,137799,137833,137854,137907,137913,137922,137923,138015,138030,138032,138070,138074,138082,138083,138086,138087,138233,138234,138235,138330,138443,138470,138680,138687,138711,138712,138714,138715,138729,138731,138919,139199,139200,139202,139203,139205,139676,139677,139975,140151,140282,140283,140336,140704,140897,140898,140903,141051,141052,141079,141081,141082,141485,141492,141573,141598,141600,141699,141731,141735,141886,141902,142040,142087,142150,142151,142637,142638,142639,142640,142648,142649,143027,143490,143491,144110,144190,144191,144192,144193,144232,144233,144234,144914,145109,145220,145222,145230,145232,145233,145252,145253,145254,145255,145258,145260,145265,145497,145511,145674,145675,145676,145677,145679,145792,146000,146112,146203,146212,146215,146217,146219,146220,146221,146222,146223,146224,146225,146226,146227,146228,146229,146230,146231,146367,146368,146369,146460,146461,146513,146536,146539,146541,146578,146580,146582,146583,146586,146587,146588,146589,146591,146592,146593,146595,146596,146622,146626,146629,146630,146632,146633,146674,146742,146743,146748,146749,146752,146818,146822,146823,146824,146825,146827,146828,146829,147330,147531,147532,147533,147534,147536,147537,147554,147557,147558,147559,147561,147643,147644,147647,147648,147660,147766,147767,147768,147769,147818,147960,148104,148260,148340,148374,148590,148603,148604,148627,148628,148629,148630,148838,148884,148890,148892,149045,149237,149453,149801,149917,149924,149925,149961,150200,150249,150294,150436,150458,150545,150552,150710,150711,150734,151148,151159,151279,151391,151392,151393,151727,151801,151840,151841,151865,151870,152314,152322,152330,152333,152334,152362,152363,152462,152463,152668,153677,153803,153804,153852,153853,154567,154597,244092,244707,244964,244970,244973,247244,247311,247348,247542,251412,251413,251414,251415,251416,251417,251418,251419,251420,251421,251422,255361,260321,260322,262533,262535,264856,272604],
				"kpv":20240229,
				"kas_kustuta":true,
				"kas_arvesta_minsots":true,
				"dokprop":1024
				}')

*/