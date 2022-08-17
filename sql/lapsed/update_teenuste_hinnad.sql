-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.update_teenuste_hinnad(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.update_teenuste_hinnad(IN user_id INTEGER,
                                                         IN l_nom_id INTEGER,
                                                         IN l_kpv DATE DEFAULT current_date,
                                                         OUT error_code INTEGER,
                                                         OUT result INTEGER,
                                                         OUT doc_type_id TEXT,
                                                         OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid    INTEGER = (SELECT rekvid
                           FROM ou.userid u
                           WHERE id = user_id
                           LIMIT 1);

    v_kaart     RECORD;
    v_groups    RECORD;
    json_object JSONB;

    DOC_STATUS  INTEGER = 1; -- только активные услуги
    l_count     INTEGER = 0;
    l_kaart_id  INTEGER;
    l_grupp_id  INTEGER;
BEGIN
    doc_type_id = 'LAPSE_KAART';

    -- делаем выборку из груп

    FOR v_groups IN
        SELECT id,
               kood,
               nimetus,
               muud,
               (properties::JSONB -> 'all_yksused' ->> 1)::TEXT AS all_yksus_1,
               (properties::JSONB -> 'all_yksused' ->> 2)::TEXT AS all_yksus_2,
               (properties::JSONB -> 'all_yksused' ->> 3)::TEXT AS all_yksus_3,
               (properties::JSONB -> 'all_yksused' ->> 4)::TEXT AS all_yksus_4,
               (properties::JSONB -> 'all_yksused' ->> 5)::TEXT AS all_yksus_5,
               (SELECT json_agg(to_jsonb(qry.*)) AS gridData
                FROM (
                         SELECT nomid AS id, x.nomid, x.kogus, n.hind, n.kood::TEXT, n.nimetus::TEXT
                         FROM jsonb_to_recordset(
                                      (properties::JSONB -> 'teenused')::JSONB
                                  ) AS x(nomid INTEGER, hind TEXT, kogus TEXT, kood TEXT, nimetus TEXT)
                                  INNER JOIN libs.nomenklatuur n ON n.id = x.nomid
                     ) qry
               )::TEXT                                          AS gridData
        FROM libs.library l
        WHERE l.library = 'LAPSE_GRUPP'
          AND l_nom_id IN (
            SELECT qry.nomid
            FROM (
                     SELECT nomid, hind
                     FROM jsonb_to_recordset(properties::JSONB -> 'teenused') AS x(nomid INTEGER, hind TEXT)) qry
                     INNER JOIN libs.nomenklatuur n ON n.id = qry.nomid
            WHERE (CASE WHEN qry.hind = '' THEN '0' ELSE qry.hind END)::NUMERIC <>
                  (CASE WHEN n.hind::TEXT = '' THEN '0' ELSE n.hind::TEXT END)::NUMERIC
        )
        LOOP
            -- salvestame grupp
            SELECT row_to_json(row)
            INTO json_object
            FROM (SELECT v_groups.id                   AS id,
                         (SELECT to_jsonb(v_groups.*)) AS data) row;

            SELECT lapsed.sp_salvesta_lapse_grupp(json_object :: JSONB, user_id, l_rekvid) INTO l_grupp_id;

            IF (l_grupp_id IS NOT NULL AND l_grupp_id > 0)
            THEN
                l_count = l_count + 1;
            END IF;

        END LOOP;


    -- делаем выборку услуг

    FOR v_kaart IN
        SELECT lk.nomid,
               lk.id,
               n.hind,
               lk.parentid,
               lk.tunnus,
               lk.properties ->> 'yksus'            AS yksus,
               lk.properties ->> 'all_yksus'        AS all_yksus,
               lk.properties ->> 'soodus'           AS soodus,
               lk.properties ->> 'kas_protsent'     AS kas_protsent,
               lk.properties ->> 'kas_eraldi'       AS kas_eraldi,
               lk.properties ->> 'kas_ettemaks'     AS kas_ettemaks,
               lk.properties ->> 'ettemaksu_period' AS ettemaksu_period,
               lk.properties ->> 'kas_inf3'         AS kas_inf3,
               lk.properties ->> 'sooduse_alg'      AS sooduse_alg,
               lk.properties ->> 'sooduse_lopp'     AS sooduse_lopp,
               lk.properties ->> 'alg_kpv'          AS alg_kpv,
               lk.properties ->> 'lopp_kpv'         AS lopp_kpv,
               lk.properties ->> 'kogus'            AS kogus,
               lk.properties ->> 'viitenr'          AS viitenr,
               lk.muud
        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.nomid = l_nom_id
          AND lk.staatus = DOC_STATUS
          AND lk.hind <> n.hind
          AND ((lk.properties ->> 'alg_kpv' IS NULL OR
                (lk.properties ->> 'alg_kpv')::DATE <= l_kpv) -- услуга должны действоаать в периоде
                   AND (lk.properties ->> 'lopp_kpv' IS NULL OR (lk.properties ->> 'lopp_kpv')::DATE >= l_kpv)
            OR l_kpv <= (lk.properties ->> 'lopp_kpv')::DATE
            )

        LOOP

            -- salvestame kaart
            SELECT row_to_json(row)
            INTO json_object
            FROM (SELECT v_kaart.id                   AS id,
                         (SELECT to_jsonb(v_kaart.*)) AS data) row;

            SELECT lapsed.sp_salvesta_lapse_kaart(json_object :: JSONB, user_id, l_rekvid) INTO l_kaart_id;
            IF (l_kaart_id IS NOT NULL AND l_kaart_id > 0)
            THEN
                l_count = l_count + 1;
            END IF;
        END LOOP;

    IF l_count = 0
    THEN
        error_message = 'Mitte ühtegi nomenklatuut uuendatud';
        error_code = 1;

    END IF;
    result = l_kaart_id;
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

GRANT EXECUTE ON FUNCTION lapsed.update_teenuste_hinnad(INTEGER, INTEGER, DATE) TO arvestaja;


/*
select * from lapsed.lapse_kaart  order by id desc limit 10
select lapsed.update_teenuste_hinnad(70, 738)
 */