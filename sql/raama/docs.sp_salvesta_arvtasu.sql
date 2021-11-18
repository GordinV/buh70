DROP FUNCTION IF EXISTS docs.sp_salvesta_arvtasu(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_arvtasu(data JSON,
                                                    userid INTEGER,
                                                    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id          INTEGER;
    userName        TEXT;
    doc_id          INTEGER        = data ->> 'id';
    doc_data        JSON           = data ->> 'data';
    doc_rekvid      INTEGER        = doc_data ->> 'rekvid';
    doc_doc_arv_id  INTEGER        = doc_data ->> 'doc_arv_id';
    doc_doc_tasu_id INTEGER        = doc_data ->> 'doc_tasu_id';

    doc_kpv         DATE           = doc_data ->> 'kpv';
    doc_summa       NUMERIC(14, 2) = doc_data ->> 'summa';
    doc_pankkassa   INTEGER        = doc_data ->> 'pankkassa';
    doc_muud        TEXT           = doc_data ->> 'muud';
    v_tasu_dok      RECORD;
    is_import       BOOLEAN        = data ->> 'import';
    l_arv_tasud     NUMERIC        = 0;
    l_arv_summa     NUMERIC        = 0;

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %, user_rekvid %, userId %', userName, user_rekvid, userId;
        RETURN 0;
    END IF;

    -- 3 delete old payment

    IF doc_doc_arv_id IS NOT NULL
    THEN
        DELETE
        FROM docs.arvtasu
        WHERE doc_tasu_id = doc_doc_tasu_id
          AND doc_doc_arv_id NOT IN (SELECT doc_doc_arv_id -- не удаляем оплату текущего счета
                                     UNION
                                     SELECT unnest(d.docs_ids)
                                     FROM docs.doc d
                                     WHERE d.id = doc_doc_arv_id
        ) -- не удаляем связанные счета (предоплата)
          AND pankkassa = doc_pankkassa;
    END IF;

    -- проверяем на сумму оплат. Если счет уже оплачен , то доп. платежи не цепляем
    l_arv_tasud = coalesce((SELECT sum(summa) FROM docs.arvtasu WHERE doc_arv_id = doc_doc_arv_id AND status <> 3), 0);

    l_arv_summa = coalesce((SELECT summa FROM docs.arv WHERE parentid = doc_doc_arv_id), 0);

    IF l_arv_summa - l_arv_tasud <= 0 AND coalesce(doc_summa, 0) > 0
    THEN
        --  счет оплачен, новых платежей не надо

        -- update arv jaak
        PERFORM docs.sp_update_arv_jaak(doc_doc_arv_id);
        RETURN 0;
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN
        -- check if tasu from journal
        IF doc_doc_arv_id IS NULL OR empty(doc_doc_arv_id) AND NOT empty(doc_doc_tasu_id) AND doc_pankkassa = 3
        THEN

            --1 open jounal doc
            SELECT * INTO v_tasu_dok
            FROM docs.journal
            WHERE parentid = doc_doc_tasu_id;

            -- 2 find arv doc
            SELECT d.id INTO doc_doc_arv_id
            FROM docs.doc d
                     INNER JOIN docs.arv a ON a.parentid = d.id
            WHERE d.rekvid = v_tasu_dok.rekvid
              AND ltrim(rtrim(number)) = ltrim(rtrim(v_tasu_dok.dok))
              AND a.asutusid = v_tasu_dok.asutusid
            ORDER BY jaak DESC
            LIMIT 1;

            IF doc_doc_arv_id IS NULL
            THEN
                RAISE NOTICE 'tasu dok ei leidnud';
                RETURN 0;
            END IF;


        END IF;


        INSERT INTO docs.arvtasu (rekvid, doc_arv_id, doc_tasu_id, kpv, summa, muud, status, pankkassa)
        VALUES (doc_rekvid, doc_doc_arv_id, doc_doc_tasu_id, doc_kpv, doc_summa, doc_muud, 1,
                doc_pankkassa) RETURNING id
                   INTO lib_id;
    ELSE

        UPDATE docs.arvtasu
        SET doc_arv_id  = doc_doc_arv_id,
            doc_tasu_id = doc_doc_tasu_id,
            kpv         = doc_kpv,
            summa       = doc_summa,
            muud        = doc_muud,
            status      = CASE
                              WHEN status = 3
                                  THEN 1
                              ELSE status END
        WHERE id = doc_id RETURNING id
            INTO lib_id;
    END IF;

    -- установить связи
    -- добавим сязь счета и оплаты
    UPDATE docs.doc SET docs_ids = array_append(docs_ids, doc_doc_tasu_id) WHERE id = doc_doc_arv_id;

    -- добавим связь оплаты со счетом
    UPDATE docs.doc SET docs_ids = array_append(docs_ids, doc_doc_arv_id) WHERE id = doc_doc_tasu_id;


    -- update arv jaak
--    PERFORM docs.sp_update_arv_jaak(doc_doc_arv_id);
    RETURN lib_id;

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

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arvtasu(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arvtasu(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*
select docs.sp_salvesta_arvtasu('{"id":0,"data":{"doc_arv_id":39,"doc_tasu_id":null,"dok":null,"dok_type":null,"id":0,"kpv":"20180302","kuurs":1,"muud":null,"number":null,"pankkassa":4,"rekvid":1,"summa":100,"userid":1,"valuuta":"EUR"}}'
,1, 1)


{"id":1,"data":{"asutusid":0,"id":1,"kbmkonto":"","kbmlausend":0,"konto":"111","kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","muud":"","parentid":1,"proc_":"","registr":1,"selg":"","vaatalaus":1}}
{"id":0,"data":{"asutusid":null,"dok":"ARV","id":0,"kbmkonto":null,"konto":null,"kood1":null,"kood2":null,"kood3":null,"kood5":null,"muud":null,"nimetus":null,"proc_":null,"registr":0,"rekvid":1,"selg":"__test8514","userid":1,"vaatalaus":0}}
{"id":1,"data":{"asutusid":2,"id":1,"kbmkonto":"113","kbmlausend":0,"konto":"111","kood1":"test","kood2":"","kood3":"","kood4":"","kood5":"","muud":"","parentid":1,"proc_":"","registr":1,"selg":"","vaatalaus":1}}
*/