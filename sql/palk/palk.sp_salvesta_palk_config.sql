DROP FUNCTION IF EXISTS palk.sp_salvesta_palk_config(DATA JSON, userid INTEGER, user_rekvid INTEGER);

CREATE FUNCTION palk.sp_salvesta_palk_config(data JSON, user_id INTEGER, user_rekvid INTEGER)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    config_id               INTEGER;
    userName                TEXT;
    doc_id                  INTEGER = data ->> 'id';
    doc_data                JSON    = data ->> 'data';
    doc_minpalk             NUMERIC = doc_data ->> 'minpalk';
    doc_tulubaas            NUMERIC = doc_data ->> 'tulubaas';
    doc_pensionari_tulubaas NUMERIC = coalesce((doc_data ->> 'pensionari_tulubaas')::numeric, 704)::NUMERIC;
    doc_round               NUMERIC = doc_data ->> 'round';
    doc_jaak                NUMERIC = doc_data ->> 'jaak';
    doc_genlausend          INTEGER = doc_data ->> 'genlausend';
    doc_suurasu             INTEGER = doc_data ->> 'suurasu';
    doc_tm                  NUMERIC = doc_data ->> 'tm';
    doc_pm                  NUMERIC = doc_data ->> 'pm';
    doc_tka                 NUMERIC = doc_data ->> 'tka';
    doc_tki                 NUMERIC = doc_data ->> 'tki';
    doc_sm                  NUMERIC = doc_data ->> 'sm';
    doc_muud1               NUMERIC = doc_data ->> 'muud1';
    doc_muud2               NUMERIC = doc_data ->> 'muud2';
    doc_mmk                 BOOLEAN = coalesce((doc_data ->> 'mmk')::BOOLEAN, FALSE);

    new_history             JSONB;
    l_jsonb                 JSONB;
BEGIN
    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT row_to_json(row)
    INTO l_jsonb
    FROM (SELECT (doc_mmk) AS mmk) row;


    -- вставка или апдейт docs.doc

    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        INSERT INTO palk.palk_config (rekvid, minpalk, tulubaas, round, jaak, genlausend, suurasu, tm,
                                      pm, tka, tki, sm, muud1, muud2, ajalugu, properties)
        VALUES (user_rekvid, doc_minpalk, doc_tulubaas, doc_round, doc_jaak, doc_genlausend, doc_suurasu, doc_tm,
                doc_pm, doc_tka, doc_tki, doc_sm, doc_muud1, doc_muud2, new_history, l_jsonb) RETURNING id
                   INTO config_id;

    ELSE

        SELECT row_to_json(row)
        INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        UPDATE palk.palk_config
        SET minpalk    = doc_minpalk,
            tulubaas   = doc_tulubaas,
            round      = doc_round,
            jaak       = doc_jaak,
            genlausend = doc_genlausend,
            suurasu    = doc_suurasu,
            tm         = doc_tm,
            pm         = doc_pm,
            tka        = doc_tka,
            tki        = doc_tki,
            sm         = doc_sm,
            muud1      = doc_muud1,
            muud2      = doc_muud2,
            ajalugu    = new_history,
            properties = l_jsonb
        WHERE id = doc_id RETURNING id
            INTO config_id;

    END IF;

    RETURN config_id;
END;
$$;

/*
SELECT palk.sp_salvesta_palk_config(
    '{"id":1,"data":{"doc_type_id":"PALK_CONFIG","genlausend":1,"id":1,"jaak":0,"minpalk":654,"mmk":0,"muud1":null,"muud2":null,"pensionari_tulubaas":704,"pm":2,"rekvid":28,"round":0.01,"sm":33,"status":"active","suurasu":0,"tka":0.800000,"tki":1.600000,"tm":20,"tulubaas":654,"userid":4862}}',
    1, 1)
*/
