DROP FUNCTION IF EXISTS docs.tasumine_ebatoenaolised(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.tasumine_ebatoenaolised_(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.tasumine_ebatoenaolised(IN l_mk_id INTEGER,
                                                        IN l_arv_id INTEGER,
                                                        IN user_id INTEGER,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
AS
$BODY$
DECLARE
    v_arv                       RECORD;
    v_mk                        RECORD;
    v_params                    RECORD;
    l_json                      JSONB;
    l_json_details              JSONB          = '[]'::JSONB;
    userName                    TEXT           = (SELECT kasutaja
                                                  FROM ou.userid
                                                  WHERE id = user_id);
    l_summa                     NUMERIC(14, 2);
    l_control_summa             NUMERIC(14, 2) = 0;
    kas_kreedit_arve            BOOL           = FALSE;
    l_journal_id                INTEGER;
    v_aasta                     RECORD;
    v_arvtasu                   RECORD;
    l_tasulised_ebatoenaolised  NUMERIC;
    l_arvestatud_ebatoenaolised NUMERIC;
BEGIN

    -- ищем документ и его сумму
    SELECT d.id                                                            AS id,
           d.rekvid                                                        AS rekv_id,
           m.id                                                            AS mk_id,
           (SELECT sum(summa) FROM docs.mk1 mk1 WHERE mk1.parentid = m.id) AS summa,
           m.maksepaev                                                     AS kpv,
           (m.properties ->> 'ebatoenaolised_tagastamine_id')::INTEGER     AS ebatoenaolised_tagastamine_id
    INTO v_mk
    FROM docs.doc d
             INNER JOIN docs.mk m ON d.id = m.parentid
    WHERE d.id = l_mk_id;

    SELECT *, (properties ->> 'ebatoenaolised_tagastamine_id')::INTEGER AS ebatoenaolised_tagastamine_id
    INTO v_arvtasu
    FROM docs.arvtasu at
    WHERE status < 3
      AND at.doc_arv_id = l_arv_id
      AND at.doc_tasu_id = l_mk_id;


    -- если оплаты нет, вернет 0
    IF v_arvtasu.id IS NULL
    THEN
        result = 0;
        error_message = 'Puudub tasulise dokument';
        RETURN;
    END IF;

    IF v_mk.id IS NULL
    THEN
        -- возможно кредитовый счет
        SELECT d.id          AS id,
               d.rekvid      AS rekv_id,
               m.id          AS mk_id,
               -1 * m.summa  AS summa,
               m.kpv         AS kpv,
               NULL::INTEGER AS ebatoenaolised_tagastamine_id
        INTO v_mk
        FROM docs.doc d
                 INNER JOIN docs.arv m ON d.id = m.parentid
        WHERE d.id = l_mk_id;

        IF v_mk.id IS NOT NULL
        THEN
            -- нашли кредитовый счет
            kas_kreedit_arve = TRUE;
        END IF;

    END IF;


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

    l_summa = CASE WHEN v_arvtasu.summa >= v_arv.summa THEN v_arv.summa ELSE v_arvtasu.summa END;
    -- если списано сумма равная или меньшая платежу , то сумма возврата равна сумме списания, иначе считаем сумму платежа

    --считаем сумма начисленных и оплаченных маловероятных
    l_arvestatud_ebatoenaolised = coalesce((SELECT sum(summa)
                                            FROM cur_journal
                                            WHERE rekvid = v_arv.rekv_id
                                              AND id IN (
                                                SELECT coalesce((properties ->> 'ebatoenaolised_1_id')::INTEGER, 0)
                                                FROM docs.arv
                                                WHERE parentid = l_arv_id
                                                UNION ALL
                                                SELECT coalesce((properties ->> 'ebatoenaolised_2_id')::INTEGER, 0)
                                                FROM docs.arv
                                                WHERE parentid = l_arv_id)), 0);

    --считаем сумма начисленных и оплаченных маловероятных
    l_tasulised_ebatoenaolised = coalesce((SELECT sum(summa)
                                           FROM cur_journal
                                           WHERE rekvid = v_arv.rekv_id
                                             AND id IN (
                                               SELECT (at.properties ->> 'ebatoenaolised_tagastamine_id')::INTEGER AS id
                                               FROM docs.arvtasu at
                                               WHERE doc_arv_id = l_arv_id
                                                 AND at.properties ->> 'ebatoenaolised_tagastamine_id' IS NOT NULL
                                                 AND (at.properties ->> 'ebatoenaolised_tagastamine_id')::INTEGER > 0
                                                 AND at.status < 3)), 0);

    -- если сумма начисленных маловероятныз меньше чем платеж, списываем только то что начисленно
    IF (l_arvestatud_ebatoenaolised + l_tasulised_ebatoenaolised) > 0 AND
       l_summa <= (l_arvestatud_ebatoenaolised + l_tasulised_ebatoenaolised)
    THEN
        -- берем остаток начисленных маловероятных
        l_summa = (l_arvestatud_ebatoenaolised + l_tasulised_ebatoenaolised);
    ELSE
        l_summa = 0;
    END IF;

    IF l_summa <= 0
    THEN
        RAISE NOTICE 'vale summa l_summa %, l_tasulised_ebatoenaolised %, v_arvtasu.summa %', l_summa, l_tasulised_ebatoenaolised, v_arvtasu.summa;
        -- ошибка в сумме
        result = 0;
        error_message = 'Vale summa';
        RETURN;
    END IF;

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
                                  --a1.kood5,
                                  a1.tunnus,
                                  a1.konto,
                                  '608'        AS kood5,
                                  a1.tp        AS lisa_d,
                                  a1.tp        AS lisa_k
                           FROM docs.arv1 a1
                                    INNER JOIN docs.arv a ON a.id = a1.parentid
                           WHERE a.parentid = l_arv_id
                           ORDER BY summa DESC
                           LIMIT 1
                          ) row;

    -- проверяем период
    IF exists(SELECT id
              FROM ou.aasta
              WHERE rekvid = v_arv.rekv_id
                AND kuu = month(v_mk.kpv)
                AND aasta = year(v_mk.kpv)
                AND kinni = 1)
    THEN
        -- То есть тогда, если вдруг по каким-то причинам период закрыт, то алгоритм должен это учитывать и делать проводки в первом месяце открытого периода.
        SELECT *
        INTO v_aasta
        FROM ou.aasta
        WHERE rekvid = v_mk.rekv_id
          AND aasta = year(v_mk.kpv)
          AND kinni = 1
        ORDER BY make_date(aasta, kuu, 1) DESC
        LIMIT 1;

        v_mk.kpv = gomonth(make_date(v_aasta.aasta, v_aasta.kuu, 1)::DATE, 1);
    END IF;

    -- проверяем сумму маловероятных

    IF coalesce(v_arvtasu.ebatoenaolised_tagastamine_id, 0) > 0 AND
       NOT exists(SELECT id FROM cur_journal WHERE id = (v_arvtasu.ebatoenaolised_tagastamine_id)::INTEGER)
    THEN
        -- нет проводки
        v_arvtasu.ebatoenaolised_tagastamine_id = NULL;
    END IF;

    SELECT coalesce(v_arvtasu.ebatoenaolised_tagastamine_id, 0) AS id,
           'JOURNAL'                                            AS doc_type_id,
           v_mk.kpv                                             AS kpv,
           'Ebatõenäoliste nõuete lahendamine'                  AS selg,
           'AUTOMAATLAUSEND'                                    AS muud,
           v_arv.Asutusid,
           'Arve nr.' || v_arv.number::TEXT                     AS dok,
           l_json_details                                       AS "gridData"
    INTO v_params;

    l_json = to_json(row)
             FROM (SELECT coalesce(v_arvtasu.ebatoenaolised_tagastamine_id, 0) AS id,
                          v_params                                             AS data) row;

    l_journal_id = docs.sp_salvesta_journal(l_json :: JSON, user_id, v_arv.rekv_Id);

    IF (l_journal_id IS NOT NULL AND l_journal_id > 0)
    THEN
        l_json = to_json(row)
                 FROM (SELECT l_journal_id AS ebatoenaolised_tagastamine_id) row;

        -- сделаем отметку
        UPDATE docs.arvtasu
        SET properties = coalesce(properties, '{}') :: JSONB || l_json::JSONB
        WHERE doc_tasu_id = l_mk_id
          AND doc_arv_id = l_arv_id
          AND status < 3;


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

/*
SELECT docs.tasumine_ebatoenaolised(5775317, 5136458,5407 );
*/