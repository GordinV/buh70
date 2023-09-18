CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_vanem(data JSONB,
                                                    userid INTEGER,
                                                    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName           TEXT;
    doc_data           JSON    = data ->> 'data';
    doc_id             INTEGER = doc_data ->> 'id';
    doc_parentid       INTEGER = doc_data ->> 'parentid';
    doc_asutusid       INTEGER = doc_data ->> 'asutusid';
    doc_arved          BOOLEAN = coalesce((doc_data ->> 'arved')::BOOLEAN, FALSE);
    doc_suhtumine      TEXT    = doc_data ->> 'suhtumine';
    doc_kas_paberil    BOOLEAN = coalesce((doc_data ->> 'kas_paberil')::BOOLEAN, FALSE);
    doc_kas_email      BOOLEAN = coalesce((doc_data ->> 'kas_email')::BOOLEAN, FALSE);
    doc_kas_earve      BOOLEAN = coalesce((doc_data ->> 'kas_earve')::BOOLEAN, FALSE);
    doc_email_alates   DATE    = CASE
                                     WHEN doc_data ->> 'email_alates' = '' THEN NULL::DATE
                                     ELSE (doc_data ->> 'email_alates')::DATE END;
    doc_pank           TEXT    = ltrim(rtrim(doc_data ->> 'pank'));
    doc_iban           TEXT    = ltrim(rtrim(doc_data ->> 'iban'));
    doc_kas_esindaja   BOOLEAN = coalesce((doc_data ->> 'kas_esindaja')::BOOLEAN, FALSE);
    doc_muud           TEXT    = doc_data ->> 'muud';
    json_props         JSONB;
    json_ajalugu       JSONB;
    l_prev_arv_isik_id INTEGER;
    v_eelmise_vanem    RECORD; -- прежнее состояние
    json_va_props      JSONB;

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
        RAISE EXCEPTION 'User not found %', user;
    END IF;

    IF NOT empty(coalesce(doc_iban, '')) AND left(doc_iban, 2) = 'EE' AND length(ltrim(rtrim(doc_iban))) <> 20
    THEN
        RAISE EXCEPTION 'Viga: Vale IBAN pikkus (<> 20) %', doc_iban;
    END IF;

    -- сохраняем ид прежнего ответственного
    IF doc_arved
    THEN
        l_prev_arv_isik_id = (SELECT va.asutusid
                              FROM lapsed.vanem_arveldus va
                              WHERE va.parentid = doc_parentid
                                AND va.rekvid = user_rekvid
                                AND va.arveldus
                              LIMIT 1);
    END IF;

    IF l_prev_arv_isik_id <> doc_asutusid
    THEN
        -- происходит смена ответственного, проверяем на не отправленные счета
        IF exists(SELECT id
                  FROM lapsed.cur_laste_arved a
                  WHERE asutusid = l_prev_arv_isik_id
                    AND a.rekvid = user_rekvid
                    AND NOT a.kas_esitatud)
        THEN
            -- ошибка. нельзя менять ответственного, пока есть не отправленные счета
            RAISE EXCEPTION 'Viga: Olemas mitte saadetud arveid';

        END IF;
    END IF;

    -- контроль за наличием каналов отправки счета
    IF (doc_arved AND NOT doc_kas_paberil AND NOT doc_kas_email AND NOT doc_kas_earve)
    THEN
        RAISE EXCEPTION 'Viga: mitte ühtegi arvelduse kanal märgistatud';
    END IF;

    json_props = to_jsonb(row)
                 FROM (SELECT doc_suhtumine    AS suhtumine,
                              doc_arved        AS arved,
                              doc_kas_paberil  AS kas_paberil,
                              doc_kas_email    AS kas_email,
                              doc_email_alates AS email_alates,
                              doc_kas_esindaja AS kas_esindaja
                      ) row;

    -- ищем ранее удаленные записи
    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT id
        INTO doc_id
        FROM lapsed.vanemad
        WHERE parentid = doc_parentid
          AND asutusid = doc_asutusid;
    END IF;


    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.vanemad (parentid, asutusid, muud, properties, ajalugu)
        VALUES (doc_parentid, doc_asutusid, doc_muud, json_props, '[]' :: JSONB || json_ajalugu) RETURNING id
            INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user
                            ) row;

        UPDATE lapsed.vanemad
        SET asutusid   = doc_asutusid,
            properties = coalesce(properties, '{}'::JSONB)::JSONB || json_props,
            muud       = doc_muud,
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu,
            staatus    = CASE WHEN staatus = 3 THEN 1 ELSE staatus END
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;

-- проверим наличие статус ответственного у родителей
    IF doc_kas_esindaja AND exists(SELECT id
                                   FROM lapsed.vanemad
                                   WHERE parentid = doc_parentid
                                     AND (properties ->> 'kas_esindaja')::BOOLEAN
                                     AND id <> doc_id)
    THEN
        -- убираем этот статус , если есть у других роделей ребенка
        UPDATE lapsed.vanemad
        SET properties = properties::JSONB || '{
          "kas_esindaja": false
        }'::JSONB
        WHERE parentid = doc_parentid
          AND id <> doc_id
          AND (properties ->> 'kas_esindaja')::BOOLEAN;
    END IF;

-- arveldused
    json_va_props = json_build_object('kas_earve', doc_kas_earve, 'pank', doc_pank, 'iban', doc_iban, 'email_alates',
                                      doc_email_alates);

    IF exists(SELECT id
              FROM lapsed.vanem_arveldus
              WHERE parentid = doc_parentid
                AND asutusid = doc_asutusid
                AND rekvid = user_rekvid)
    THEN

        UPDATE lapsed.vanem_arveldus
        SET arveldus    = doc_arved,
            kas_email   = coalesce(doc_kas_email, FALSE),
            kas_paberil = coalesce(doc_kas_paberil, TRUE),
            properties  = coalesce(properties, '{}'::JSONB)::JSONB || json_va_props
        WHERE parentid = doc_parentid
          AND asutusid = doc_asutusid
          AND rekvid = user_rekvid;
    ELSE
        INSERT INTO lapsed.vanem_arveldus (parentid, asutusid, rekvid, arveldus, properties, kas_email, kas_paberil)
        VALUES (doc_parentid, doc_asutusid, user_rekvid, doc_arved, json_va_props, FALSE, TRUE);

    END IF;

    -- уберем статус у других родителей, если надо
    IF (doc_arved)
    THEN
        UPDATE lapsed.vanem_arveldus
        SET arveldus = FALSE
        WHERE parentid = doc_parentid
          AND rekvid = user_rekvid
          AND asutusid <> doc_asutusid
          AND arveldus = TRUE;
    END IF;

    -- делаем перенос сальдо
/*    IF (l_prev_arv_isik_id IS NOT NULL AND doc_arved and l_prev_arv_isik_id <> doc_asutusid)
    THEN
        PERFORM docs.saldo_ulekanne_lausend(userId,
                                            l_prev_arv_isik_id,
                                            doc_asutusid,
                                            current_date,
                                            doc_parentid);

    END IF;
*/
    RETURN doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_vanem(JSONB, INTEGER, INTEGER) TO arvestaja;


/*

select * from lapsed.vanemad where id = 1

select lapsed.sp_salvesta_vanem('{"data":{"id":0,"parentid":7,"asutusid":31825,"arved":"jah","muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id
select lapsed.sp_salvesta_vanem('{"data":{"id":2,"parentid":1,"asutusid":1621,"arved":"Jah","muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id

*/