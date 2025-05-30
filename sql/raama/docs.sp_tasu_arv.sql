-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_tasu_arv(INTEGER);
DROP FUNCTION IF EXISTS docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER, NUMERIC);

CREATE OR REPLACE FUNCTION docs.sp_tasu_arv(l_tasu_id INTEGER, l_arv_id INTEGER, l_user_id INTEGER,
                                            tasu_summa NUMERIC DEFAULT 0)
    RETURNS INTEGER AS
$BODY$

DECLARE
    l_doc_id         INTEGER;
    v_tasu           RECORD;
    v_params         RECORD;
    json_object      JSONB;
    l_tasu_type      INTEGER = 3; -- muud (lausend)
    l_summa          NUMERIC = 0;
    l_doc_tasu_id    INTEGER;
    TYPE_DOK_MK      INTEGER = 1;
    TYPE_DOK_KORDER  INTEGER = 2;
    TYPE_DOK_JOURNAL INTEGER = 3;
    TYPE_DOK_ARVE    INTEGER = 4;
    v_arv            RECORD;
    v_tulu_arved     RECORD;
    l_tasu_summa     NUMERIC = 0;
    is_refund        BOOLEAN = FALSE;
    v_arvtasu        RECORD;
BEGIN
    IF exists
    (
        SELECT 1
        FROM docs.arv
        WHERE journalid = l_tasu_id
    )
    THEN
        -- это не оплата, это проводка счета
        RETURN 0;
    END IF;


    SELECT
        d.id,
        d.docs_ids,
        a.properties ->> 'tyyp'                                AS tyyp,
        CASE WHEN a.liik = 1 THEN 'KULU' ELSE 'TULU' END::TEXT AS arve_tyyp,
        a.properties ->> 'ebatoenaolised_1_id'                 AS ebatoenaolised_1_id,
        a.properties ->> 'ebatoenaolised_2_id'                 AS ebatoenaolised_2_id,
        a.jaak
    INTO v_arv
    FROM
        docs.doc                d
            INNER JOIN docs.arv a ON a.parentid = d.id
    WHERE
        d.id = l_arv_id;

    SELECT
        d.*,
        CASE
            WHEN m.maksepaev IS NOT NULL THEN m.maksepaev
            WHEN k.kpv IS NOT NULL THEN k.kpv
            WHEN j.kpv IS NOT NULL THEN j.kpv
            WHEN a.kpv IS NOT NULL THEN a.kpv
            ELSE d.created::DATE
            END     AS maksepaev,
        l.kood      AS doc_type,
        m.opt,
        m.jaak,
        ld.parentid AS laps_id
    INTO v_tasu
    FROM
        docs.doc                                d
            INNER JOIN      libs.library        l ON l.id = d.doc_type_id
            LEFT OUTER JOIN lapsed.liidestamine ld ON ld.docid = d.id -- для проверки о возврате платежа
            LEFT OUTER JOIN docs.mk             m ON m.parentid = d.id
            LEFT OUTER JOIN docs.korder1        k
                            ON k.parentid = D.id
            LEFT OUTER JOIN docs.journal        j
                            ON j.parentid = d.id
            LEFT OUTER JOIN docs.arv            a ON a.parentid = d.id
    WHERE
        d.id = l_tasu_id;


    IF l_tasu_id IS NULL
    THEN
        -- Документ не найден
        RAISE NOTICE 'Документ не найден';
        RETURN 0;
    END IF;

    -- проверим не возврат ли это

    IF coalesce(v_tasu.opt, 0) = 1 AND v_tasu.laps_id IS NOT NULL
    THEN
        -- похоже на возврат
        is_refund = TRUE;
    END IF;

    l_tasu_type = (CASE
                       WHEN v_tasu.doc_type ILIKE '%MK%'
                           THEN TYPE_DOK_MK
                       WHEN v_tasu.doc_type ILIKE '%ORDER%'
                           THEN TYPE_DOK_KORDER
                       WHEN v_tasu.doc_type ILIKE '%ARV%'
                           THEN TYPE_DOK_ARVE
                       ELSE TYPE_DOK_JOURNAL END);

    -- рассчитываем сумму оплаты, если платеж не задан

    l_summa = CASE
                  WHEN empty(tasu_summa) THEN (
                                                  SELECT
                                                      sum(summa) AS summa
                                                  FROM
                                                      (
                                                          SELECT
                                                              summa * (CASE
                                                                           WHEN v_arv.arve_tyyp = 'TULU' AND m.opt = 2
                                                                               THEN 1
                                                                           WHEN v_arv.arve_tyyp = 'TULU' AND m.opt = 1
                                                                               THEN -1
                                                                           WHEN v_arv.arve_tyyp = 'KULU' AND m.opt = 1
                                                                               THEN 1
                                                                           WHEN v_arv.arve_tyyp = 'KULU' AND m.opt = 2
                                                                               THEN -1 END)::INTEGER AS summa
                                                          FROM
                                                              docs.mk                 m
                                                                  INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
                                                          WHERE
                                                              m.parentid = l_tasu_id
                                                          UNION ALL
                                                          SELECT
                                                              summa
                                                          FROM
                                                              docs.korder1 k
                                                          WHERE
                                                              k.parentid = l_tasu_id
                                                          UNION ALL
                                                          SELECT
                                                              -1 * summa
                                                          FROM
                                                              docs.arv a
                                                          WHERE
                                                              a.parentid = l_tasu_id
                                                          UNION ALL
                                                          SELECT
                                                              j1.summa
                                                          FROM
                                                              docs.journal                 j
                                                                  INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                                                          WHERE
                                                                j.parentid = l_tasu_id
                                                            AND j1.deebet NOT IN ('20363005', '20363004')
                                                      ) tasud
                  )
                  ELSE tasu_summa END;

    l_doc_tasu_id = (
                        SELECT
                            a.id
                        FROM
                            docs.arvtasu a
                        WHERE
                              doc_arv_id = l_arv_id
                          AND doc_tasu_id = l_tasu_id
                          AND a.status <> 3
                        ORDER BY a.id DESC
                        LIMIT 1
                    );

    SELECT
        coalesce(l_doc_tasu_id, 0)                         AS id,
        v_tasu.rekvid                                      AS rekvid,
        l_arv_id                                           AS doc_arv_id,
        v_tasu.maksepaev :: DATE                           AS kpv,
        l_tasu_type                                        AS pankkassa,
        -- 1 - mk, 2- kassa, 3 - lausend
        l_tasu_id                                          AS doc_tasu_id,
        l_summa * (CASE WHEN is_refund THEN -1 ELSE 1 END) AS summa
    INTO v_params;

    SELECT
        row_to_json(row)
    INTO json_object
    FROM
        (
            SELECT
                coalesce(l_doc_tasu_id, 0) AS id,
                v_params                   AS data
        ) row;

    SELECT docs.sp_salvesta_arvtasu(json_object :: JSON, l_user_id, v_tasu.rekvid) INTO l_doc_id;

    -- если счет имеет тип - предоплата

    IF v_arv.tyyp = 'ETTEMAKS'
    THEN
        -- выбираем связанные счета
        FOR v_tulu_arved IN
            SELECT
                d.id,
                a.jaak
            FROM
                docs.doc                d
                    INNER JOIN docs.arv a ON d.id = a.parentid
            WHERE
                  d.id IN (
                              SELECT unnest(v_arv.docs_ids)
                          )
              AND d.id <> l_arv_id
              AND a.jaak > 0
            ORDER BY kpv
            LOOP
            -- делаем пропорциональную оплату
            -- изем уже имеющуюся оплату
                l_doc_tasu_id = (
                                    SELECT
                                        id
                                    FROM
                                        docs.arvtasu
                                    WHERE
                                          doc_arv_id = v_tulu_arved.id
                                      AND doc_tasu_id = l_tasu_id
                                      AND status <> 3
                                    ORDER BY id DESC
                                    LIMIT 1
                                );

                -- готовим параметры
                l_tasu_summa = CASE WHEN v_tulu_arved.jaak > l_summa THEN l_summa ELSE v_tulu_arved.jaak END;
                SELECT
                    coalesce(l_doc_tasu_id, 0) AS id,
                    v_tasu.rekvid              AS rekvid,
                    v_tulu_arved.id            AS doc_arv_id,
                    v_tasu.maksepaev :: DATE   AS kpv,
                    l_tasu_type                AS pankkassa,
                    -- 1 - mk, 2- kassa, 3 - lausend
                    l_tasu_id                  AS doc_tasu_id,
                    l_tasu_summa               AS summa
                INTO v_params;

                SELECT
                    row_to_json(row)
                INTO json_object
                FROM
                    (
                        SELECT
                            coalesce(l_doc_tasu_id, 0) AS id,
                            v_params                   AS data
                    ) row;
                -- созранение
                l_doc_id = docs.sp_salvesta_arvtasu(json_object :: JSON, l_user_id, v_tasu.rekvid);

                l_summa = l_summa - l_tasu_summa;
                IF l_summa <= 0
                THEN
                    -- вся оплата списана, вызодим их оплат
                    EXIT;
                END IF;

            END LOOP;

    END IF;
    -- сальдо платежа
    -- оплата маловероятных
    --только при положительной сумме оплат

/*  
    -- меняем алгоритм
    IF ((v_arv.ebatoenaolised_1_id IS NOT NULL OR v_arv.ebatoenaolised_2_id IS NOT NULL) AND
        coalesce(v_arv.tyyp, '') <> 'ETTEMAKS' AND v_params.summa > 0)
    THEN
        PERFORM docs.tasumine_ebatoenaolised(l_tasu_id, l_arv_id, l_user_id);
    END IF;
*/
    perform docs.sp_update_arv_jaak(l_arv_id:: INTEGER);

    RETURN l_doc_id;

END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER, NUMERIC) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER, NUMERIC) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER, NUMERIC) TO arvestaja;

/*
SELECT *
FROM docs.sp_tasu_arv(4626983::INTEGER, 4576324::INTEGER, 5399::INTEGER);
*/