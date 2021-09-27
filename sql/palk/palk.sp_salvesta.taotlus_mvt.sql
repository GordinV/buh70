DROP FUNCTION IF EXISTS palk.sp_salvesta_taotlus_mvt(DATA JSON, userid INTEGER, user_rekvid INTEGER);

CREATE FUNCTION palk.sp_salvesta_taotlus_mvt(data JSON, userid INTEGER, user_rekvid INTEGER)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    taotlus_id      INTEGER;
    userName        TEXT;
    doc_id          INTEGER        = data ->> 'id';
    doc_data        JSON           = data ->> 'data';
    doc_kpv         DATE           = doc_data ->> 'kpv';
    doc_alg_kpv     DATE           = doc_data ->> 'alg_kpv';
    doc_lopp_kpv    DATE           = doc_data ->> 'lopp_kpv';
    doc_lepingid    INTEGER        = doc_data ->> 'lepingid';
    doc_summa       NUMERIC(12, 2) = doc_data ->> 'summa';
    doc_muud        TEXT           = doc_data ->> 'muud';

    new_history     JSONB;
    v_taotlus_mvt   RECORD;
    is_import       BOOLEAN        = data ->> 'import';
    l_error_message TEXT;
BEGIN

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;
    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    -- вставка или апдейт docs.doc

    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS created,
                     userName AS user) row;

        INSERT INTO palk.taotlus_mvt (lepingid, kpv, alg_kpv, lopp_kpv, summa, status, ajalugu, muud)
        VALUES (doc_lepingid, doc_kpv, doc_alg_kpv, doc_lopp_kpv, doc_summa,
                'active', new_history, doc_muud) RETURNING id
                   INTO taotlus_id;

    ELSE
        -- контроля

        SELECT * INTO v_taotlus_mvt FROM palk.taotlus_mvt WHERE id = doc_id;

        -- Если в текущем месяце внесено новое заявление с суммой, то сумму можно менять только первый месяц подачи заявления
        -- - текущий месяц (работник может предоставить заявление в начале месяца и в середине месяца с разными суммами)
        IF current_date > v_taotlus_mvt.kpv
            AND current_date > date(year(v_taotlus_mvt.kpv), month(v_taotlus_mvt.kpv), 1) + INTERVAL '1 month'
        THEN
            l_error_message = 'Taotlus juba kinni';
            -- lubatud ainult lopp kpv
            IF doc_lopp_kpv < (date(year(current_date), month(current_date), 1) - 1)
            THEN
                doc_lopp_kpv = v_taotlus_mvt.lopp_kpv;
            END IF;
        ELSE

        END IF;

        --        RAISE EXCEPTION 'Ei saa muuda taotluse andmed sest sellest periodis juba arvestatud palk';


        -- history

        SELECT row_to_json(row) INTO new_history
        FROM (SELECT now()    AS updated,
                     userName AS user) row;

        IF l_error_message IS NOT NULL
        THEN
            UPDATE palk.taotlus_mvt
            SET lopp_kpv = doc_lopp_kpv,
                ajalugu  = '[]'::JSONB || coalesce(ajalugu, '[]'::JSONB) || new_history,
                muud     = doc_muud
            WHERE id = doc_id RETURNING id
                INTO taotlus_id;
        ELSE
            UPDATE palk.taotlus_mvt
            SET kpv      = doc_kpv,
                lopp_kpv = doc_lopp_kpv,
                summa    = doc_summa,
                ajalugu  = '[]'::JSONB || coalesce(ajalugu, '[]'::JSONB) || new_history,
                muud     = doc_muud
            WHERE id = doc_id RETURNING id
                INTO taotlus_id;
        END IF;

    END IF;

    RETURN taotlus_id;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;
END;
$$;

GRANT EXECUTE ON FUNCTION palk.sp_salvesta_taotlus_mvt(DATA JSON, userid INTEGER, user_rekvid INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_salvesta_taotlus_mvt(DATA JSON, userid INTEGER, user_rekvid INTEGER) TO dbpeakasutaja;


/*
SELECT palk.sp_salvesta_puudumine(
    '{"id":0,"data":{"doc_type_id":"PUUDUMINE","id":0,"kpv1":"20180401","kpv2":"20180401","lepingid":4,"libid":384,"muud":null,"paevad":0,"parentid":0,"puudumiste_liik":"PUHKUS","status":1,"summa":100,"tyyp":1,"userid":1}}',
    1, 1)
*/
