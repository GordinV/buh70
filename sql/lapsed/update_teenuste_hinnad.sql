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
    json_object JSONB;

    DOC_STATUS  INTEGER = 1; -- только активные услуги
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
               lk.properties ->> 'yksus' as yksus,
               lk.properties ->> 'all_yksus' as all_yksus,
               lk.properties ->> 'soodus' as soodus,
               lk.properties ->> 'kas_protsent' as kas_protsent ,
               lk.properties ->> 'kas_eraldi' as kas_eraldi,
               lk.properties ->> 'kas_ettemaks' as kas_ettemaks,
               lk.properties ->> 'ettemaksu_period' as ettemaksu_period,
               lk.properties ->> 'kas_inf3' as kas_inf3,
               lk.properties ->> 'sooduse_alg' as sooduse_alg,
               lk.properties ->> 'sooduse_lopp' as sooduse_lopp,
               lk.properties ->> 'alg_kpv' as alg_kpv,
               lk.properties ->> 'lopp_kpv' as lopp_kpv,
               lk.properties ->> 'kogus' as kogus,
               lk.muud
        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.nomid = l_nom_id
          AND lk.staatus = DOC_STATUS
          AND lk.hind <> n.hind
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
select lapsed.update_teenuste_hinnad(70, 2738)
 */