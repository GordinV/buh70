DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_kaart(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_lapse_kaart(data JSONB,
                                                          userid INTEGER,
                                                          user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName             TEXT;
    doc_data             JSON    = data ->> 'data';
    doc_id               INTEGER = (SELECT CASE
                                               WHEN (doc_data ->> 'id')::TEXT ILIKE '%NEW%' THEN 0::TEXT
                                               ELSE (doc_data ->> 'id')::TEXT END)::INTEGER;
    doc_parentid         INTEGER = doc_data ->> 'parentid';
    doc_nomid            INTEGER = doc_data ->> 'nomid';
    doc_tunnus           TEXT    = doc_data ->> 'tunnus';
    doc_hind             NUMERIC = doc_data ->> 'hind';
    doc_yksus            TEXT    = doc_data ->> 'yksus';
    doc_all_yksus        TEXT    = doc_data ->> 'all_yksus';
    doc_soodus           NUMERIC = CASE
                                       WHEN coalesce((doc_data ->> 'soodus')::TEXT, '') = '' THEN 0
                                       ELSE (doc_data ->> 'soodus')::NUMERIC END;
    doc_kas_protsent     BOOLEAN = doc_data ->> 'kas_protsent';
    doc_kas_eraldi       BOOLEAN = doc_data ->> 'kas_eraldi';
    doc_kas_ettemaks     BOOLEAN = doc_data ->> 'kas_ettemaks';
    doc_kas_inf3         BOOLEAN = doc_data ->> 'kas_inf3';
    doc_sooduse_alg      DATE    = (CASE
                                        WHEN (doc_data ->> 'sooduse_alg')::TEXT = '' THEN NULL
                                        ELSE doc_data ->> 'sooduse_alg' END)::DATE ;
    doc_sooduse_lopp     DATE    = (CASE
                                        WHEN (doc_data ->> 'sooduse_lopp')::TEXT = '' THEN NULL
                                        ELSE doc_data ->> 'sooduse_lopp' END)::DATE;
    doc_alg_kpv          DATE    = (CASE
                                        WHEN (doc_data ->> 'alg_kpv')::TEXT = '' THEN NULL
                                        ELSE doc_data ->> 'alg_kpv' END)::DATE;
    doc_lopp_kpv         DATE    = (CASE
                                        WHEN (doc_data ->> 'lopp_kpv')::TEXT = '' THEN NULL
                                        ELSE doc_data ->> 'lopp_kpv' END)::DATE;
    doc_muud             TEXT    = doc_data ->> 'muud';
    doc_viitenr          TEXT    = doc_data ->> 'viitenr';
    doc_kogus            NUMERIC = doc_data ->> 'kogus';
    doc_ettemaksu_period INTEGER = doc_data ->> 'ettemaksu_period';
    json_props           JSONB;
    json_ajalugu         JSONB;
    doc_row              RECORD;
    l_grupp_id           INTEGER = (SELECT id
                                    FROM libs.library
                                    WHERE kood = doc_yksus
                                      AND library.library = 'LAPSE_GRUPP'
                                      AND status <> 3
                                      AND rekvid = user_rekvid
                                    ORDER BY id DESC
                                    LIMIT 1);
    l_noms               INTEGER = (SELECT count(id)
                                    FROM lapsed.lapse_kaart
                                    WHERE parentid = doc_parentid
                                      AND nomid = doc_nomid
                                      AND staatus <> 3);

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    IF doc_id IS NULL OR doc_id = 0
    THEN
        -- если бобавляем услугу, то пропускаем проверку
        l_noms = l_noms + 1;
    END IF;

    SELECT l.isikukood, lk.*
    INTO doc_row
    FROM lapsed.lapse_kaart lk
             INNER JOIN lapsed.laps l ON l.id = lk.parentid
    WHERE lk.id = doc_id
    LIMIT 1;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

-- проверка на даты
    IF (doc_alg_kpv > doc_lopp_kpv)
    THEN
        RAISE EXCEPTION 'Vale kuupäevad alg.kpv > lõpp kpv, %', doc_row.isikukood;
    END IF;

    -- проверка на табеля
--    По нач. дате - не должно оставлять вне периода дневные табеля , которые оформлены ранее даты нач. срока действия услуги
    IF exists(SELECT dt.id
              FROM lapsed.day_taabel dt
                       INNER JOIN lapsed.day_taabel1 dt1 ON dt.id = dt1.parent_id
              WHERE dt1.laps_id = doc_parentid
                AND dt.kpv < doc_alg_kpv
                AND dt1.nom_id = doc_nomid
                AND dt.grupp_id = l_grupp_id
                AND coalesce(dt1.kogus, 0) > 0
                AND coalesce(l_noms, 0) < 2 -- при условии, что услуга только одна
                AND dt.staatus < 3
              LIMIT 1
        )
    THEN
        RAISE EXCEPTION 'Vale alg.kuupäev. Päevatabelid leidnud koostatud  varem kui alg. kpv, %',doc_row.isikukood;

    END IF;

    -- по дате окончания срока действия услуги - не должны оставаться табеля позже срока окончания действия услуги
    IF exists(SELECT dt.id
              FROM lapsed.day_taabel dt
                       INNER JOIN lapsed.day_taabel1 dt1 ON dt.id = dt1.parent_id
              WHERE dt1.laps_id = doc_parentid
                AND dt.kpv > doc_lopp_kpv
                AND dt1.nom_id = doc_nomid
                AND dt.grupp_id = l_grupp_id
                AND coalesce(dt1.kogus, 0) > 0
                AND dt.staatus < 3
                AND coalesce(l_noms, 0) < 2 -- при условии, что услуга только одна
                AND dt.grupp_id = l_grupp_id
              LIMIT 1
        )
    THEN
        RAISE EXCEPTION 'Vale lõpp.kuupäev. Päevatabelid leidnud koostatud  hiljem kui lõpp. kpv, %', doc_row.isikukood;
    END IF;


    -- дата нач. услуги - нельзя ставить позже , чем есть табель
    IF exists(SELECT lt.id
              FROM lapsed.lapse_taabel lt
              WHERE lt.parentid = doc_parentid
                AND (make_date(lt.aasta, lt.kuu, 1) + INTERVAL '1 month' - INTERVAL '1 day')::DATE < doc_alg_kpv
                AND lt.nomid = doc_nomid
                AND lt.staatus < 3
                AND coalesce(l_noms, 0) < 2 -- при условии, что услуга только одна
              LIMIT 1
        )
    THEN
        RAISE EXCEPTION 'Vale alg.kuupäev. Leidnud tabel varem kui alg. kpv, isikukood %, nom_id %', doc_row.isikukood, doc_nomid;
    END IF;

    -- дата конц. услуги - нельзя ставить раньше , чем есть табель
    IF exists(SELECT lt.id
              FROM lapsed.lapse_taabel lt
              WHERE lt.parentid = doc_parentid
                AND make_date(lt.aasta, lt.kuu, 1) > doc_lopp_kpv
                AND lt.nomid = doc_nomid
                AND lt.staatus < 3
                AND coalesce(l_noms, 0) < 2 -- при условии, что услуга только одна

        )
    THEN
        RAISE NOTICE 'Vale lõpp kuupäev. Leidnud tabel hiljem kui lõpp kpv, %', doc_row.isikukood;
    END IF;

    -- проверка на дату льготы, если дата не конец мнесяца и не равна дате окончания услуги
    IF (doc_sooduse_lopp IS NOT NULL AND doc_sooduse_lopp <> doc_lopp_kpv
        AND doc_sooduse_lopp <
            (make_date(year(doc_sooduse_lopp), month(doc_sooduse_lopp), 1) + INTERVAL '1 month' -
             INTERVAL '1 day')::DATE)
        OR coalesce(doc_sooduse_lopp, doc_lopp_kpv) > doc_lopp_kpv
    THEN
        RAISE EXCEPTION 'Vale soodustuse lõpp kuupäev. peaks olla kuu lõpp või teenuse lõpp kuupäev, %', doc_row.isikukood;
    END IF;

    -- на наличие такой услуги в карте
    IF exists(SELECT lk.id
              FROM lapsed.lapse_kaart lk
              WHERE lk.parentid = doc_parentid
                AND lk.rekvid = user_rekvid
                AND lk.nomid = doc_nomid
                AND lk.properties ->> 'yksus' = doc_yksus
                AND lk.id <> coalesce(doc_id, 0)
                AND lk.staatus < 3
        )
    THEN
        RAISE NOTICE 'See teenus juba olemas, korduv, %', doc_row.isikukood;
    END IF;


    json_props = to_jsonb(row)
                 FROM (SELECT doc_yksus            AS yksus,
                              doc_all_yksus        AS all_yksus,
                              doc_kogus            AS kogus,
                              doc_ettemaksu_period AS ettemaksu_period,
                              doc_soodus           AS soodus,
                              doc_kas_protsent     AS kas_protsent,
                              doc_kas_inf3         AS kas_inf3,
                              doc_sooduse_alg      AS sooduse_alg,
                              doc_sooduse_lopp     AS sooduse_lopp,
                              doc_alg_kpv          AS alg_kpv,
                              doc_lopp_kpv         AS lopp_kpv,
                              doc_kas_eraldi       AS kas_eraldi,
                              doc_kas_ettemaks     AS kas_ettemaks,
                              doc_viitenr          AS viitenr
                      ) row;

    -- проверка на статус карты ребенка
    IF (SELECT staatus
        FROM lapsed.laps
        WHERE id = doc_parentid
        LIMIT 1) = 3
    THEN
        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user) row;

        UPDATE lapsed.laps
        SET staatus = 1,
            ajalugu = ajalugu::JSONB || json_ajalugu
        WHERE id = doc_parentid;
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.lapse_kaart (parentid, rekvid, nomid, hind, tunnus, muud, properties, ajalugu)
        VALUES (doc_parentid, user_rekvid, doc_nomid, doc_hind, doc_tunnus, doc_muud, json_props,
                '[]' :: JSONB || json_ajalugu) RETURNING id
                   INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user
                             FROM lapsed.lapse_kaart l
                             WHERE id = doc_id
                            ) row;

        UPDATE lapsed.lapse_kaart
        SET nomid      = doc_nomid,
            tunnus     = doc_tunnus,
            hind       = doc_hind,
            properties = coalesce(properties, '[]')::JSONB || json_props,
            muud       = doc_muud,
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu,
            staatus    = 1
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;


    RETURN doc_id;

/*EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;
*/

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_kaart(JSONB, INTEGER, INTEGER) TO arvestaja;


/*

select * from libs.nomenklatuur where rekvid = 63

select lapsed.sp_salvesta_lapse_kaart('{"data":{"id":23,"parentid":7,"nomid":16468,"tunnus":"test","muud":"test","userid":70,"kas_ettemaks":"true", "ettemaksu_period":1}}'::jsonb, 70::integer, 63::integer) as id


select * from lapsed.lapse_kaart
*/