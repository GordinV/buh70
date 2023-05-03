DROP FUNCTION IF EXISTS docs.ulekanne_makse(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.ulekanne_makse(IN user_id INTEGER,
                                               IN params JSONB,
                                               OUT error_code INTEGER,
                                               OUT result INTEGER,
                                               OUT doc_type_id TEXT,
                                               OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_mk_id       INTEGER = params ->> 'mk_id';
    l_maksepaev   DATE    = params ->> 'maksepaev';
    l_viitenumber TEXT    = params ->> 'viitenumber';
    l_summa       NUMERIC = coalesce((params ->> 'kogus')::NUMERIC, 0);
    mk_id         INTEGER;
    l_dok         TEXT    = 'SMK';
    l_dokprop_id  INTEGER;
    l_rekvId      INTEGER ;
    v_mk          RECORD ;
    v_mk1         RECORD ;
    json_mk1      JSON;
    l_laps_id     INTEGER;
    v_params      RECORD;
    json_object   JSON;
    l_user_id     INTEGER;
    l_aa_id       INTEGER;
    l_tunnus      TEXT;
BEGIN
    doc_type_id = 'SMK';

    -- контроль длины
    IF len(l_viitenumber) <> 10
    THEN
        -- ошибка на ВН
        result = 0;
        error_message = 'Viitenumber vigane';
        error_code = 1;

        RAISE EXCEPTION 'Vale viitenumber, < 10';
    END IF;


    -- читаем ссылку и ищем учреждение
    l_rekvid = substr(l_viitenumber, 3)::INTEGER;


    -- получим ид ребенка
    l_laps_id = left(right(l_viitenumber::TEXT, 7), 6)::INTEGER;

    IF l_laps_id IS NULL OR l_rekvid IS NULL
    THEN
        result = 0;
        error_message = 'Laps ei leidnud või viitenumber vigane';
        error_code = 1;
        RAISE EXCEPTION '%', error_message;

    END IF;

    -- ищем нового пользователя в новом учреждении
    SELECT id
    INTO l_user_id
    FROM ou.userid
    WHERE rekvid = l_rekvid
      AND kasutaja IN (SELECT kasutaja FROM ou.userid WHERE id = user_id )
      AND status <> 3
    LIMIT 1;


    -- контроль
    IF l_user_id IS NULL
    THEN
        result = 0;
        error_message = 'Kasutajal puudub õigused siht asutusel';
        error_code = 1;
        RAISE EXCEPTION '%',error_message;
        RETURN;
    END IF;


    -- копия исходного документа
    SELECT mk.*, l.parentid AS laps_id
    INTO v_mk
    FROM docs.mk mk
             INNER JOIN lapsed.liidestamine l ON l.docid = mk.parentid
    WHERE mk.parentid = l_mk_id
    LIMIT 1;

    -- ищем расч. счет в новом учреждении
    SELECT id
    INTO l_aa_id
    FROM ou.aa
    WHERE parentid = l_rekvid
      AND kassa = 1
      AND arve IN (SELECT arve FROM ou.aa WHERE id = v_mk.aaid)
    LIMIT 1;

    IF l_aa_id IS NULL
    THEN
        -- используем дефолтный расч. счет
        SELECT id INTO l_aa_id FROM ou.aa WHERE parentid = l_rekvid AND kassa = 1 ORDER BY default_ DESC LIMIT 1;
    END IF;


    SELECT 0                                                      AS id,
           nomid                                                  AS nomid,
           asutusid                                               AS asutusid,
           -1 * CASE WHEN l_summa = 0 THEN summa ELSE l_summa END AS summa,
           aa :: TEXT                                             AS aa,
           kood1,
           kood2,
           kood3,
           kood4,
           kood5,
           '103000'                                               AS konto,
           tp,
           tunnus,
           proj
    INTO v_mk1
    FROM docs.mk1
    WHERE parentid = v_mk.id
    LIMIT 1;

    -- контроль
    IF v_mk1 IS NULL
    THEN
        result = 0;
        error_message = 'Vale maksekorraldus, puudub või summa <= 0 ';
        error_code = 1;
        RAISE EXCEPTION '%',error_message;
    END IF;


    l_dokprop_id = (SELECT id
                    FROM com_dokprop l
                    WHERE (l.rekvId = l_rekvId OR l.rekvid IS NULL)
                      AND kood = l_dok
                    ORDER BY id DESC
                    LIMIT 1
    );

    json_mk1 = array_to_json((SELECT array_agg(row_to_json(v_mk1))));

    -- Обратное платежное поручение со знаком минус

    SELECT 0                                         AS id,
           v_mk.doklausid                            AS doklausid,
           v_mk.aaid                                 AS aa_id,
           NULL                                      AS arvid,
           v_mk.opt                                  AS opt,-- возврат платежа
           v_mk.viitenr                              AS viitenr,
           NULL                                      AS number,
           l_maksepaev                               AS kpv,
           l_maksepaev                               AS maksepaev,
           'Tagasimakse ' || coalesce(v_mk.selg, '') AS selg,
           NULL                                      AS muud,
           json_mk1                                  AS "gridData",
           v_mk.laps_id                              AS lapsid
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT 0        AS id,
                 v_params AS data) row;

    SELECT docs.sp_salvesta_mk(json_object :: JSON, user_id, v_mk.rekvid) INTO mk_id;

    IF mk_id IS NOT NULL AND mk_id > 0
    THEN
        result = mk_id;
        -- register
        PERFORM docs.gen_lausend_smk(mk_id, user_id);
    ELSE
        result = 0;
        error_message = 'Tagasimakse koostamise viga, ' + mk_id::TEXT;
        error_code = 1;
        RAISE EXCEPTION '%',error_message;
        RETURN;
    END IF;

    -- обратный платеж сформирован , создаем новый платеж в назначенном учреждении
    v_mk1.summa = -1 * v_mk1.summa;
    v_mk.laps_id = l_laps_id;
    v_mk.viitenr = l_viitenumber;
    v_mk.aaid = l_aa_id;

    -- правим признак
    IF (l_rekvId IN (SELECT id FROM ou.rekv WHERE parentid = 119 OR id = 119))
    THEN
        l_tunnus = (SELECT left(nimetus, 7) FROM ou.rekv WHERE id = l_rekvId);

        IF l_tunnus IS NOT NULL AND exists(SELECT id
                                           FROM libs.library
                                           WHERE rekvid = l_rekvid
                                             AND kood = l_tunnus
                                             AND status < 3
                                             AND library = 'TUNNUS')
        THEN
            v_mk1.tunnus = l_tunnus;
        END IF;
    END IF;


    -- параметры нового платежа
    json_mk1 = array_to_json((SELECT array_agg(row_to_json(v_mk1))));

    SELECT 0                                           AS id,
           l_dokprop_id                                AS doklausid,
           l_aa_id                                     AS aa_id,
           NULL                                        AS arvid,
           v_mk.opt                                    AS opt,-- возврат платежа
           v_mk.viitenr                                AS viitenr,
           NULL                                        AS number,
           l_maksepaev                                 AS kpv,
           l_maksepaev                                 AS maksepaev,
           'Ülekannemakse ' || coalesce(v_mk.selg, '') AS selg,
           NULL                                        AS muud,
           json_mk1                                    AS "gridData",
           l_laps_id                                   AS lapsid
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT 0        AS id,
                 v_params AS data) row;


    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT 0        AS id,
                 v_params AS data) row;

    SELECT docs.sp_salvesta_mk(json_object :: JSON, l_user_id, l_rekvid) INTO mk_id;

    IF mk_id IS NOT NULL AND mk_id > 0
    THEN
        result = mk_id;
        -- register
        PERFORM docs.gen_lausend_smk(mk_id, l_user_id);
    ELSE
        result = 0;
        error_message = 'Ülekannemakse koostamise viga, ' + mk_id::TEXT;
        error_code = 1;
        RAISE EXCEPTION '%',error_message;
    END IF;

    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.ulekanne_makse(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.ulekanne_makse(INTEGER, JSONB) TO dbpeakasutaja;


/*
SELECT docs.ulekanne_makse(6973, '{"mk_id":4739819, "maksepaev":"20230406", "viitenumber":"1000086117","kogus":119}')

*/