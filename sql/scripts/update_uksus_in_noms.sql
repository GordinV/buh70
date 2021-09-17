DROP FUNCTION IF EXISTS update_uksus_in_noms(INTEGER);

CREATE FUNCTION update_uksus_in_noms(l_rekv_id INTEGER)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_nom    RECORD;
    v_rekv   RECORD;
    l_tunnus VARCHAR(20);
    v_mk     RECORD;
    v_arv    RECORD;
BEGIN
    FOR v_rekv IN
        SELECT id, nimetus
        FROM ou.rekv
        WHERE parentid = 119
          AND id NOT IN (82)
          AND id = l_rekv_id

    LOOP
        RAISE NOTICE 'rek %', v_rekv.id;
        -- ищем признак
        SELECT kood
        INTO l_tunnus
        FROM libs.library l
        WHERE l.library = 'TUNNUS'
          AND rekvid = v_rekv.id
          AND ltrim(rtrim(v_rekv.nimetus)) ILIKE ltrim(rtrim(kood)) || '%'
            LIMIT 1;

        RAISE NOTICE 'Kood found %, v_rekv.nimetus %', l_tunnus, v_rekv.nimetus;

        FOR v_nom IN
            SELECT id
            FROM libs.nomenklatuur
            WHERE rekvid = v_rekv.id
              AND dok IN ('ARV', 'SMK', 'VMK', 'MK')
        --                 AND dok IN ('SMK', 'VMK', 'MK')
            LOOP
                UPDATE libs.nomenklatuur
                SET properties = properties:: JSONB || ('{"tunnus":"' || l_tunnus || '"}')::JSONB
                WHERE id = v_nom.id;

                -- правим документы
                FOR v_mk IN
                    SELECT mk.parentid                       AS doc_id,
                           mk.id,
                           (SELECT id
                            FROM ou.userid u
                            WHERE u.rekvid = mk.rekvid
                              AND kasutaja = 'vlad' LIMIT 1) AS user_id
                    FROM docs.mk mk
                             INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
                    WHERE mk1.nomid = v_nom.id
                      AND mk.rekvid = v_rekv.id
                      AND mk.kpv >= '2020-12-31'
                    LOOP
                        UPDATE docs.mk1
                        SET tunnus = l_tunnus
                        WHERE nomid = v_nom.id
                          AND parentid = v_mk.id;

                        PERFORM docs.gen_lausend_smk(v_mk.doc_id,
                                                     v_mk.user_id);

                    END LOOP;
                FOR v_arv IN
                    SELECT a.parentid AS doc_id, a.userid AS user_id, a1.id AS id
                    FROM docs.arv a
                             INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                    WHERE a1.nomid = v_nom.id
                      AND a.rekvid = v_rekv.id
                      AND a.liik = 0
                      AND (kpv) >= '2020-12-31'
                      AND a1.konto <> '103701'

                    LOOP
                        UPDATE docs.arv1 SET tunnus = l_tunnus WHERE id = v_arv.id;
                        PERFORM docs.gen_lausend_arv(v_arv.doc_id,
                                                     v_arv.user_id);

                    END LOOP;

            END LOOP;

    END LOOP;

    RETURN 1;
END;

$$;

--DROP FUNCTION IF EXISTS update_uksus_in_noms(INTEGER);

