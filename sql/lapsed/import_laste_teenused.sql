DROP FUNCTION IF EXISTS lapsed.import_laste_teenused(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_laste_teenused(IN data JSONB,
                                                        IN user_id INTEGER,
                                                        IN user_rekvid INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_code INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName         TEXT;
    json_object      JSON;
    count            INTEGER = 0;
    json_record      RECORD;
    l_laps_id        INTEGER;
    l_nom_id         INTEGER;
    l_id             INTEGER;
    json_save_params JSONB;
    l_status         INTEGER;

BEGIN
    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;
    IF userName IS NULL
    THEN
        error_message = 'User not found';
        RETURN;
    END IF;

    FOR json_object IN
        SELECT *
        FROM jsonb_array_elements(data)
        LOOP
            SELECT * INTO json_record
            FROM json_to_record(
                         json_object) AS x (isikukood TEXT, yksus TEXT, all_yksus TEXT, kood TEXT, hind TEXT,
                                            kogus TEXT,
                                            tunnus TEXT, alg_kpv TEXT, lopp_kpv TEXT, kas_ettemaks TEXT,
                                            ettemaksu_period TEXT,
                                            kas_eraldi TEXT, kas_inf3 TEXT, soodus TEXT, sooduse_alg TEXT,
                                            sooduse_lopp TEXT, kas_protsent TEXT);

            -- ищем ребенка
            SELECT id, staatus INTO l_laps_id, l_status
            FROM lapsed.laps
            WHERE isikukood = json_record.isikukood
--              AND staatus <> 3
            ORDER BY id
            LIMIT 1;

            -- ищем услугу
            SELECT id INTO l_nom_id
            FROM libs.nomenklatuur n
            WHERE kood = json_record.kood
              AND rekvid = user_rekvid
              AND n.status <> 3
            ORDER BY id
            LIMIT 1;

            IF l_laps_id IS NOT NULL AND l_nom_id IS NOT NULL
            THEN
                -- проверяем уникальность записи
                IF NOT exists(SELECT id
                              FROM lapsed.lapse_kaart
                              WHERE parentid = l_laps_id
                                AND staatus <> 3
                                AND nomid = l_nom_id
                                AND rekvid = user_rekvid)
                THEN

                    json_object = to_jsonb(row)
                                  FROM (SELECT l_laps_id                                         AS parentid,
                                               l_nom_id                                          AS nomid,
                                               json_record.yksus                                 AS yksus,
                                               json_record.all_yksus                             AS all_yksus,
                                               CASE
                                                   WHEN empty(json_record.kogus) THEN 0::NUMERIC
                                                   ELSE json_record.kogus::NUMERIC END           AS kogus,
                                               CASE
                                                   WHEN empty(json_record.hind) THEN 0::NUMERIC
                                                   ELSE json_record.hind::NUMERIC END            AS hind,
                                               CASE
                                                   WHEN empty(json_record.ettemaksu_period::TEXT) OR
                                                        json_record.ettemaksu_period IS NULL THEN NULL
                                                   ELSE json_record.ettemaksu_period END         AS ettemaksu_period,
                                               CASE
                                                   WHEN empty(json_record.soodus) OR json_record.soodus = '' THEN NULL
                                                   ELSE json_record.soodus END                   AS soodus,
                                               json_record.kas_protsent IS NOT NULL AND
                                               (json_record.kas_protsent ILIKE
                                                '%jah%' OR
                                                json_record.kas_protsent ILIKE
                                                '%yes%'
                                                   )::BOOLEAN                                    AS kas_protsent,
                                               json_record.kas_inf3 IS NOT NULL AND
                                               (json_record.kas_inf3 ILIKE '%jah%' OR
                                                json_record.kas_inf3 ILIKE '%yes%')::BOOLEAN     AS kas_inf3,
                                               CASE
                                                   WHEN NOT empty(json_record.sooduse_alg)
                                                       THEN format_date(json_record.sooduse_alg::TEXT)
                                                   ELSE NULL END::DATE                           AS sooduse_alg,
                                               CASE
                                                   WHEN NOT empty(json_record.sooduse_lopp)
                                                       THEN format_date(json_record.sooduse_lopp::TEXT)
                                                   ELSE NULL::DATE END                           AS sooduse_lopp,
                                               format_date(json_record.alg_kpv::TEXT)            AS alg_kpv,
                                               format_date(json_record.lopp_kpv::TEXT)           AS lopp_kpv,
                                               json_record.kas_eraldi IS NOT NULL AND
                                               (json_record.kas_eraldi ILIKE '%jah%' OR
                                                json_record.kas_eraldi ILIKE '%yes%')::BOOLEAN   AS kas_eraldi,
                                               json_record.kas_ettemaks IS NOT NULL AND
                                               (json_record.kas_ettemaks ILIKE '%jah%' OR
                                                json_record.kas_ettemaks ILIKE '%yes%')::BOOLEAN AS kas_ettemaks
                                       ) ROW;

                    -- сохраняем
                    -- подготавливаем параметры для сохранения
                    SELECT row_to_json(row) INTO json_save_params
                    FROM (SELECT 0           AS id,
                                 json_object AS data) row;

/*                    IF l_status = 3
                    THEN
                        -- карточка ребенка удалена, восстановим
                        UPDATE lapsed.laps SET staatus = 1 WHERE id = l_laps_id;
                    END IF;

*/
                    SELECT lapsed.sp_salvesta_lapse_kaart(json_save_params :: JSONB, user_id, user_rekvid) INTO l_id;
                    IF l_id > 0
                    THEN
                        count = count + 1;
                    END IF;

                END IF;

            END IF;


        END LOOP;

    -- расшифруем платежи
    result = count;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_message = SQLERRM;
            RETURN;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.import_laste_teenused(JSONB, INTEGER, INTEGER) TO arvestaja;


/*
SELECT *
FROM lapsed.import_laste_teenused('[
  {
    "isikukood": "51311090109",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322040-007",
    "hind": "0.63",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51311090109",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322040-008",
    "hind": "0.81",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51311090109",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322040-009",
    "hind": "0.36",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51311090109",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322020-014 ",
    "hind": "18.9",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "Yes",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51311090109",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322030-016 ",
    "hind": "8.1",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "Yes",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51311090109",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322020-034 ",
    "hind": "-18.9",
    "kogus": "0.25",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "Yes",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51311090109",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322030-036 ",
    "hind": "-8.1",
    "kogus": "0.25",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "Yes",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51309270095",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322040-007",
    "hind": "0.63",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51309270095",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322040-008",
    "hind": "0.81",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51309270095",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322040-009",
    "hind": "0.36",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51309270095",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322020-014 ",
    "hind": "18.9",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "Yes",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51309270095",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322030-016 ",
    "hind": "8.1",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "Yes",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51409250198",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322040-007",
    "hind": "0.63",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51409250198",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322040-008",
    "hind": "0.81",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51409250198",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322040-009",
    "hind": "0.36",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51409250198",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322020-014 ",
    "hind": "18.9",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "Yes",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  },
  {
    "isikukood": "51409250198",
    "yksus": "LAED-002-01",
    "all_yksus": "",
    "kood": "322030-016 ",
    "hind": "8.1",
    "kogus": "1",
    "tunnus": "",
    "alg_kpv": "01.11.2019",
    "lopp_kpv": "31.12.2030",
    "kas_ettemaks": "",
    "ettemaksu_period": "",
    "kas_eraldi": "",
    "kas_inf3": "Yes",
    "soodus": "",
    "sooduse_alg": "",
    "sooduse_lopp": "",
    "kas_protsent": ""
  }
]',
                                  70,
                                  63)

SELECT id FROM lapsed.vanemad WHERE parentid = 5004 AND asutusid = 16070
delete from lapsed.vanemad where id = 43

SELECT * FROM lapsed.lapse_kaart order by id desc limit 10

delete FROM lapsed.lapse_kaart
where id > 72
*/


