DROP FUNCTION IF EXISTS generate_taotlused_mvt();

CREATE FUNCTION generate_taotlused_mvt()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_taotlus  RECORD;
    v_tootajad RECORD;
    l_aasta    INTEGER = 2023;
    l_count    INTEGER = 0;
    l_params   JSON;
    v_params   RECORD;
    l_id       INTEGER;
    v_user     RECORD;
BEGIN
    FOR v_tootajad IN
        SELECT *
        FROM libs.asutus a
        WHERE exists(SELECT id
                     FROM palk.tooleping t
                              INNER JOIN (SELECT DISTINCT lepingid FROM palk.taotlus_mvt WHERE lopp_kpv >= '2022-12-31'
                     ) mvt ON mvt.lepingid = t.id
                     WHERE (t.lopp IS NULL OR t.lopp >= '2023-01-01')
                       AND t.parentid = a.id
                       AND rekvid IN (SELECT r.id
                                      FROM ou.rekv r
                                               INNER JOIN ou.aa aa ON aa.parentid = r.id
                                          AND aa.kassa = 2
                                          AND tp IN ('18510140', '18510103', '18510105', '18510106', '18510107')
                                      WHERE r.parentid < 999)
                  )
        LOOP
            RAISE NOTICE 'isik %, v_tootajad.id %', v_tootajad.nimetus, v_tootajad.id;
            -- ищем заявление
            SELECT mvt.*, t.rekvid
            INTO v_taotlus
            FROM palk.taotlus_mvt mvt
                     INNER JOIN palk.tooleping t ON t.id = mvt.lepingid
            WHERE lepingid IN (SELECT id FROM palk.tooleping WHERE parentid = v_tootajad.id)
            ORDER BY lopp_kpv DESC
            LIMIT 1;
            -- получаем данные на 31.12.2022
            IF coalesce(v_taotlus.summa, -1) >= 0 AND
               NOT exists(SELECT id
                          FROM palk.taotlus_mvt
                          WHERE year(lopp_kpv) = 2023
                            AND lepingid = v_taotlus.lepingid
                            AND status <> 'deleted'
                   )
            THEN
                IF v_taotlus.summa = 500
                THEN
                    v_taotlus.summa = 654;
                END IF;
                -- save
                SELECT 0                       AS id,
                       make_date(2023, 01, 01) AS kpv,
                       make_date(2023, 01, 01) AS alg_kpv,
                       make_date(2023, 12, 31) AS lopp_kpv,
                       v_taotlus.lepingid      AS lepingid,
                       v_taotlus.summa         AS summa,
                       'Genereeritud'          AS muud
                INTO v_params;

                SELECT row_to_json(row)
                INTO l_params
                FROM (SELECT 0        AS id,
                             v_params AS data) row;

                SELECT id, rekvid
                INTO v_user
                FROM ou.userid
                WHERE rekvid = v_taotlus.rekvid
                  AND kasutaja = 'vlad'
                ORDER BY id DESC
                LIMIT 1;

                l_id = palk.sp_salvesta_taotlus_mvt(l_params, v_user.id, v_user.rekvid);

                RAISE NOTICE '2023 summa %, v_taotlus.lopp_kpv %, saved id %' , v_taotlus.summa,v_taotlus.lopp_kpv, l_id;
                l_count = l_count + 1;
            END IF;
        END LOOP;
    RETURN l_count;
END;
$$;

SELECT generate_taotlused_mvt();

DROP FUNCTION IF EXISTS generate_taotlused_mvt();
