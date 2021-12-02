DROP FUNCTION IF EXISTS lapsed.register_eelmise_lapsed();

CREATE FUNCTION lapsed.register_eelmise_lapsed()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_lapsed   RECORD;
    l_laps_id  INTEGER;
    l_rekv_id  INTEGER;
    l_grupp_id INTEGER;
    l_nom_id   INTEGER;
    l_kaart_id INTEGER;
    l_json     JSONB;
    l_user_id  INTEGER;
BEGIN
    /*    ALTER TABLE tmp_lapsed
            ADD COLUMN IF NOT EXISTS kaart_id INTEGER;
    */
    FOR v_lapsed IN
        SELECT *
        FROM tmp_lapsed
        WHERE isikukood IS NOT NULL
--        and isikukood = '46904233729'
        LOOP
            --     карточка ребенка
            SELECT id INTO l_laps_id FROM lapsed.laps WHERE isikukood = v_lapsed.isikukood;
            IF l_laps_id IS NULL
            THEN
                RAISE EXCEPTION 'No laps %', v_lapsed.isikukood;
            END IF;

            -- asutus
            l_rekv_id = (SELECT id FROM ou.rekv WHERE nimetus = v_lapsed.asutus LIMIT 1);
            IF l_rekv_id IS NULL
            THEN
                RAISE EXCEPTION 'No rekv %', v_lapsed.asutus;
            END IF;

            -- user_id
            l_user_id = (SELECT id FROM ou.userid WHERE rekvid = l_rekv_id AND kasutaja = 'vlad' LIMIT 1);

            -- grupp
            l_grupp_id = (SELECT id
                          FROM libs.library
                          WHERE rekvid = l_rekv_id
                            AND kood = v_lapsed.grupp
                            AND library.library = 'LAPSE_GRUPP'
                            AND status < 3);

            IF l_grupp_id IS NULL
            THEN
                -- insert
                INSERT INTO libs.library (rekvid, kood, nimetus, library, status)
                VALUES (l_rekv_id, v_lapsed.grupp, v_lapsed.grupp_nimetus, 'LAPSE_GRUPP', 1) RETURNING id INTO l_grupp_id;
            END IF;

            --  noms
            l_nom_id = (SELECT id FROM libs.nomenklatuur WHERE rekvid = l_rekv_id AND kood = v_lapsed.teenus_kood);
            IF l_nom_id IS NULL
            THEN
                INSERT INTO libs.nomenklatuur (rekvid, dok, kood, nimetus, uhik, hind, kogus, status)
                VALUES (l_rekv_id, 'ARV', v_lapsed.teenus_kood, v_lapsed.teenus_nimetus, 'muud', 0, 0,
                        1) RETURNING id INTO l_nom_id;
                -- , {"vat": null, "luno": null, "rasv": null, "tyyp": "SOODUSTUS", "grupp": null, "kalor": null, "konto": "322040", "tegev": "09110", "valid": null, "tunnus": "0911009", "allikas": "80", "projekt": null, "artikkel": "3220", "kas_inf3": false, "rahavoog": "null", "sahharid": null, "oppe_tyyp": "Muud", "vailkaine": null}
            END IF;

            RAISE NOTICE 'l_rekv_id %, l_nom_id %, l_grupp_id %', l_rekv_id, l_nom_id, l_grupp_id;

            -- карточка

            l_kaart_id = (SELECT id
                          FROM lapsed.lapse_kaart
                          WHERE rekvid = l_rekv_id
                            and parentid = l_laps_id
                            AND nomid = l_nom_id
                            AND staatus < 3
                          LIMIT 1);
            IF l_kaart_id IS NULL
            THEN

                -- создаем
                l_json = (SELECT row_to_json(row)
                          FROM (SELECT 0              AS id,
                                       l_laps_id      AS parentid,
                                       l_nom_id       AS nomid,
                                       1              AS kogus,
                                       0              AS hind,
                                       v_lapsed.grupp AS yksus,
                                       '2019-12-31'   AS alg_kpv,
                                       '2019-12-31'   AS lopp_kpv,
                                       'import'       AS muud) row) :: JSONB;

                RAISE NOTICE 'salvestan %', l_json;
                SELECT row_to_json(row)
                INTO l_json
                FROM (SELECT 0 AS id, l_json AS data) row;


                l_kaart_id = lapsed.sp_salvesta_lapse_kaart(l_json::JSONB, l_user_id::INTEGER, l_rekv_id::INTEGER);
                IF l_kaart_id IS NULL OR l_kaart_id = 0
                THEN
                    RAISE EXCEPTION 'kaar not saved l_json %', l_json;
                END IF;
                UPDATE tmp_lapsed
                SET kaart_id = l_kaart_id
                WHERE isikukood = v_lapsed.isikukood
                  AND viitenumber = v_lapsed.viitenumber;
                RAISE NOTICE 'kaart saved l_laps_id %, l_rekv_id %, l_kaart_id %', l_laps_id, l_rekv_id, l_kaart_id;
            END IF;

        END LOOP;
    RETURN 1;
END ;
$$;

SELECT lapsed.register_eelmise_lapsed();

--DROP FUNCTION IF EXISTS lapsed.register_eelmise_lapsed();


