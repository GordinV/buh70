DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_kaart(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_lapse_kaart(data JSONB,
                                                          userid INTEGER,
                                                          user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName             TEXT;
    doc_data             JSON    = data ->> 'data';
    doc_id               INTEGER = doc_data ->> 'id';
    doc_parentid         INTEGER = doc_data ->> 'parentid';
    doc_nomid            INTEGER = doc_data ->> 'nomid';
    doc_tunnus           TEXT    = doc_data ->> 'tunnus';
    doc_hind             NUMERIC = doc_data ->> 'hind';
    doc_yksus            TEXT    = doc_data ->> 'yksus';
    doc_all_yksus        TEXT    = doc_data ->> 'all_yksus';
    doc_soodus           NUMERIC = doc_data ->> 'soodus';
    doc_kas_protsent     BOOLEAN = doc_data ->> 'kas_protsent';
    doc_kas_eraldi       BOOLEAN = doc_data ->> 'kas_eraldi';
    doc_kas_ettemaks     BOOLEAN = doc_data ->> 'kas_ettemaks';
    doc_kas_inf3         BOOLEAN = doc_data ->> 'kas_inf3';
    doc_sooduse_alg      DATE    = doc_data ->> 'sooduse_alg';
    doc_sooduse_lopp     DATE    = doc_data ->> 'sooduse_lopp';
    doc_alg_kpv          DATE    = doc_data ->> 'alg_kpv';
    doc_lopp_kpv         DATE    = doc_data ->> 'lopp_kpv';
    doc_muud             TEXT    = doc_data ->> 'muud';
    doc_kogus            NUMERIC = doc_data ->> 'kogus';
    doc_ettemaksu_period INTEGER = doc_data ->> 'ettemaksu_period';
    json_props           JSONB;
    json_ajalugu         JSONB;
BEGIN
    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
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
                              doc_kas_ettemaks     AS kas_ettemaks
                      ) row;

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
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;


    RETURN doc_id;

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

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_kaart(JSONB, INTEGER, INTEGER) TO arvestaja;


/*

select * from libs.nomenklatuur where rekvid = 63

select lapsed.sp_salvesta_lapse_kaart('{"data":{"id":23,"parentid":7,"nomid":16468,"tunnus":"test","muud":"test","userid":70,"kas_ettemaks":"true", "ettemaksu_period":1}}'::jsonb, 70::integer, 63::integer) as id


select * from lapsed.lapse_kaart
*/