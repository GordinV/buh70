DROP FUNCTION IF EXISTS docs.ulekanne_volg(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.ulekanne_volg(IN user_id INTEGER,
                                              IN params JSONB,
                                              OUT error_code INTEGER,
                                              OUT result INTEGER,
                                              OUT doc_type_id TEXT,
                                              OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_laps_id       INTEGER = params ->> 'laps_id'; -- на ком долг
    l_kpv           DATE    = params ->> 'kpv'; -- долг на дату
    l_viitenumber   TEXT    = params ->> 'viitenumber'; -- кому долг переносится
    l_summa         NUMERIC = coalesce((params ->> 'kogus')::NUMERIC, 0);
    l_jaak          NUMERIC = 0; -- сумма долга в учреждении
    l_jaak_inf3     NUMERIC = 0; -- часть инф3 в долге
    doc_id_kreedit  INTEGER;
    doc_id_new      INTEGER;
    l_dok           TEXT    = 'ARV';
    l_dokprop_id    INTEGER;

    l_rekvId_new    INTEGER = (SELECT rekv_id
                               FROM lapsed.get_rekv_id_from_viitenumber(l_viitenumber)); -- ид учреждения, куда отписываем долг

    l_rekvId        INTEGER = (SELECT rekvid
                               FROM ou.userid
                               WHERE id = user_id); -- ид учреждения, откуда списываем долг

    v_mk            RECORD ;
    v_mk1           RECORD ;
    json_rea        JSONB   = '[]'::JSONB;
    v_params        RECORD;
    json_object     JSONB;
    l_user_id       INTEGER;
    l_aa_id         INTEGER;
    l_tunnus        TEXT;
    l_nom_id        INTEGER;
    l_nom_inf3_id   INTEGER;
    v_nom_rea       RECORD;
    v_new_nom       RECORD;
    kas_eritunnus   BOOLEAN;
    l_db_konto      TEXT    = '10300029'; -- согдасно описанию отдела культуры
    l_doklausend_id INTEGER = (SELECT dp.id
                               FROM libs.dokprop dp
                                        INNER JOIN libs.library l ON l.id = dp.parentid
                               WHERE dp.rekvid = l_rekvid
                                 AND (dp.details ->> 'konto')::TEXT = l_db_konto::TEXT
                                 AND l.kood = 'ARV'
                               ORDER BY dp.id DESC
                               LIMIT 1
    );

    l_asutus_id     INTEGER = (SELECT asutusid
                               FROM lapsed.vanem_arveldus v
                                        INNER JOIN libs.asutus a ON a.id = v.asutusid
                               WHERE v.parentid = l_laps_id
                                 AND v.rekvid = l_rekvid
                                 AND arveldus
                               ORDER BY v.id DESC
                               LIMIT 1);

    l_aa            TEXT    = (SELECT arve
                               FROM ou.aa
                               WHERE parentid IN (SELECT rekvid FROM ou.userid WHERE id = user_id)
                                 AND kassa = 1
                               ORDER BY default_ DESC
                               LIMIT 1);
    l_yksus         TEXT;

    v_arved         RECORD;
BEGIN

    doc_type_id = 'ARV';
    -- контроль длины
    IF len(l_viitenumber) <> 10
    THEN
        -- ошибка на ВН
        result = 0;
        error_message = 'Viitenumber vigane';
        error_code = 1;

        RAISE EXCEPTION 'Vale viitenumber, < 10';
    END IF;

    -- получим ид ребенка
    l_laps_id = left(right(l_viitenumber::TEXT, 7), 6)::INTEGER;

    IF l_laps_id IS NULL OR l_rekvid IS NULL
    THEN
        result = 0;
        error_message = 'Laps ei leidnud või viitenumber vigane';
        error_code = 1;
        RAISE EXCEPTION '%', error_message;

    END IF;

    -- считаем сумму долга, вкл. сумму INF3
    SELECT qry.jaak, qry.jaak_inf3
    INTO l_jaak, l_jaak_inf3
    FROM lapsed.kaive_aruanne(l_rekvId, l_kpv, l_kpv) qry
    WHERE viitenumber = lapsed.get_viitenumber(l_rekvId, l_laps_id);

    RAISE NOTICE 'l_jaak %, l_jaak_inf3 %, l_rekvId %, l_kpv %, l_laps_id %, user_id %', l_jaak, l_jaak_inf3, l_rekvId, l_kpv,l_laps_id, user_id;

    -- вычитаем из долга, долю инф3
    l_jaak = l_jaak - l_jaak_inf3;


    IF (coalesce(l_jaak, 0) + coalesce(l_jaak_inf3, 0)) = 0
    THEN
        -- выходим
        error_code = 0;
        error_message = 'Võlg <= 0';
        result = 0;
        RETURN;
    END IF;

    -- готовим кредитовый счет
    -- ищем ном для не инф3 услуги
    l_nom_id =
            (SELECT id FROM libs.nomenklatuur n WHERE kood = '888888-001' AND rekvid = l_rekvId AND status < 3 LIMIT 1);
    -- ищем ном для инф3 услуги
    l_nom_inf3_id =
            (SELECT id FROM libs.nomenklatuur n WHERE kood = '888888-002' AND rekvid = l_rekvId AND status < 3 LIMIT 1);

    IF l_jaak > 0
    THEN

        FOR v_arved IN
            WITH docs AS (
                SELECT a.jaak AS volg, lapsed.get_inf3_jaak(a.id, l_kpv) AS inf3_jaak, a.kpv
                FROM lapsed.cur_laste_arved a
                WHERE a.laps_id = l_laps_id
                  AND rekvid = l_rekvId
                  AND a.jaak > 0
            )
            SELECT volg - inf3_jaak AS jaak, inf3_jaak, volg
            FROM docs
            ORDER BY kpv
            LOOP
                SELECT n.id                                              AS nomid,
                       1                                                 AS kogus,
                       -1 * v_arved.jaak                                 AS hind,
                       -1 * v_arved.jaak                                 AS summa,
                       0::NUMERIC                                        AS vat,
                       (n.properties::JSONB ->> 'konto')::VARCHAR(20)    AS konto,
                       (n.properties::JSONB ->> 'projekt')::VARCHAR(20)  AS projekt,
                       (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)   AS tunnus,
                       (n.properties::JSONB ->> 'tegev')::VARCHAR(20)    AS tegev,
                       (n.properties::JSONB ->> 'allikas')::VARCHAR(20)  AS allikas,
                       (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20) AS rahavoog,
                       (n.properties::JSONB ->> 'artikkel')::VARCHAR(20) AS artikkel
                INTO v_nom_rea
                FROM libs.nomenklatuur n
                WHERE kood = '888888-001'
                  AND rekvid = l_rekvId
                  AND status < 3
                LIMIT 1;

                -- формируем строку
                json_rea = json_rea::JSONB || (SELECT row_to_json(row)
                                               FROM (SELECT v_nom_rea.nomid    AS nomid,
                                                            v_nom_rea.kogus    AS kogus,
                                                            v_nom_rea.hind,
                                                            v_nom_rea.summa    AS kbmta,
                                                            0                  AS kbm,
                                                            v_nom_rea.summa    AS summa,
                                                            v_nom_rea.tegev    AS kood1,
                                                            v_nom_rea.allikas  AS kood2,
                                                            v_nom_rea.rahavoog AS kood3,
                                                            v_nom_rea.artikkel AS kood5,
                                                            v_nom_rea.konto    AS konto,
                                                            v_nom_rea.tunnus,
                                                            v_nom_rea.projekt,
                                                            ''                 AS yksus,
                                                            ''                 AS all_yksus,
                                                            'SALDO ÜLEKANNE'   AS muud,
                                                            '800699'           AS tp) row) :: JSONB;

                -- строка на инф3 часть долга
                IF v_arved.inf3_jaak > 0
                THEN
                    SELECT n.id                                              AS nomid,
                           1                                                 AS kogus,
                           -1 * v_arved.inf3_jaak                                  AS hind,
                           -1 * v_arved.inf3_jaak                                  AS summa,
                           0::NUMERIC                                        AS vat,
                           (n.properties::JSONB ->> 'konto')::VARCHAR(20)    AS konto,
                           (n.properties::JSONB ->> 'projekt')::VARCHAR(20)  AS projekt,
                           (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)   AS tunnus,
                           (n.properties::JSONB ->> 'tegev')::VARCHAR(20)    AS tegev,
                           (n.properties::JSONB ->> 'allikas')::VARCHAR(20)  AS allikas,
                           (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20) AS rahavoog,
                           (n.properties::JSONB ->> 'artikkel')::VARCHAR(20) AS artikkel
                    INTO v_nom_rea
                    FROM libs.nomenklatuur n
                    WHERE kood = '888888-002'
                      AND rekvid = l_rekvId
                      AND status < 3
                    LIMIT 1;

                    -- формируем строку
                    json_rea = json_rea::JSONB || (SELECT row_to_json(row)
                                                   FROM (SELECT v_nom_rea.nomid    AS nomid,
                                                                v_nom_rea.kogus    AS kogus,
                                                                v_nom_rea.hind,
                                                                v_nom_rea.summa    AS kbmta,
                                                                0                  AS kbm,
                                                                v_nom_rea.summa    AS summa,
                                                                v_nom_rea.tegev    AS kood1,
                                                                v_nom_rea.allikas  AS kood2,
                                                                v_nom_rea.rahavoog AS kood3,
                                                                v_nom_rea.artikkel AS kood5,
                                                                v_nom_rea.konto    AS konto,
                                                                v_nom_rea.tunnus,
                                                                v_nom_rea.projekt,
                                                                ''                 AS yksus,
                                                                ''                 AS all_yksus,
                                                                'SALDO ÜLEKANNE'   AS muud,
                                                                '800699'           AS tp) row) :: JSONB;
                END IF;

                -- создаем счет в учреждении на сумму долга

                json_object = (SELECT to_jsonb(row)
                               FROM (SELECT 0                                AS id,
                                            NULL::TEXT                       AS number,
                                            l_doklausend_id                  AS doklausid,
                                            0                                AS liik,
                                            l_kpv                            AS kpv,
                                            (l_kpv +
                                             coalesce(
                                                         (SELECT tahtpaev FROM ou.config WHERE rekvid = l_rekvid LIMIT 1),
                                                         20)::INTEGER)::DATE AS tahtaeg,
                                            l_asutus_id                      AS asutusid,
                                            l_aa                             AS aa,
                                            l_laps_id                        AS lapsid,
                                            'SALDO ÜLEKANNE'                 AS muud,
                                            json_rea                         AS "gridData") row);

                -- подготавливаем параметры для создания счета

                json_object = jsonb_build_object('id', 0, 'data', json_object);

                -- сохраняем кредитовый счет
                doc_id_kreedit = docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid);

                IF doc_id_kreedit IS NULL OR empty(doc_id_kreedit)
                THEN
                    RAISE EXCEPTION 'Viga:,kreedit arve salvestamine ebaõnnestus';
                END IF;

                -- контировка
                PERFORM docs.gen_lausend_arv(doc_id_kreedit, user_id);
            END LOOP;
    END IF;

    -- проверяем счета, по которым перенос долга
    FOR v_arved IN
        SELECT id, docs.sp_update_arv_jaak(id) AS jaak, number
        FROM lapsed.cur_laste_arved
        WHERE rekvid = l_rekvId
          AND laps_id = l_laps_id
          AND jaak <> 0
        LOOP
            IF v_arved.jaak > 0
            THEN
                -- ошибка при переносе
                RAISE NOTICE 'Viga, arved tasumata, number %', v_arved.number;
            END IF;
        END LOOP;

    -- создаем параметры для счета на сумму долга в целевом учреждении

    -- ищем нового пользователя в новом учреждении
    SELECT id
    INTO l_user_id
    FROM ou.userid
    WHERE rekvid = l_rekvid_new
      AND kasutaja IN (SELECT kasutaja FROM ou.userid WHERE id = user_id)
      AND status <> 3
    LIMIT 1;


    -- контроль
    IF l_user_id IS NULL
    THEN
        result = 0;
        error_message = 'Kasutajal puudub õigused siht asutusel';
        error_code = 1;
        RAISE EXCEPTION '%',error_message;
    END IF;

    -- обнулим параметры
    json_rea = '[]'::JSONB;

    -- ребенок на которого переводим долг
    l_laps_id = lapsed.get_laps_from_viitenumber(l_viitenumber);

    -- ищем группу
    l_yksus = (SELECT properties ->> 'yksus'
               FROM lapsed.lapse_kaart
               WHERE parentid = l_laps_id
                 AND rekvid = l_rekvId_new
                 AND staatus < 3
               ORDER BY (properties ->> 'lopp_kpv')::DATE DESC
               LIMIT 1);

    IF l_jaak > 0
    THEN
        SELECT n.id                                              AS nomid,
               1                                                 AS kogus,
               l_jaak                                            AS hind,
               l_jaak                                            AS summa,
               0::NUMERIC                                        AS vat,
               (n.properties::JSONB ->> 'konto')::VARCHAR(20)    AS konto,
               (n.properties::JSONB ->> 'projekt')::VARCHAR(20)  AS projekt,
               (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)   AS tunnus,
               (n.properties::JSONB ->> 'tegev')::VARCHAR(20)    AS tegev,
               (n.properties::JSONB ->> 'allikas')::VARCHAR(20)  AS allikas,
               (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20) AS rahavoog,
               (n.properties::JSONB ->> 'artikkel')::VARCHAR(20) AS artikkel
        INTO v_nom_rea
        FROM libs.nomenklatuur n
        WHERE kood = '888888-001'
          AND rekvid = l_rekvId_new
          AND status < 3
        LIMIT 1;

        -- формируем строку
        json_rea = json_rea::JSONB || (SELECT row_to_json(row)
                                       FROM (SELECT v_nom_rea.nomid    AS nomid,
                                                    v_nom_rea.kogus    AS kogus,
                                                    v_nom_rea.hind,
                                                    v_nom_rea.summa    AS kbmta,
                                                    0                  AS kbm,
                                                    v_nom_rea.summa    AS summa,
                                                    v_nom_rea.tegev    AS kood1,
                                                    v_nom_rea.allikas  AS kood2,
                                                    v_nom_rea.rahavoog AS kood3,
                                                    v_nom_rea.artikkel AS kood5,
                                                    v_nom_rea.konto    AS konto,
                                                    v_nom_rea.tunnus,
                                                    v_nom_rea.projekt,
                                                    l_yksus            AS yksus,
                                                    ''                 AS all_yksus,
                                                    'SALDO ÜLEKANNE'   AS muud,
                                                    '800699'           AS tp) row) :: JSONB;
    END IF;

    -- строка на инф3 часть долга
    IF l_jaak_inf3 > 0
    THEN
        SELECT n.id                                              AS nomid,
               1                                                 AS kogus,
               l_jaak_inf3                                       AS hind,
               l_jaak_inf3                                       AS summa,
               0::NUMERIC                                        AS vat,
               (n.properties::JSONB ->> 'konto')::VARCHAR(20)    AS konto,
               (n.properties::JSONB ->> 'projekt')::VARCHAR(20)  AS projekt,
               (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)   AS tunnus,
               (n.properties::JSONB ->> 'tegev')::VARCHAR(20)    AS tegev,
               (n.properties::JSONB ->> 'allikas')::VARCHAR(20)  AS allikas,
               (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20) AS rahavoog,
               (n.properties::JSONB ->> 'artikkel')::VARCHAR(20) AS artikkel
        INTO v_nom_rea
        FROM libs.nomenklatuur n
        WHERE kood = '888888-002'
          AND rekvid = l_rekvId_new
          AND status < 3
        LIMIT 1;

        -- формируем строку
        json_rea = json_rea::JSONB || (SELECT row_to_json(row)
                                       FROM (SELECT v_nom_rea.nomid    AS nomid,
                                                    v_nom_rea.kogus    AS kogus,
                                                    v_nom_rea.hind,
                                                    v_nom_rea.summa    AS kbmta,
                                                    0                  AS kbm,
                                                    v_nom_rea.summa    AS summa,
                                                    v_nom_rea.tegev    AS kood1,
                                                    v_nom_rea.allikas  AS kood2,
                                                    v_nom_rea.rahavoog AS kood3,
                                                    v_nom_rea.artikkel AS kood5,
                                                    v_nom_rea.konto    AS konto,
                                                    v_nom_rea.tunnus,
                                                    v_nom_rea.projekt,
                                                    l_yksus            AS yksus,
                                                    ''                 AS all_yksus,
                                                    'SALDO ÜLEKANNE'   AS muud,
                                                    '800699'           AS tp) row) :: JSONB;
    END IF;

    -- создаем счет в учреждении на сумму долга

    json_object = (SELECT to_jsonb(row)
                   FROM (SELECT 0                                AS id,
                                NULL::TEXT                       AS number,
                                l_doklausend_id                  AS doklausid,
                                0                                AS liik,
                                l_kpv                            AS kpv,
                                (l_kpv +
                                 coalesce(
                                             (SELECT tahtpaev FROM ou.config WHERE rekvid = l_rekvid_new LIMIT 1),
                                             20)::INTEGER)::DATE AS tahtaeg,
                                l_asutus_id                      AS asutusid,
                                l_aa                             AS aa,
                                l_laps_id                        AS lapsid,
                                'SALDO ÜLEKANNE'                 AS muud,
                                json_rea                         AS "gridData") row);

    -- подготавливаем параметры для создания счета

    json_object = jsonb_build_object('id', 0, 'data', json_object);

    -- сохраняем кредитовый счет
    doc_id_new = docs.sp_salvesta_arv(json_object :: JSON, l_user_id, l_rekvId_new);

    IF doc_id_new IS NULL OR empty(doc_id_new)
    THEN
        RAISE EXCEPTION 'Viga:, arve salvestamine ebaõnnestus';
    END IF;

    -- контировка
    PERFORM docs.gen_lausend_arv(doc_id_new, l_user_id);

    -- списываем долг у просроченных счетов
    result = doc_id_new;
    RETURN;
/*EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
*/
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.ulekanne_volg(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.ulekanne_volg(INTEGER, JSONB) TO dbpeakasutaja;


/*
SELECT docs.ulekanne_volg(5419, '{"laps_id":14253, "kpv":"20240531", "viitenumber":"0840142539"}')

0940142536-0840142539

select * from ou.rekv where id = 94
*/