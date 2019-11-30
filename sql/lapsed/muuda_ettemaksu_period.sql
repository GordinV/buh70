-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.muuda_ettemaksu_period(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.muuda_ettemaksu_period(IN user_id INTEGER,
                                                         IN l_lapse_teenuse_id INTEGER,
                                                         IN l_ettemaksud_period INTEGER,
                                                         OUT error_code INTEGER,
                                                         OUT result INTEGER,
                                                         OUT doc_type_id TEXT,
                                                         OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE

    l_kaart_id INTEGER;
    userName   TEXT = (SELECT kasutaja
                       FROM ou.userid u
                       WHERE u.id = user_id);
BEGIN
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        error_code = 1;
        error_message = 'Kasutaja ei leidnud';

        RETURN;
    END IF;


    -- правим
    UPDATE lapsed.lapse_kaart
    SET properties = properties::JSONB || (SELECT to_jsonb(row)
                                           FROM (SELECT l_ettemaksud_period AS ettemaksu_period) row),
        ajalugu    = coalesce(ajalugu, '[]') :: JSONB || (SELECT to_jsonb(row)
                                                          FROM (SELECT now()    AS updated,
                                                                       userName AS user) row)

    WHERE id = l_lapse_teenuse_id
      AND (properties ->> 'kas_ettemaks')::BOOLEAN RETURNING id INTO l_kaart_id;

raise notice 'l_kaart_id %', l_kaart_id;
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

GRANT EXECUTE ON FUNCTION lapsed.muuda_ettemaksu_period(INTEGER, INTEGER, INTEGER) TO arvestaja;


/*
select * from lapsed.muuda_ettemaksu_period(70, 23, 3 )

*/