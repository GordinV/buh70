-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.muuda_teenuste_tahtaeg(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.muuda_teenuste_tahtaeg(IN user_id INTEGER,
                                                         IN l_id INTEGER,
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
    json_object JSONB;

    l_count     INTEGER = 0;
    l_kaart_id  INTEGER;
BEGIN
    doc_type_id = 'LAPSE_KAART';

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
               lk.properties ->> 'lopp_kpv'         AS vana_lopp_kpv,
               l_kpv                                AS lopp_kpv,
               lk.properties ->> 'kogus'            AS kogus,
               lk.muud
        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.id = l_id
          AND staatus <> 3
        LOOP
            -- проверка на срок действия
            IF v_kaart.vana_lopp_kpv IS NULL
                   OR empty(v_kaart.vana_lopp_kpv)
                   OR v_kaart.vana_lopp_kpv::DATE < l_kpv
                   OR v_kaart.alg_kpv::DATE > l_kpv
            THEN
                -- услуга не действует
                result = 0;
                RETURN;
            END IF;

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
    IF l_count = 0
    THEN
        error_message = 'Mitte ühtegi teenused uuendatud';
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

GRANT EXECUTE ON FUNCTION lapsed.muuda_teenuste_tahtaeg(INTEGER, INTEGER, DATE) TO arvestaja;


/*
select properties->>'alg_kpv', properties->>'lopp_kpv', * from lapsed.lapse_kaart
where id = 91
order by id desc limit 10

select lapsed.muuda_teenuste_tahtaeg(70, 91,'2020-12-31')


 select * from ou.userid where id = 70
 */