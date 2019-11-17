-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.update_prices_in_group(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.update_prices_in_group(IN user_id INTEGER,
                                                         IN l_group_id INTEGER,
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
    v_noms      RECORD;
    json_object JSONB;

    DOC_STATUS  INTEGER = 1; -- только активные услуги
    l_count     INTEGER = 0;
    l_kaart_id  INTEGER;
BEGIN
    doc_type_id = 'LAPSE_KAART';

    FOR v_noms IN
        WITH v_group AS (SELECT id, kood, (properties::JSONB -> 'teenused')::JSONB AS teenused
                         FROM libs.library
                         WHERE id = l_group_id)
        SELECT x.*, v_group.kood as yksus
        FROM v_group,
             jsonb_to_recordset(
                     v_group.teenused::JSONB
                 ) AS x(nomid INTEGER, hind NUMERIC)

        LOOP
            -- делаем выборку услуг

            FOR v_kaart IN
                SELECT lk.nomid,
                       lk.id,
                       v_noms.hind,
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
                       lk.muud
                FROM lapsed.lapse_kaart lk
                WHERE lk.nomid = v_noms.nomid
                  and (lk.properties ->> 'yksus') = v_noms.yksus
                  AND lk.staatus = DOC_STATUS
                  AND lk.hind <> v_noms.hind
                  AND (lk.properties ->> 'alg_kpv' IS NULL OR
                       (lk.properties ->> 'alg_kpv')::DATE <= l_kpv) -- услуга должны действоаать в периоде
                  AND (lk.properties ->> 'lopp_kpv' IS NULL OR (lk.properties ->> 'lopp_kpv')::DATE >= l_kpv)
                LOOP
                    -- salvestame kaart
                    SELECT row_to_json(row) INTO json_object
                    FROM (SELECT v_kaart.id                   AS id,
                                 (SELECT to_jsonb(v_kaart.*)) AS data) row;

                    SELECT lapsed.sp_salvesta_lapse_kaart(json_object :: JSONB, user_id, l_rekvid) INTO l_kaart_id;
                    IF (l_kaart_id IS NOT NULL AND l_kaart_id > 0)
                    THEN
                        l_count = l_count + 1;
                    END IF;
                END LOOP;


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

GRANT EXECUTE ON FUNCTION lapsed.update_prices_in_group(INTEGER, INTEGER, DATE) TO arvestaja;


/*
select lapsed.update_prices_in_group(70, 38)
 */