DROP FUNCTION IF EXISTS ou.sp_salvesta_menupohi(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION ou.sp_salvesta_menupohi(data JSON,
                                                   userid INTEGER,
                                                   user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    menu_id                    INTEGER;
    userName                   TEXT;
    doc_id                     INTEGER = data ->> 'id';
    doc_data                   JSON    = data ->> 'data';
    doc_pad                    TEXT    = doc_data ->> 'pad';
    doc_bar                    TEXT    = doc_data ->> 'bar';
    doc_idx                    INTEGER = doc_data ->> 'idx';
    doc_name                   TEXT    = doc_data ->> 'name';
    doc_eesti                  TEXT    = doc_data ->> 'eesti';
    doc_vene                   TEXT    = doc_data ->> 'vene';
    doc_proc                   TEXT    = doc_data ->> 'proc';
    doc_groups                 JSONB   = '[]';
    doc_users                  JSONB   = '[]';
    doc_modules                JSONB   = '[]';
    doc_level                  INTEGER = doc_data ->> 'level';
    doc_is_admin               INTEGER = doc_data ->> 'is_admin';
    doc_is_eelarve             INTEGER = doc_data ->> 'is_eelarve';
    doc_is_eelproj             INTEGER = doc_data ->> 'is_eelproj';
    doc_is_palk                INTEGER = doc_data ->> 'is_palk';
    doc_is_pv                  INTEGER = doc_data ->> 'is_pv';
    doc_is_reklmaks            INTEGER = doc_data ->> 'is_reklmaks';
    doc_is_kasutaja            INTEGER = doc_data ->> 'is_kasutaja';
    doc_is_peakasutaja         INTEGER = doc_data ->> 'is_peakasutaja';
    doc_is_vaatleja            INTEGER = doc_data ->> 'is_vaatleja';
    doc_is_asutuste_korraldaja INTEGER = doc_data ->> 'is_asutuste_korraldaja';
    doc_is_eel_koostaja        INTEGER = doc_data ->> 'is_eel_koostaja';
    doc_is_eel_allkirjastaja   INTEGER = doc_data ->> 'is_eel_allkirjastaja';
    doc_is_eel_esitaja         INTEGER = doc_data ->> 'is_eel_esitaja';
    doc_is_eel_aktsepterja     INTEGER = doc_data ->> 'is_eel_aktsepterja';
    doc_is_rekl_maksuhaldur    INTEGER = doc_data ->> 'is_rekl_maksuhaldur';
    doc_is_rekl_administraator INTEGER = doc_data ->> 'is_rekl_administraator';
    doc_is_ladu_kasutaja       INTEGER = doc_data ->> 'is_ladu_kasutaja';
    doc_is_palga_kasutaja      INTEGER = doc_data ->> 'is_palga_kasutaja';
    doc_is_pohivara_kasutaja   INTEGER = doc_data ->> 'is_pohivara_kasutaja';
    doc_keyshortcut            TEXT    = doc_data ->> 'keyshortcut';
    doc_submenu                TEXT    = doc_data ->> 'submenu';
    json_object                JSONB;
BEGIN
    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

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

    IF doc_is_palga_kasutaja
    THEN
        doc_groups = doc_groups || to_jsonb('PALK_KASUTAJA' :: TEXT);
    END IF;

    IF doc_is_pohivara_kasutaja
    THEN
        doc_groups = doc_groups || to_jsonb('POHIVARA_KASUTAJA' :: TEXT);
    END IF;

    IF doc_is_rekl_administraator
    THEN
        doc_groups = doc_groups || to_jsonb('REKL_ADMINISTRAATOR' :: TEXT);
    END IF;

    IF doc_is_ladu_kasutaja
    THEN
        doc_groups = doc_groups || to_jsonb('LADU_KASUTAJA' :: TEXT);
    END IF;

    IF doc_is_rekl_maksuhaldur
    THEN
        doc_groups = doc_groups || to_jsonb('REKL_MAKSUHALDUR' :: TEXT);
    END IF;

    IF doc_is_eel_aktsepterja
    THEN
        doc_groups = doc_groups || to_jsonb('EEL_AKTSEPTERJA' :: TEXT);
    END IF;

    IF doc_is_eel_esitaja
    THEN
        doc_groups = doc_groups || to_jsonb('EEL_ESITAJA' :: TEXT);
    END IF;

    IF doc_is_eel_allkirjastaja
    THEN
        doc_groups = doc_groups || to_jsonb('EEL_ALLKIRJASTAJA' :: TEXT);
    END IF;

    IF doc_is_eel_koostaja
    THEN
        doc_groups = doc_groups || to_jsonb('EEL_KOOSTAJA' :: TEXT);
    END IF;

    IF doc_is_asutuste_korraldaja
    THEN
        doc_groups = doc_groups || to_jsonb('ASUTUSTE_KORRALDAJA' :: TEXT);
    END IF;

    IF doc_is_vaatleja
    THEN
        doc_groups = doc_groups || to_jsonb('VAATLEJA' :: TEXT);
    END IF;

    IF doc_is_admin
    THEN
        doc_groups = doc_groups || to_jsonb('ADMIN' :: TEXT);
    END IF;

    IF doc_is_kasutaja
    THEN
        doc_groups = doc_groups || to_jsonb('KASUTAJA' :: TEXT);
    END IF;

    IF doc_is_peakasutaja
    THEN
        doc_groups = doc_groups || to_jsonb('PEAKASUTAJA' :: TEXT);
    END IF;

    IF doc_is_peakasutaja
    THEN
        doc_groups = doc_groups || to_jsonb('PEAKASUTAJA' :: TEXT);
    END IF;

    IF doc_is_reklmaks
    THEN
        doc_modules = doc_modules || to_jsonb('REKLMAKS' :: TEXT);
    END IF;

    IF doc_is_pv
    THEN
        doc_modules = doc_modules || to_jsonb('POHIVARA' :: TEXT);
    END IF;

    IF doc_is_eelarve
    THEN
        doc_modules = doc_modules || to_jsonb('EELARVE' :: TEXT);
    END IF;

    IF doc_is_eelproj
    THEN
        doc_modules = doc_modules || to_jsonb('EELPROJ' :: TEXT);
    END IF;

    IF doc_is_palk
    THEN
        doc_modules = doc_modules || to_jsonb('PALK' :: TEXT);
    END IF;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT now()           AS created,
                 userName        AS user,
                 doc_name        AS name,
                 doc_eesti       AS eesti,
                 doc_vene        AS vene,
                 doc_groups      AS groups,
                 doc_modules     AS modules,
                 doc_users       AS users,
                 doc_proc        AS proc,
                 doc_keyshortcut AS keyshortcut,
                 doc_submenu     AS submenu,
                 doc_level       AS level) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO ou.menupohi (pad, bar, idx, properties, status)
        VALUES (doc_pad, doc_bar, doc_idx, json_object, 'active') RETURNING id
            INTO menu_id;
    ELSE

        UPDATE ou.menupohi
        SET pad        = doc_pad,
            bar        = doc_bar,
            idx        = doc_idx,
            properties = json_object
        WHERE id = doc_id RETURNING id
            INTO menu_id;

    END IF;

    RETURN menu_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION ou.sp_salvesta_menupohi(JSON, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_menupohi(JSON, INTEGER, INTEGER) TO dbadmin;


/*

SELECT ou.sp_salvesta_menupohi('{"id":671,"data":{"pad":"test","bar":"test","name":"Test", "vene": "Тест", "eesti": "Testid", "level": 1, "idx": 0, "is_admin": 1, "is_rekl_administraator":1, "is_eelarve":0  }}'
,1, 1)

select * from ou.menupohi order by id desc limit 1
*/