DROP FUNCTION IF EXISTS update_mk_klassif();

CREATE FUNCTION update_mk_klassif()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_arv    RECORD;
    v_mk     RECORD;
    l_arv_id INTEGER;
BEGIN
    FOR v_mk IN
        SELECT d.id,
               mk.id                                                                                AS mk_id,
               d.docs_ids,
               (SELECT id FROM ou.userid u WHERE u.rekvid = d.rekvid AND kasutaja = 'vlad' LIMIT 1) AS user_id
        FROM docs.doc d
                 INNER JOIN docs.mk mk ON mk.parentid = d.id
        WHERE d.rekvid in (select id from ou.rekv where rekv.parentid = 119 and id not in (82))
--          AND d.id = 2335422
        LOOP
            -- ищем счет
            SELECT id
            INTO l_arv_id
            FROM docs.arv
            WHERE parentid IN (
                SELECT unnest(v_mk.docs_ids)
            ) ORDER BY id LIMIT 1;

            SELECT * INTO v_arv FROM docs.arv1 WHERE parentid = l_arv_id ORDER BY summa DESC LIMIT 1;
            UPDATE docs.mk1
            SET kood1  = v_arv.kood1,
                kood2  = v_arv.kood2,
                kood3  = v_arv.kood3,
                kood4  = v_arv.kood4,
                kood5  = v_arv.kood5,
                tunnus = v_arv.tunnus,
                tp     = v_arv.tp
            WHERE parentid = v_mk.mk_id;

            RAISE NOTICE 'gen_lausend';
            PERFORM docs.gen_lausend_smk(v_mk.id,
                                         v_mk.user_id);
        END LOOP;
    RETURN 1;
END;

$$;

SELECT update_mk_klassif();

DROP FUNCTION IF EXISTS update_mk_klassif();

