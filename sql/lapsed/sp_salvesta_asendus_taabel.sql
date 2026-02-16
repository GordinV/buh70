DROP FUNCTION IF EXISTS lapsed.sp_salvesta_asendus_taabel(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_asendus_taabel(data JSONB,
                                                             userid INTEGER,
                                                             user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName         TEXT;
    doc_data         JSON    = data ->> 'data';
    doc_id           INTEGER = doc_data ->> 'id';
    doc_parentid     INTEGER = doc_data ->> 'parentid';
    doc_nomid        INTEGER = doc_data ->> 'nomid';
    doc_yksusid      INTEGER = doc_data ->> 'yksusid';
    doc_kogus        NUMERIC = doc_data ->> 'kogus';
    doc_hind         NUMERIC = doc_data ->> 'hind';
    doc_summa        NUMERIC = doc_data ->> 'summa';
    doc_kuu          INTEGER = doc_data ->> 'kuu';
    doc_aasta        INTEGER = doc_data ->> 'aasta';
    doc_muud         TEXT    = doc_data ->> 'muud';
    doc_viitenumber  TEXT    = doc_data ->> 'viitenumber';
    l_nom_id         integer;
    doc_staatus      INTEGER = 1;
    json_ajalugu     JSONB;
    v_nom            record;
    l_lapse_rekvid   integer;
    l_lapse_kaart_id integer;
BEGIN
    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT
        kasutaja
    INTO userName
    FROM
        ou.userid u
    WHERE
          u.rekvid = user_rekvid
      AND u.id = userId;

    IF userName IS NULL
    THEN
        RAISE EXCEPTION 'Viga, User not found %', user;
    END IF;

    -- проверка на сохранение для "своих" детей
    IF lapsed.get_rekv_id_from_viitenumber(doc_viitenumber) = user_rekvid
    THEN
        RAISE EXCEPTION 'Viga, Ei saa sisesta selle asutuse lapsed %', doc_viitenumber;
    END IF;


    -- проверка на наличие услуг в родном учреждении
    -- ищем услугу по коду другово учреждения
    select
        kood
    into v_nom
    from
        libs.nomenklatuur n
    where
        id = doc_nomid;

    l_lapse_rekvid = lapsed.get_rekv_id_from_viitenumber(doc_viitenumber);

    SELECT
        id
    INTO l_nom_id
    FROM
        libs.nomenklatuur n
    WHERE
          ltrim(rtrim(kood)) = ltrim(rtrim(v_nom.kood))
      AND rekvid = l_lapse_rekvid
      AND n.status <> 3
    ORDER BY id
    LIMIT 1;

    -- ищем запись в карте
    SELECT
        id
    INTO l_lapse_kaart_id
    FROM
        lapsed.lapse_kaart lk
    WHERE
          parentid = doc_parentid
      AND nomid = l_nom_id
      AND rekvid = l_lapse_rekvid
      AND staatus <> 3
      AND (lk.properties ->> 'alg_kpv')::DATE <= make_date(doc_aasta, doc_kuu, 1)
    ORDER BY (lk.properties ->> 'lopp_kpv')::DATE DESC
    LIMIT 1;

    IF (l_lapse_kaart_id IS NULL)
    THEN
        raise exception 'Puudub  teenused , VN:%, Kood:%', doc_viitenumber, v_nom.kood;
    END IF;


    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM
                           (
                               SELECT
                                   now()    AS created,
                                   userName AS user
                           ) row;

        INSERT INTO
            lapsed.asendus_taabel (parentid, yksusid, nomid, rekvid, hind, kogus, summa,
                                   kuu, aasta, viitenumber,
                                   muud,
                                   ajalugu)
        VALUES
            (doc_parentid, doc_yksusid, doc_nomid, user_rekvid, doc_hind, doc_kogus, doc_summa,
             doc_kuu, doc_aasta, doc_viitenumber,
             doc_muud,
             '[]' :: JSONB || json_ajalugu)
        RETURNING id
            INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM
                           (
                               SELECT
                                   now()    AS updated,
                                   userName AS user
                           ) row;

        UPDATE lapsed.asendus_taabel
        SET
            nomid       = doc_nomid,
            yksusid     = doc_yksusid,
            viitenumber = doc_viitenumber,
            hind        = doc_hind,
            kogus       = doc_kogus,
            summa       = doc_summa,
            kuu         = doc_kuu,
            aasta       = doc_aasta,
            muud        = doc_muud,
            ajalugu     = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu,
            staatus     = doc_staatus
        WHERE
            id = doc_id
        RETURNING id
            INTO doc_id;

    END IF;


    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_asendus_taabel(JSONB, INTEGER, INTEGER) TO arvestaja;


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