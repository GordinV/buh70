DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_taabel(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_lapse_taabel(data JSONB,
                                                           userid INTEGER,
                                                           user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName           TEXT;
    doc_data           JSON    = data ->> 'data';
    doc_id             INTEGER = doc_data ->> 'id';
    doc_parentid       INTEGER = doc_data ->> 'parentid';
    doc_lapse_kaart_id INTEGER = doc_data ->> 'lapse_kaart_id';
    doc_nomid          INTEGER = (SELECT nomid
                                  FROM lapsed.lapse_kaart
                                  WHERE id = doc_lapse_kaart_id);
    doc_kogus          NUMERIC = doc_data ->> 'kogus';
    doc_kulastused     NUMERIC = doc_data ->> 'kulastused';
    doc_too_paevad     NUMERIC = doc_data ->> 'too_paevad';
    doc_kovid          NUMERIC = doc_data ->> 'kovid';
    doc_hind           NUMERIC = doc_data ->> 'hind';
    doc_soodustus      NUMERIC = doc_data ->> 'soodustus';
    doc_summa          NUMERIC = doc_data ->> 'summa';
    doc_vahe           NUMERIC = CASE WHEN doc_data ->> 'vahe'::TEXT = '' THEN 0 ELSE (doc_data ->> 'vahe')::NUMERIC END;
    doc_kuu            INTEGER = doc_data ->> 'kuu';
    doc_aasta          INTEGER = doc_data ->> 'aasta';
    doc_muud           TEXT    = doc_data ->> 'muud';
    doc_alus_hind      NUMERIC = doc_data ->> 'alus_hind';
    doc_alus_soodustus NUMERIC = doc_data ->> 'alus_soodustus';
    doc_sooduse_alg    DATE    = doc_data ->> 'sooduse_alg';
    doc_sooduse_lopp   DATE    = doc_data ->> 'sooduse_lopp';
    doc_umberarvestus  BOOLEAN = coalesce((doc_data ->> 'umberarvestus')::BOOLEAN, FALSE);
    doc_kas_asendus    BOOLEAN = coalesce((doc_data ->> 'kas_asendus')::BOOLEAN, FALSE);
    doc_asendus_id     INTEGER = doc_data ->> 'asendus_id';
    doc_staatus        INTEGER = 1;
    json_ajalugu       JSONB;
    json_props         JSONB;
    v_lapse_kaart      RECORD;
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

    -- check if service is valid

    SELECT coalesce((lk.properties ->> 'alg_kpv')::DATE, date(year(), month(), 1)) AS alg_kpv,
           coalesce((lk.properties ->> 'lopp_kpv')::DATE, date(year(), 12, 31))    AS lopp_kpv
    INTO v_lapse_kaart
    FROM lapsed.lapse_kaart lk
    WHERE lk.id = doc_lapse_kaart_id;

    json_props = to_jsonb(row)
                 FROM (SELECT doc_kulastused     AS kulastused,
                              doc_kovid          AS kovid,
                              doc_too_paevad     AS too_paevad,
                              doc_alus_hind      AS alus_hind,
                              doc_alus_soodustus AS alus_soodustus,
                              doc_sooduse_alg    AS sooduse_alg,
                              doc_sooduse_lopp   AS sooduse_lopp,
                              doc_kas_asendus    AS kas_asendus,
                              doc_asendus_id     AS asendus_id
                      ) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.lapse_taabel (parentid, lapse_kaart_id, nomid, rekvid, hind, kogus, summa, vahe, soodustus,
                                         kuu, aasta,
                                         muud,
                                         ajalugu, umberarvestus, properties)
        VALUES (doc_parentid, doc_lapse_kaart_id, doc_nomid, user_rekvid, doc_hind, doc_kogus, doc_summa, doc_vahe,
                doc_soodustus,
                doc_kuu, doc_aasta,
                doc_muud,
                '[]' :: JSONB || json_ajalugu, doc_umberarvestus, json_props) RETURNING id
                   INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user
                             FROM lapsed.lapse_taabel lt
                             WHERE id = doc_id
                            ) row;

        UPDATE lapsed.lapse_taabel
        SET nomid          = doc_nomid,
            lapse_kaart_id = doc_lapse_kaart_id,
            hind           = doc_hind,
            kogus          = doc_kogus,
            summa          = doc_summa,
            vahe           = doc_vahe,
            soodustus      = doc_soodustus,
            kuu            = doc_kuu,
            aasta          = doc_aasta,
            muud           = doc_muud,
            ajalugu        = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu,
            staatus        = doc_staatus,
            umberarvestus  = doc_umberarvestus,
            properties     = coalesce(properties, '{}') :: JSONB || json_props
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;

    -- для импортированный из замещения
    IF (doc_kas_asendus AND doc_asendus_id IS NOT NULL)
    THEN
        -- отметим статус - импортирован
        UPDATE lapsed.asendus_taabel SET staatus = 2 WHERE id = doc_asendus_id;
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

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_taabel(JSONB, INTEGER, INTEGER) TO arvestaja;


/*
id: 0,
         parentid: 16,
         nomid: 17748,
         kuu: 9,
         aasta: 2019,
         kogus: 1,
         muud: 'test muud' } } 70


select lapsed.sp_salvesta_lapse_taabel('{"data":{"id":0,"parentid":16,"nomid":17748,"kuu":9,"aasta":2019,"kogus":1,"muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id

*/