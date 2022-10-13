-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.import_alg_saldo_deebet(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_alg_saldo_deebet(IN data JSONB,
                                                          IN user_id INTEGER,
                                                          IN user_rekvid INTEGER,
                                                          OUT result INTEGER,
                                                          OUT error_code INTEGER,
                                                          OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid        INTEGER;
    l_asutus_id     INTEGER ;
    l_laps_id       INTEGER;

    l_doklausend_id INTEGER;
    l_liik          INTEGER = 0;
    json_object     JSONB;
    json_record     RECORD;
    l_json_arve     JSON;
    json_arvrea     JSONB   = '[]';

    l_tp            TEXT    = '800699'; -- (SELECT tp FROM libs.asutus a WHERE id = l_asutus_id);

    l_arv_id        INTEGER = 0;
    l_number        TEXT;
    l_arve_summa    NUMERIC = 0;
    l_aa            TEXT;
    v_details       RECORD;
    v_nom           RECORD;
    l_count         INTEGER = 0;
    l_user_id       INTEGER;
    l_kpv           DATE    = '2022-08-31';

BEGIN


    FOR json_record IN
        WITH qryJsons AS (
            SELECT *
            FROM jsonb_to_recordset(data::JSONB)
                     AS x(yksus TEXT, laps_ik TEXT, vanem_ik TEXT, summa TEXT, db TEXT, kood TEXT,
                          inf3 TEXT, grupp TEXT)
        )
        SELECT DISTINCT yksus, laps_ik, vanem_ik
        FROM qryJsons
        LOOP
            RAISE NOTICE 'yksus %, laps_ik %, vanem_ik %', json_record.yksus, json_record.laps_ik, json_record.vanem_ik;

            l_laps_id = (SELECT id
                         FROM lapsed.laps l
                         WHERE l.isikukood = json_record.laps_ik
                           AND l.staatus <> 3
                         LIMIT 1);


            -- ищем котр-агента
            l_asutus_id = (
                SELECT a.id
                FROM libs.asutus a
                         LEFT OUTER JOIN lapsed.vanemad v ON v.asutusid = a.id AND v.staatus <> 3
                WHERE a.regkood = json_record.vanem_ik
                  AND v.parentid = l_laps_id
                ORDER BY v.id DESC
                LIMIT 1
            );

            IF (l_asutus_id IS NULL OR l_laps_id IS NULL)
            THEN
                RAISE EXCEPTION 'vanem või laps ei leidnud json_record.vanem_ik-> %, json_record.laps_ik->%' , json_record.vanem_ik, json_record.laps_ik;
            END IF;

            RAISE NOTICE 'l_laps_id %, l_rekvid %, json_record.yksus %', l_laps_id, l_rekvid, json_record.yksus;

            -- ищем учреждение
            l_rekvid = (SELECT id
                        FROM ou.rekv
                        WHERE nimetus LIKE ltrim(rtrim(json_record.yksus)) + '%'
                        LIMIT 1);

            l_user_id = (SELECT id
                         FROM ou.userid
                         WHERE rekvid = l_rekvid
                           AND kasutaja = 'temp');


            l_aa = (SELECT arve
                    FROM ou.aa
                    WHERE parentid = l_rekvid
                      AND kassa = 1
                    ORDER BY default_ DESC
                    LIMIT 1);


            -- ищем счет
            l_arv_id = (SELECT a.parentid
                        FROM docs.doc d
                                 INNER JOIN docs.arv a ON a.parentid = d.id AND d.status <> 3
                                 INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                        WHERE kpv = l_kpv
                          AND asutusid = l_asutus_id
                          AND l.parentid = l_laps_id
                          AND a.rekvid = l_rekvid
            );


            -- ищем ид конфигурации контировки
            l_doklausend_id = (SELECT dp.id
                               FROM libs.dokprop dp
                                        INNER JOIN libs.library l ON l.id = dp.parentid
                               WHERE dp.rekvid = l_rekvid
                                 AND (dp.details ->> 'konto')::TEXT = '103000'::TEXT
                                 AND l.kood = 'ARV'
                               ORDER BY dp.id DESC
                               LIMIT 1
            );


            -- обнулим строку
            json_arvrea = '[]'::JSONB;

            FOR v_details IN
                WITH qryJsons AS (
                    SELECT *
                    FROM jsonb_to_recordset(data::JSONB)
                             AS x(yksus TEXT, laps_ik TEXT, vanem_ik TEXT, summa TEXT, db TEXT, kood TEXT,
                                  inf3 TEXT, grupp TEXT)
                )
                SELECT *
                FROM qryJsons
                WHERE qryJsons.yksus = json_record.yksus
                  AND qryJsons.laps_ik = json_record.laps_ik
                  AND qryJsons.vanem_ik = json_record.vanem_ik
                LOOP


                    l_arve_summa = regexp_replace(v_details.summa, '[,]', '.')::NUMERIC;

                    -- ищем номенклатуру
                    SELECT *
                    INTO v_nom
                    FROM libs.nomenklatuur n
                    WHERE rekvid = l_rekvid
                      AND kood = v_details.kood
                      AND n.dok = 'ARV'
                      AND status <> 3
                    LIMIT 1;

                    -- формируем строку
                    json_arvrea = json_arvrea || (SELECT row_to_json(row)
                                                  FROM (SELECT v_nom.id                        AS nomid,
                                                               1                               AS kogus,
                                                               l_arve_summa                    AS hind,
                                                               l_arve_summa                    AS kbmta,
                                                               0                               AS kbm,
                                                               l_arve_summa                    AS summa,
                                                               v_nom.properties ->> 'tegev'    AS kood1,
                                                               v_nom.properties ->> 'allikas'  AS kood2,
                                                               v_nom.properties ->> 'rahavoog' AS kood3,
                                                               v_nom.properties ->> 'artikkel' AS kood5,
                                                               v_nom.properties ->> 'konto'    AS konto,
                                                               v_nom.properties ->> 'tunnus',
                                                               v_nom.properties ->> 'projekt',
                                                               v_nom.properties ->> 'yksus'    AS tunnus,
                                                               'Alg. saldo'                    AS muud,
                                                               v_details.grupp                 AS yksus,
                                                               l_tp                            AS tp) row) :: JSONB;

                END LOOP;

            -- создаем параметры
            l_json_arve = (SELECT to_json(row)
                           FROM (SELECT coalesce(l_arv_id, 0) AS id,
                                        NULL::TEXT            AS number,
                                        l_doklausend_id       AS doklausid,
                                        l_liik                AS liik,
                                        l_kpv                 AS kpv,
                                        l_asutus_id           AS asutusid,
                                        l_aa                  AS aa,
                                        l_laps_id             AS lapsid,
                                        'Alg.saldo'           AS muud,
                                        TRUE                  AS import,
                                        json_arvrea           AS "gridData") row);

            SELECT row_to_json(row)
            INTO json_object
            FROM (SELECT coalesce(l_arv_id, 0) AS id, l_json_arve AS data, TRUE AS import) row;


            -- сохранение
            SELECT docs.sp_salvesta_arv(json_object :: JSON, l_user_id, l_rekvid) INTO l_arv_id;

            RAISE NOTICE 'Arve salvestatud, id-> %, l_user_id %',l_arv_id, l_user_id;

            IF (coalesce(l_arv_id, 0) > 0)
            THEN
                PERFORM docs.gen_lausend_arv(l_arv_id, l_user_id);

                l_count = l_count + 1;
            END IF;


        END LOOP;
    RAISE NOTICE 'Kokku leidnud voi salvestatuds arveid %', l_count;
    result = l_count;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


/*
SELECT error_code, result, error_message
FROM lapsed.import_alg_saldo_deebet( '[{"yksus":"0951004","laps_ik":"61012133737","vanem_ik":"37807142212","summa":"19.17","db":"103000","kood":"322000-010","grupp":"HUVI-012-04"}]'::jsonb, 70::integer, 63::integer) as id

 */

--update docs.arv set number = '449' where parentid = 2347613