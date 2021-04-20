DROP FUNCTION IF EXISTS docs.tasumine_ebatoenaolised(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.tasumine_ebatoenaolised(IN l_mk_id INTEGER,
                                                        IN l_arv_id INTEGER,
                                                        IN user_id INTEGER,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
AS
$BODY$
DECLARE
    v_arv          RECORD;
    v_mk           RECORD;
    v_params       RECORD;
    l_json         JSONB;
    l_json_details JSONB = '[]'::JSONB;
    userName       TEXT  = (SELECT kasutaja
                            FROM ou.userid
                            WHERE id = user_id);
    l_summa        NUMERIC(14, 2);
    l_journal_id   INTEGER;
BEGIN

    -- ищем документ и его сумму
    SELECT d.id                                                        AS id,
           m.id                                                        AS mk_id,
           (SELECT sum(summa) FROM docs.mk1 mk1 WHERE mk1.parentid = m.id)   AS summa,
           m.maksepaev                                                 AS kpv,
           (m.properties ->> 'ebatoenaolised_tagastamine_id')::INTEGER AS ebatoenaolised_tagastamine_id
           INTO v_mk
    FROM docs.doc d
             INNER JOIN docs.mk m ON d.id = m.parentid
    WHERE d.id = l_mk_id;

    -- ищем счет и сумму списаний по нему
--

    SELECT a.id                                                                                             AS arv_id,
           (a.properties ->> 'ebatoenaolised_2_id')::INTEGER                                                AS ebatoenaolised_2_id,
           a.asutusid                                                                                       AS asutusid,
           a.number,
           a.rekvid                                                                                         AS rekv_id,
           (a.properties ->> 'ebatoenaolised_1_id')::INTEGER                                                AS ebatoenaolised_1_id,
           (SELECT sum(summa)
            FROM docs.doc d
                     INNER JOIN docs.journal j ON j.parentid = d.id
                     INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
            WHERE d.id IN (
                           coalesce((a.properties ->> 'ebatoenaolised_2_id')::INTEGER, 0),
                           coalesce((a.properties ->> 'ebatoenaolised_1_id')::INTEGER, 0)))::NUMERIC(14, 2) AS summa
           INTO v_arv
    FROM docs.doc d
             INNER JOIN docs.arv a ON d.id = a.parentid
    WHERE d.id = l_arv_id;

    l_summa = CASE WHEN v_mk.summa >= v_arv.summa THEN v_arv.summa ELSE v_mk.summa END;
    -- если списано сумма равная или меньшая платежу , то сумма возврата равна сумме списания, иначе считаем сумму платежа

    -- создаем проводку (или ищем если уже создана)

    l_json_details = '[]'::JSONB;
    l_json_details = l_json_details || to_jsonb(row)
                     FROM (SELECT 0            AS id,
                                  -1 * l_summa AS summa, -- 50% от требования
                                  '605030'     AS deebet,
                                  '103009'     AS kreedit,
                                  a1.kood1,
                                  a1.kood2,
                                  a1.kood3,
                                  a1.tunnus,
                                  a1.konto,
                                  '608',
                                  a1.tp        AS lisa_d,
                                  a1.tp        AS lisa_k
                           FROM docs.arv1 a1
                                    INNER JOIN docs.arv a ON a.id = a1.parentid
                           WHERE a.parentid = l_arv_id
                           ORDER BY summa DESC
                           LIMIT 1
                          ) row;

    SELECT coalesce(v_mk.ebatoenaolised_tagastamine_id, 0) AS id,
           'JOURNAL'                                       AS doc_type_id,
           v_mk.kpv                                        AS kpv,
           'Ebatõenäoliste nõuete lahendamine'             AS selg,
           v_arv.Asutusid,
           'Arve nr' || v_arv.number::TEXT                 AS dok,
           l_json_details                                  AS "gridData"
           INTO v_params;

    l_json = to_json(row)
             FROM (SELECT coalesce(v_mk.ebatoenaolised_tagastamine_id, 0) AS id,
                          v_params                                        AS data) row;

    l_journal_id = docs.sp_salvesta_journal(l_json :: JSON, user_id, v_arv.rekv_Id);

    IF (l_journal_id IS NOT NULL AND l_journal_id > 0)
    THEN
        l_json = to_json(row)
                 FROM (SELECT l_journal_id AS ebatoenaolised_tagastamine_id) row;

        -- сделаем отметку
        UPDATE docs.mk
        SET properties = coalesce(properties, '{}') :: JSONB || l_json::JSONB
        WHERE parentid = l_mk_id;

        -- история
        l_json = to_json(row)
                 FROM (SELECT now()                               AS updated,
                              userName                            AS user,
                              'ebatoenaoliste nõuete lahendamine' AS task,
                              l_journal_id                        AS result
                      ) row;

        -- связываем документы
        UPDATE docs.doc
        SET docs_ids   = array_append(docs_ids, l_journal_id),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || l_json::JSONB
        WHERE id = l_mk_id;

        UPDATE docs.doc
        SET docs_ids   = array_append(docs_ids, l_journal_id),
            lastupdate = now(),
            history    = coalesce(history, '[]') :: JSONB || l_json::JSONB
        WHERE id = l_arv_id;

    END IF;

    error_message = 'Koostatud ebatoenaoliste nõuete lahendamine, arve nr. ' || ltrim(rtrim(v_arv.number));
    result = l_journal_id;
    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            result = 0;
            error_code = 9;
            error_message = 'tekkis viga: ' || coalesce(SQLERRM, '');
            RETURN;

END;

$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

ALTER FUNCTION docs.tasumine_ebatoenaolised( INTEGER, INTEGER, INTEGER )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.tasumine_ebatoenaolised(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.tasumine_ebatoenaolised(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;

--SELECT docs.kustuta_ebatoenaolised(2288915, 28 );
