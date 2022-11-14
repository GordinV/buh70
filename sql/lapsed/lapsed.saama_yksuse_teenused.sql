-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.saama_yksuse_teenused(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.saama_yksuse_teenused(INTEGER, INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.saama_yksuse_teenused(IN user_id INTEGER,
                                                        IN l_id INTEGER,
                                                        IN l_grupp_id INTEGER,
                                                        IN l_alates DATE DEFAULT current_date,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT doc_type_id TEXT,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid   INTEGER = (SELECT rekvid
                          FROM ou.userid u
                          WHERE id = user_id
                          LIMIT 1);

    v_kaart    RECORD;

    l_count    INTEGER = 0;
    params     JSONB;
    l_kaart_id INTEGER;

BEGIN
    doc_type_id = 'LAPS';

    -- делаем выборку услуг
    FOR v_kaart IN
        SELECT x.*,
               n.id                                   AS nom_id,
               n.kood::TEXT,
               n.nimetus::TEXT,
               n.uhik::TEXT,
               n.properties ->> 'tunnus'              AS tunnus,
               (n.properties ->> 'kas_inf3')::BOOLEAN AS kas_inf3,
               ltrim(rtrim(l.kood))                                 AS yksus

        FROM jsonb_to_recordset((SELECT properties::JSONB -> 'teenused'
                                 FROM libs.library
                                 WHERE id = l_grupp_id)) AS x(hind NUMERIC(12, 2), kogus NUMERIC(12, 2), nomid INTEGER)
                 INNER JOIN libs.nomenklatuur n ON n.id = x.nomid AND n.status <> 3
                 INNER JOIN libs.library l ON l.id = l_grupp_id
        LOOP
            -- готовим параметры

            -- ищем услуги с такими же параметрами
            SELECT id INTO l_kaart_id
            FROM lapsed.lapse_kaart lk
            WHERE parentid = l_id
              AND nomid = v_kaart.nom_id
              AND coalesce(lk.properties ->> 'yksus', '') = v_kaart.yksus
-- различаются по срокам
              and (lk.properties->>'lopp_kpv')::date > l_alates
              AND lk.staatus <> 3
              AND lk.rekvid = l_rekvid
            LIMIT 1;

            IF l_kaart_id IS NULL
            THEN
                -- такой услуги нет, добавляем
                params = jsonb_build_object('id', 0,
                                            'parentid', l_id,
                                            'nomid', v_kaart.nom_id,
                                            'tunnus', v_kaart.tunnus,
                                            'yksus', v_kaart.yksus,
                                            'hind', v_kaart.hind,
                                            'kas_inf3', v_kaart.kas_inf3,
                                            'alg_kpv', l_alates,
                                            'lopp_kpv', make_date(year(current_date) + 10, 12, 31),
                                            'kogus', v_kaart.kogus
                    );

                -- подготавливаем параметры для сохранения
                SELECT row_to_json(row) INTO params
                FROM (SELECT 0      AS id,
                             params AS data) row;
                -- сохраняем

                SELECT lapsed.sp_salvesta_lapse_kaart(params :: JSONB, user_id, l_rekvid) INTO l_kaart_id;
                IF l_kaart_id > 0
                THEN
                    l_count = l_count + 1;
                END IF;
            END IF;

        END LOOP;


    IF l_count = 0
    THEN
        error_message = 'Mitte ühtegi teenused uuendatud';
        error_code = 1;
    ELSE
        error_message = 'Kokku salvestatud ' || l_count::TEXT || ' teenused';
        result = l_count;

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

GRANT EXECUTE ON FUNCTION lapsed.saama_yksuse_teenused(INTEGER, INTEGER, INTEGER, DATE) TO arvestaja;


/*
select properties->>'alg_kpv', properties->>'lopp_kpv', * from lapsed.lapse_kaart
where id = 91
order by id desc limit 10

select lapsed.muuda_teenuste_tahtaeg(70, 91,'2020-12-31')


 select * from ou.userid where id = 70
 */