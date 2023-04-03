DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_grupp(JSONB, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_grupp(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_lapse_grupp(data JSONB,
                                                          user_id INTEGER,
                                                          user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id          INTEGER;
    userName        TEXT;
    doc_id          INTEGER = data ->> 'id';
    doc_data        JSON    = data ->> 'data';
    doc_kood        TEXT    = doc_data ->> 'kood';
    doc_nimetus     TEXT    = doc_data ->> 'nimetus';
    doc_library     TEXT    = 'LAPSE_GRUPP';
    doc_muud        TEXT    = doc_data ->> 'muud';
    doc_all_yksus_1 TEXT    = coalesce((doc_data ->> 'all_yksus_1'), '');
    doc_all_yksus_2 TEXT    = coalesce((doc_data ->> 'all_yksus_2'), '');
    doc_all_yksus_3 TEXT    = coalesce((doc_data ->> 'all_yksus_3'), '');
    doc_all_yksus_4 TEXT    = coalesce((doc_data ->> 'all_yksus_4'), '');
    doc_all_yksus_5 TEXT    = coalesce((doc_data ->> 'all_yksus_5'), '');
    doc_details     JSONB   = coalesce(doc_data ->> 'gridData', doc_data ->> 'griddata');
    doc_tyyp        INTEGER = doc_data ->> 'tyyp';

    is_import       BOOLEAN = data ->> 'import';
    all_yksused     TEXT[]  = ARRAY [doc_all_yksus_1, doc_all_yksus_2, doc_all_yksus_3, doc_all_yksus_4, doc_all_yksus_5];
    json_object     JSONB;
    l_prev_kood     TEXT;
    l_tyyp_kood     TEXT;

    l_error         TEXT    = '';
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE EXCEPTION 'User not found %', user;
    END IF;

    -- только согласно патт
    -- Маска кода группы
    -- "Koolituse tüüp""дефис""две цифры"ерну

    IF coalesce((len(array_to_string(regexp_match(doc_kood, '[A-Z][A-Z][A-Z][A-Z]-[0-9A-Z][0-9A-Z][0-9A-Z]-[0-9A-Z][0-9A-Z]'), ''))),
                0) <> 11
    THEN
        RAISE EXCEPTION 'Viga, kood peaks olla AAAA-999-99 aga sisestatud %',doc_kood;
    END IF;

    -- проверка на тип обучения

    l_tyyp_kood = (SELECT ltrim(rtrim(kood)) FROM libs.library WHERE id = doc_tyyp LIMIT 1);
    IF l_tyyp_kood IS NOT NULL AND doc_kood !~ l_tyyp_kood
    THEN
        l_error = 'Viga, kood peaks olla: ' + l_tyyp_kood || ' aga sisestatud';
        RAISE EXCEPTION '% %', l_error ,doc_kood;
    END IF;


-- prepairing all yksused

    SELECT to_jsonb(row)
    INTO json_object
    FROM (SELECT all_yksused AS all_yksused,
                 doc_details AS teenused,
                 doc_tyyp    AS tyyp
         ) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO libs.library (rekvid, kood, nimetus, library, muud, properties)
        VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_muud, json_object) RETURNING id
            INTO lib_id;
    ELSE
        -- прежнее значение
        SELECT kood INTO l_prev_kood FROM libs.library WHERE id = doc_id LIMIT 1;

        UPDATE libs.library
        SET kood       = doc_kood,
            nimetus    = doc_nimetus,
            library    = doc_library,
            muud       = doc_muud,
            properties = json_object
        WHERE id = doc_id RETURNING id
            INTO lib_id;

        -- подменим код в карточках

        if (ltrim(rtrim(l_prev_kood)) <> ltrim(rtrim(doc_kood)))  then
            UPDATE lapsed.lapse_kaart
            SET properties = properties || jsonb_build_object('yksus', ltrim(rtrim(doc_kood)))
            WHERE rekvid = user_rekvid
              AND ltrim(rtrim(coalesce(properties ->> 'yksus', 'YKSUS'))) = ltrim(rtrim(l_prev_kood))
              AND staatus < 3;

        END IF;


    END IF;

    RETURN lib_id;

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

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_grupp(JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_grupp(JSONB, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT lapsed.sp_salvesta_lapse_grupp('{"id":214107,"data":{"id":214107,"kood":"grupp 2","muud":"test all_yksused","nimetus":"grupp 2 nimetus ","all_yksus_1":"1","all_yksus_2":"2"}}'
,70, 63)
*/