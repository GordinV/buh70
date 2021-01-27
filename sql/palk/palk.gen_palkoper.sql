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
        ORDER BY t.pohikoht DESC, t.koormus desc
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
                       pk.tunnus,
                       pk.tunnusid::INTEGER         AS tunnusid
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
SELECT * from palk.gen_palkoper(1, '{"kpv":20210131,"leping_ids": [20016,27828]}')
SELECT palk.gen_palkoper(1, '{"kpv":20180508,"leping_ids": [3,4],"lib_ids":[525, 526, 528, 529, 530, 531, 524]}')
SELECT palk.gen_palkoper(1, '{"kpv":20180508,"isik_ids": [56,57],"osakond_ids":[374,377],"lib_ids":[525, 526, 528, 529, 530, 531, 524]}')

SELECT palk.gen_palkoper(4921, '{"osakond_ids":[214005,214005,214005],
				"isik_ids":[14719],
				"lib_ids":[135159,135160,135230,135255,135392,135446,135455,135532,135619,135675,135680,135887,135910,135912,135916,135918,135927,135934,135938,135948,135957,135973,135987,135997,136001,136004,136035,136045,136047,136053,136076,136100,136125,136134,136135,136144,136163,136169,136176,136190,136201,136237,136243,136264,136284,136292,136317,136323,136331,136338,136344,136362,136367,136383,136433,136479,136576,136746,136781,136957,136959,137188,137340,137542,137674,137760,137878,137895,137962,137965,138065,138206,138207,138485,138517,138661,138688,138870,138998,139224,139429,139469,139509,139599,139622,139642,139685,139703,139783,139932,139958,140044,140072,140127,140510,140517,140553,140558,140596,140597,140598,140611,140622,140652,140661,140665,140670,140674,140682,140688,140695,140710,140715,140721,140805,140901,140934,140974,141278,141284,141287,141294,141298,141304,141310,141315,141320,141325,141338,141344,141520,141681,141701,141744,141756,141773,141792,141828,141832,141841,141872,141970,141976,141977,141978,141992,142011,142049,142062,142091,142152,142153,142154,142155,142156,142160,142161,142162,142164,142165,142166,142167,142168,142203,142235,142241,142255,142260,142266,142288,142289,142291,142297,142299,142306,142307,142308,142309,142310,142311,142312,142313,142314,142315,142316,142317,142318,142319,142484,142574,142594,142608,142612,142622,142632,142687,142714,142725,142739,142774,142866,142870,143020,143026,143032,143152,143155,143159,143162,143424,143428,143433,143653,143657,144034,144092,144132,144147,144152,144211,144336,144357,144360,144371,144572,144598,144608,144654,144673,144683,144686,144699,144703,144709,144724,144731,144734,144740,144745,144752,144757,144762,144809,144851,144883,144943,145075,145081,145083,145276,145285,145321,145459,145493,145593,145618,145740,145743,145746,145767,145801,145808,145815,145828,145839,145850,145863,145877,145884,145961,145985,145994,146003,146006,146008,146052,146066,146083,146095,146145,146151,146169,146191,146200,146249,146297,146300,146475,146519,146532,146635,146724,146734,146847,147715,147932,147946,147985,148162,148253,148410,148418,148496,148554,148563,148587,148598,148618,148670,148713,148742,148795,148798,148801,148925,149184,149227,149281,149290,149336,149430,149460,149541,149667,149780,149818,149903,149931,150132,150144,150147,150150,150158,150162,150167,150174,150176,150181,150187,150201,150204,150206,150222,150223,150224,150225,150237,150261,150271,150291,150299,150329,150330,150338,150354,150375,150598,150943,150964,150987,150998,151003,151013,151145,151248,151254,151267,151396,151408,151429,151491,151494,151503,151508,151514,151526,151532,151539,151552,151561,151573,151672,151684,151685,151728,151739,151747,151842,151845,151846,151853,151856,151857,151858,151859,151908,151913,151918,151933,151953,151966,151967,151968,151969,151970,151971,151972,151973,151974,151980,151983,152023,152030,152160,152266,152269,152283,152297,152302,152329,152336,152361,152379,152386,152394,152405,152409,152442,152470,152475,152496,152498,152696,153061,153074,153079,153091,153096,153098,153104,153108,153141,153755,153807,153811,153815,153830,153983,153987,153991,153995,154004,154015,154018,154195,154210,154266,154290,154294,154300,154306,154309,154319,154329,154335,154339,154344,154347,154352,154366,154371,154373,154380,154391,154400,154413,154417,154420,154455,154459,154553,154579,154600,213998,243577,243578,243640,243668,243682,243694,243700,243703,243708,243717,243718,243725,243736,243741,243748,243750,243754,243763,243773,243776,243782,243793,243796,243816,243829,243831,243845,243848,243850,243864,243876,243886,243904,243906,243918,243929,243950,243958,243969,243976,243994,244002,244009,244014,244054,244057,244065,244075,244084,244094,244101,244116,244158,244179,244181,244186,244192,244196,244197,244198,244199,244200,244210,244211,244212,244226,244228,244231,244238,244239,244244,244251,244253,244255,244259,244267,244268,244269,244308,244316,244336,244379,244411,244421,244422,244438,244463,244480,244497,244500,244508,244517,244525,244542,244554,244572,244587,244617,244628,244648,244666,244670,244696,244700,244702,244731,244741,244777,244789,244792,244819,244830,244857,244867,244879,244899,244914,244922,244923,244938,244950,244959,245008,245063,245083,245088,245093,245118,245146,245151,245153,245156,245158,245165,245175,245183,245190,245198,245207,245214,245221,245228,245231,245239,245247,245254,245262,245270,245277,245282,245286,245293,245295,245297,245301,245310,245334,245347,245359,245366,245399,245416,245430,245445,245454,245460,245465,245472,245477,245486,245494,245502,245509,245523,245530,245545,245547,245562,245578,245585,245591,245598,245608,245615,245618,245632,245641,245650,245658,245666,245675,245684,245699,245705,245711,245717,245722,245731,245745,245748,245760,245770,245778,245786,245794,245802,245807,245813,245821,245831,245840,245855,245858,245864,245870,245879,245884,245894,245901,245909,245917,245926,245931,245944,245949,245957,245976,245985,245995,246002,246009,246018,246026,246032,246039,246054,246062,246070,246084,246089,246096,246103,246111,246118,246133,246141,246150,246158,246167,246174,246180,246189,246207,246213,246221,246233,246241,246249,246255,246264,246271,246277,246283,246300,246307,246319,246327,246344,246347,246357,246365,246379,246394,246405,246413,246429,246441,246534,246542,246551,246558,246566,246569,246572,246579,246590,246598,246605,246616,246625,246633,246643,246653,246673,246679,246685,246691,246697,246706,246718,246737,246744,246752,246764,246766,246772,246780,246786,246791,246797,246804,246813,246841,246849,246857,246874,246883,246903,246933,246943,246993,247004,247024,247106,247203,247231,247238,247323,247326,247355,247362,247375,247381,247423,247433,247436,247438,247442,247450,247470,247510,247523,247545,247552,247559,247619,247636,247644,247723,247761,247765,247782,247811],
				"kpv":20210131,
				"kas_kustuta":true,
				"kas_arvesta_minsots":true,
				"dokprop":1495
				}')

select * from ou.userid where kasutaja = 'vlad' and rekvid  = 121

SELECT * from palk.gen_palkoper(1, '{"leping_ids": [20016,27828], "kas_kustuta":true}')



*/