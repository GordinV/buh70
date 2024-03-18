DROP FUNCTION IF EXISTS palk.sp_salvesta_palk_kaart(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION palk.sp_salvesta_palk_kaart(data JSON,
                                                       userid INTEGER,
                                                       user_rekvid INTEGER)
    RETURNS INTEGER
    LANGUAGE 'plpgsql'
AS
$BODY$

DECLARE
    kaart_id       INTEGER;
    userName       TEXT;
    doc_id         INTEGER        = data ->> 'id';
    doc_data       JSON           = data ->> 'data';
    doc_parentid   INTEGER        = doc_data ->> 'parentid';
    doc_libid      INTEGER        = doc_data ->> 'libid';
    doc_lepingid   INTEGER        = doc_data ->> 'lepingid';
    doc_summa      NUMERIC(14, 4) = doc_data ->> 'summa';
    doc_percent_   INTEGER        = doc_data ->> 'percent_';
    doc_tulumaks   INTEGER        = doc_data ->> 'tulumaks';
    doc_tulumaar   INTEGER        = doc_data ->> 'tulumaar';
    doc_alimentid  INTEGER        = doc_data ->> 'alimentid';
    doc_tunnus     TEXT           = doc_data ->> 'tunnus';
    doc_objekt     TEXT           = doc_data ->> 'objekt';
    doc_minsots    INTEGER        = doc_data ->> 'minsots';
    doc_muud       TEXT           = doc_data ->> 'muud';
    doc_status     INTEGER        = doc_data ->> 'status';

    new_properties JSONB;
    new_history    JSONB;
    v_palk_kaart   RECORD;
    is_import      BOOLEAN        = data ->> 'import';
    l_props        JSONB;
BEGIN

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    -- проверка на уникальность
    kaart_id = (SELECT id
                FROM palk.palk_kaart
                WHERE lepingid = doc_lepingid
                  AND libid = doc_libid
                  AND status < 3
                  AND (doc_id = 0 OR id <> doc_id));

    IF kaart_id IS NOT NULL
    THEN
        -- если создание записи, то отдадим номер уже существующей и обновим ее иначе вернем ошибку
        IF doc_id = 0
        THEN
            doc_id = kaart_id;
        ELSE
            RAISE EXCEPTION 'Kiri sele parametridega juba olemas';
            RETURN 0;
        END IF;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    l_props = (SELECT row_to_json(row)
               FROM (SELECT doc_objekt AS objekt) row);


    -- вставка или апдейт docs.doc

    IF doc_id IS NULL OR doc_id = 0
    THEN


        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;


        INSERT INTO palk.palk_kaart (parentid, libid, lepingid, summa, percent_, tulumaks, tulumaar,
                                     alimentid, tunnus, minsots, status, ajalugu, muud, properties)
        VALUES (doc_parentid, doc_libid, doc_lepingid, doc_summa, doc_percent_, doc_tulumaks, doc_tulumaar,
                doc_alimentid, doc_tunnus, doc_minsots, CASE
                                                            WHEN is_import IS NOT NULL
                                                                THEN doc_status
                                                            ELSE 1 END,
                new_history, doc_muud, l_props) RETURNING id
                   INTO kaart_id;


    ELSE
        -- history
        SELECT *
        INTO v_palk_kaart
        FROM palk.palk_kaart
        WHERE id = doc_id;

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()        AS updated,
                     userName     AS user,
                     v_palk_kaart AS palk_kaart) row;

        UPDATE palk.palk_kaart
        SET libid      = doc_libid,
            lepingid   = doc_lepingid,
            summa      = doc_summa,
            percent_   = doc_percent_,
            tulumaks   = doc_tulumaks,
            tulumaar   = doc_tulumaar,
            alimentid  = doc_alimentid,
            tunnus     = doc_tunnus,
            minsots    = doc_minsots,
            ajalugu    = coalesce(ajalugu, '[]'::JSONB) || new_history::JSONB,
            muud       = doc_muud,
            properties = coalesce(properties, '{}'::JSONB) || l_props,
            timestamp  = now(),
            status     = doc_status
        WHERE id = doc_id RETURNING id
            INTO kaart_id;

    END IF;

    RETURN kaart_id;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error %', SQLERRM;
            RETURN 0;
END ;
$BODY$;


GRANT EXECUTE ON FUNCTION palk.sp_salvesta_palk_kaart(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_salvesta_palk_kaart(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*
select palk.sp_salvesta_palk_kaart('{"id":295562,"data":{"alimentid":0,"amet":"Sotsiaalhooldaja","asutusest":1,"doc_type_id":"PALK_KAART","id":295562,"kood":"SMAKS-ETTEM-2201LEP","kuurs":1,"lepingid":35812,"libid":236727,"liik":5,"maks":0,"minsots":0,"muud":"","nimetus":"NSTK SOTSIAALMAKSU ETTEMAKS 10201-506-2201-LE-P","osakond":"NSTK SM (p.k.k.t.)","osakondid":235983,"parentid":29860,"percent_":0,"status":1,"summa":33,"tululiik":"","tulumaar":1,"tulumaks":0,"tund":1,"tunnus":"2201","userid":5175,"valuuta":"EUR"}}',5175, 132);

select * from libs.asutus

*/