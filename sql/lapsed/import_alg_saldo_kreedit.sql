-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.import_alg_saldo_kreedit(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_alg_saldo_kreedit(IN data JSONB,
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
    l_json_mk       JSON;
    json_mk1        JSONB   = '[]';

    l_tp            TEXT    = '800699'; -- (SELECT tp FROM libs.asutus a WHERE id = l_asutus_id);

    l_mk_id         INTEGER = 0;
    l_number        TEXT;
    l_mk_summa      NUMERIC = 0;
    l_aa            TEXT;
    v_aa            RECORD;
    v_details       RECORD;
    v_nom           RECORD;
    l_count         INTEGER = 0;
    l_user_id       INTEGER;
    l_dok_id        INTEGER = (SELECT id
                               FROM libs.library WHERE library.library = 'DOK' AND kood = 'SMK' LIMIT 1);
    v_mk1           RECORD;
    v_mk            RECORD;
    l_viitenr       TEXT;

BEGIN


    FOR json_record IN
        WITH qryJsons AS (
            SELECT *
            FROM jsonb_to_recordset(data::JSONB)
                     AS x(yksus TEXT, laps_ik TEXT, vanem_ik TEXT, summa TEXT, kr TEXT, kood TEXT, konto TEXT)
        )
        SELECT DISTINCT yksus, laps_ik, vanem_ik, konto
        FROM qryJsons
        LOOP
            RAISE NOTICE 'yksus %, laps_ik %, vanem_ik %', json_record.yksus, json_record.laps_ik, json_record.vanem_ik;
            -- ищем котр-агента
            l_asutus_id = (
                SELECT a.id
                FROM libs.asutus a
                         LEFT OUTER JOIN lapsed.vanemad v ON v.asutusid = a.id AND v.staatus <> 3
                    WHERE a.regkood = json_record.vanem_ik
                    ORDER BY v.id ASC LIMIT 1
            );

            l_laps_id = (SELECT id
                         FROM lapsed.laps l WHERE l.isikukood = json_record.laps_ik AND l.staatus <> 3 LIMIT 1);

            -- ищем учреждение
            l_rekvid = (SELECT id
                        FROM ou.rekv WHERE nimetus LIKE ltrim(rtrim(json_record.yksus)) + '%' LIMIT 1);

            l_viitenr = lapsed.get_viitenumber(l_rekvid, l_laps_id);


            l_user_id = (SELECT id
                         FROM ou.userid WHERE rekvid = l_rekvid AND kasutaja = 'temp' LIMIT 1);

            SELECT * INTO v_aa
            FROM ou.aa
                WHERE parentid = l_rekvid
                     AND kassa = 1
                     AND konto = json_record.konto
                ORDER BY default_ DESC
                LIMIT 1;

            RAISE NOTICE 'v_aa %',v_aa;

            -- ищем mk
            l_mk_id = (
                SELECT d.id
                FROM docs.doc d
                         INNER JOIN docs.mk m ON m.parentid = d.id AND d.status <> 3
                         INNER JOIN docs.mk1 m1 ON m1.parentid = m.id
                         INNER JOIN lapsed.liidestamine l ON l.docid = m.parentid
                    WHERE m1.asutusid = l_asutus_id
                         AND l.parentid = l_laps_id
                         AND m.kpv = '2020-12-31'
                    LIMIT 1
            );
            RAISE NOTICE 'l_mk_id %',l_mk_id;


            -- ищем ид конфигурации контировки
            l_doklausend_id = (SELECT dp.id
                               FROM libs.dokprop dp
                                        INNER JOIN libs.library l ON l.id = dp.parentid
                                   WHERE dp.rekvid = l_rekvid
                                        AND l.kood = 'SMK'
                                   ORDER BY dp.id DESC
                                   LIMIT 1
            );

            IF (l_doklausend_id IS NULL)
            THEN
                -- нет профиля, надо создать
                -- тип документа
                json_object = (
                    SELECT to_json(row)
                    FROM (SELECT 0                      AS id,
                                 0                      AS asutusid,
                                 NULL                   AS kbmkonto,
                                 json_record.konto             AS konto,
                                 l_dok_id               AS parentid,
                                 1                      AS registr,
                                 'Sissemakse korraldus' AS selg,
                                 1                      AS vaatalaus) row);

                SELECT row_to_json(row) INTO json_object
                FROM (SELECT 0 AS id, json_object AS data, TRUE AS import) row;

                RAISE NOTICE 'dokprop json_object %', json_object;

                -- сохранение
                SELECT libs.sp_salvesta_dokprop(json_object :: JSON, l_user_id, l_rekvid) INTO l_doklausend_id;

                raise notice 'dokprop saved, l_doklausend_id %', l_doklausend_id;
            END IF;

            RAISE NOTICE 'salvestan';
            -- обнулим строку
            json_mk1 = '[]'::JSONB;

            FOR v_details IN
                WITH qryJsons AS (
                    SELECT *
                    FROM jsonb_to_recordset(data::JSONB)
                             AS x(yksus TEXT, laps_ik TEXT, vanem_ik TEXT, summa TEXT, kr TEXT, kood TEXT,
                                  inf3 TEXT)
                )
                SELECT *
                FROM qryJsons
                    WHERE qryJsons.yksus = json_record.yksus
                         AND qryJsons.laps_ik = json_record.laps_ik
                         AND qryJsons.vanem_ik = json_record.vanem_ik
                LOOP


                    l_mk_summa = regexp_replace(v_details.summa, '[,]', '.')::NUMERIC;

                    -- ищем номенклатуру
                    SELECT * INTO v_nom
                    FROM libs.nomenklatuur n
                        WHERE rekvid = l_rekvid
                             AND n.dok IN ('SMK', 'MK')
                             AND status <> 3 LIMIT 1;

                    -- формируем строку
                    SELECT 0            AS id,
                           v_nom.id     AS nomid,
                           l_asutus_id  AS asutusid,
                           l_mk_summa   AS summa,
                           v_aa.arve    AS aa,
                           v_details.kr AS konto
                           INTO v_mk1;

                    json_mk1 = json_mk1::jsonb || (SELECT (row_to_json(v_mk1)))::jsonb;

                END LOOP;

            raise notice    'json_mk1 %, v_aa %, v_details %', json_mk1, v_aa, v_details;

            SELECT 0               AS id,
                   l_doklausend_id AS doklausid,
                   v_aa.id         AS aa_id,
                   NULL            AS arvid,
                   2               AS opt,
                   l_viitenr       AS viitenr,
                   NULL            AS number,
                   '2020-12-31'    AS maksepaev,
                   '2020-12-31'    AS kpv,
                   'Alg.saldo'     AS selg,
                   NULL            AS muud,
                   json_mk1        AS "gridData",
                   l_laps_id       AS lapsid
                   INTO v_mk;

            json_object = (SELECT (row_to_json(v_mk)));

            SELECT row_to_json(row) INTO l_json_mk
            FROM (SELECT 0           AS id,
                         json_object AS data) row;

            raise notice 'l_json_mk %', l_json_mk;

            SELECT docs.sp_salvesta_mk(l_json_mk :: JSON, l_user_id, l_rekvId) INTO l_mk_id;


            RAISE NOTICE 'Mk salvestatud, id-> %',l_mk_id;

            IF (coalesce(l_mk_id, 0) > 0)
            THEN
                PERFORM docs.gen_lausend_smk(l_mk_id, l_user_id);

                l_count = l_count + 1;
            END IF;


        END LOOP;
    RAISE NOTICE 'Kokku leidnud voi salvestatuds mk %', l_count;
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
FROM lapsed.import_alg_saldo_kreedit('[
  {
    "yksus": "0911018",
    "laps_ik": "51010143722",
    "vanem_ik": "48910152238",
    "summa": "12",
    "kr": "203900",
    "kood": "322040-004"
  }
]'::JSONB, 70::INTEGER, 63::INTEGER) AS id

*/

