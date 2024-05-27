DROP FUNCTION IF EXISTS docs.tulude_mahakandmine(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION docs.tulude_mahakandmine(IN user_id INTEGER,
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
    l_viitenumber   TEXT;
    l_jaak          NUMERIC = 0; -- сумма долга в учреждении
    doc_id_kreedit  INTEGER;
    doc_id_new      INTEGER;

    l_rekvId        INTEGER = (SELECT rekvid
                               FROM ou.userid
                               WHERE id = user_id); -- ид учреждения, откуда списываем долг

    json_rea        JSONB   = '[]'::JSONB;
    json_object     JSONB;
    l_user_id       INTEGER;
    l_nom_id        INTEGER;
    v_nom_rea       RECORD;

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
                               WHERE parentid IN (SELECT rekvid
                                                  FROM ou.userid
                                                  WHERE id = user_id)
                                 AND kassa = 1
                               ORDER BY default_ DESC
                               LIMIT 1);
    l_yksus         TEXT;

    l_rekv_siht     INTEGER = l_rekvId; -- все сальдо переводим сюда
    l_nom_kood_siht TEXT    = 'TULUDE_MAHAKANDMINE'; -- код услуги в целевом учреждении

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
BEGIN

    doc_type_id = 'ARV';

    IF l_laps_id IS NULL OR l_rekvid IS NULL
    THEN
        result = 0;
        error_message = 'Laps ei leidnud';
        error_code = 1;
        RAISE EXCEPTION '%', error_message;

    END IF;

    -- считаем сумму переплаты

    SELECT -1 * qry.jaak
    INTO l_jaak
    FROM lapsed.kaive_aruanne(l_rekvId, l_kpv, l_kpv) qry
    WHERE viitenumber = lapsed.get_viitenumber(l_rekvId, l_laps_id)
      AND jaak < 0; -- только минус (переплата)

    RAISE NOTICE 'l_jaak %, l_rekvId %, l_kpv %, l_laps_id %, user_id %', l_jaak, l_rekvId, l_kpv,l_laps_id, user_id;

    IF (coalesce(l_jaak, 0)) = 0
    THEN
        -- выходим
        error_code = 0;
        error_message = 'Jääk = 0';
        result = 0;
        RETURN;
    END IF;

    -- ищем документ - основу
    SELECT id
    INTO doc_id_kreedit
    FROM lapsed.cur_lapsed_mk mk
    WHERE mk.rekvid = l_rekvId
      AND mk.laps_id = l_laps_id
      AND mk.jaak > 0
    ORDER BY kpv DESC
    LIMIT 1;

    IF doc_id_kreedit IS NULL
    THEN
        -- выходим
        error_code = 0;
        error_message = 'Puudub MK, kus jääk > 0';
        result = 0;
        RETURN;

    END IF;

    -- Так как учреждение было закрыто путем слияния с другим учреждением, то сначала делаем перенос сальдо из базы закрытого учреждения в базу учреждения, куда "слили" закрытое учреждение:
    -- делаем перенос платежа


    IF l_rekvId IN (81, 82, 85)
        -- только для закрытых учрежденией
    THEN
        l_rekv_siht = 9;

        -- получим ВН для целевого учреждения
        l_viitenumber = lapsed.get_viitenumber(l_rekv_siht, l_laps_id);

        json_object =
                jsonb_build_object('mk_id', doc_id_kreedit, 'maksepaev', l_kpv, 'viitenumber', l_viitenumber, 'kogus',
                                   l_jaak, 'tyyp', 'jaak_ulekandmine');

        doc_id_new = (SELECT um.result FROM docs.ulekanne_makse(user_id, json_object) um);

        IF coalesce(doc_id_new, 0) = 0
        THEN
            -- платеж не создан, ошибка
            error_code = 0;
            error_message = 'Uus MK salvestamine ebaõnnestus, viga';
            result = 0;
            RAISE EXCEPTION 'Viga: %', error_message;
        END IF;

    END IF;

    -- готовим счет на списание доходов в базе ТП
    -- ищем ном
    l_nom_id =
            (SELECT id
             FROM libs.nomenklatuur n
             WHERE kood = l_nom_kood_siht
               AND rekvid = l_rekv_siht
               AND status < 3
             LIMIT 1);


    -- создаем параметры для счета на сумму долга в базе ТП

    -- ищем нового пользователя в новом учреждении
    SELECT id
    INTO l_user_id
    FROM ou.userid
    WHERE rekvid = l_rekv_siht
      AND kasutaja IN (SELECT kasutaja
                       FROM ou.userid
                       WHERE id = user_id)
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

    -- ищем группу
    l_yksus = (SELECT properties ->> 'yksus'
               FROM lapsed.lapse_kaart
               WHERE parentid = l_laps_id
                 AND rekvid = l_rekv_siht
                 AND staatus < 3
               ORDER BY (properties ->> 'lopp_kpv')::DATE DESC
               LIMIT 1);

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
    WHERE kood = l_nom_kood_siht
      AND rekvid = l_rekv_siht
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


    -- создаем счет в учреждении на сумму долга

    json_object = (SELECT to_jsonb(row)
                   FROM (SELECT 0                            AS id,
                                NULL::TEXT                   AS number,
                                l_doklausend_id              AS doklausid,
                                0                            AS liik,
                                l_kpv                        AS kpv,
                                (l_kpv +
                                 coalesce(
                                         (SELECT tahtpaev
                                          FROM ou.config
                                          WHERE rekvid = l_rekv_siht
                                          LIMIT 1),
                                         20)::INTEGER)::DATE AS tahtaeg,
                                l_asutus_id                  AS asutusid,
                                l_aa                         AS aa,
                                l_laps_id                    AS lapsid,
                                'SALDO ÜLEKANNE'             AS muud,
                                json_rea                     AS "gridData") row);

    -- подготавливаем параметры для создания счета

    json_object = jsonb_build_object('id', 0, 'data', json_object);

    -- сохраняем кредитовый счет
    doc_id_new = docs.sp_salvesta_arv(json_object :: JSON, l_user_id, l_rekv_siht);

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
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.tulude_mahakandmine(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.tulude_mahakandmine(INTEGER, JSONB) TO dbpeakasutaja;


/*
SELECT docs.tulude_mahakandmine(5407, '{"laps_id":7200, "kpv":"20240531"}')

0940142536-0840142539

select * from ou.rekv where id = 94
*/