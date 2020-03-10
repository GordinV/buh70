-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_tasu_arv(INTEGER);
DROP FUNCTION IF EXISTS docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_tasu_arv(l_tasu_id INTEGER, l_arv_id INTEGER, l_user_id INTEGER)
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
    v_arv            RECORD;
    v_tulu_arved     RECORD;
    l_tasu_summa     NUMERIC = 0;
    is_refund        BOOLEAN = FALSE;
BEGIN
    SELECT d.id,
           d.docs_ids,
           a.properties ->> 'tyyp'                                AS tyyp,
           CASE WHEN a.liik = 1 THEN 'KULU' ELSE 'TULU' END::TEXT AS arve_tyyp
           INTO v_arv
    FROM docs.doc d
             INNER JOIN docs.arv a ON a.parentid = d.id
    WHERE d.id = l_arv_id;

    SELECT d.*,
           l.kood AS doc_type
           INTO v_tasu
    FROM docs.doc d
             INNER JOIN libs.library l ON l.id = d.doc_type_id
    WHERE d.id = l_tasu_id;

raise notice 'v_tasu l_tasu_id %, %',l_tasu_id, v_tasu.rekvid;

    IF l_tasu_id IS NULL
    THEN
        -- Документ не найден
        RETURN 0;
    END IF;

    l_tasu_type = (CASE
                       WHEN v_tasu.doc_type ILIKE '%MK%'
                           THEN TYPE_DOK_MK
                       WHEN v_tasu.doc_type ILIKE '%ORDER%'
                           THEN TYPE_DOK_KORDER
                       ELSE TYPE_DOK_JOURNAL END);

    l_summa = (
        SELECT sum(summa) AS summa
        FROM (
                 SELECT summa * (CASE
                                     WHEN v_arv.arve_tyyp = 'TULU' AND m.opt = 2 THEN 1
                                     WHEN v_arv.arve_tyyp = 'TULU' AND m.opt = 1 THEN -1
                                     WHEN v_arv.arve_tyyp = 'KULU' AND m.opt = 1 THEN 1
                                     WHEN v_arv.arve_tyyp = 'KULU' AND m.opt = 2 THEN -1 END)::INTEGER AS summa
                 FROM docs.mk m
                          INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
                 WHERE m.parentid = l_tasu_id
                 UNION ALL
                 SELECT summa
                 FROM docs.korder1 k
                 WHERE k.parentid = l_tasu_id
                 UNION ALL
                 SELECT summa
                 FROM docs.journal j
                          INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                 WHERE j.parentid = l_tasu_id
             ) tasud
    );

    l_doc_tasu_id = (
        SELECT a.id
        FROM docs.arvtasu a
        WHERE rekvid = v_tasu.rekvid
          AND doc_arv_id = l_arv_id
          AND doc_tasu_id = l_tasu_id
        ORDER BY a.id DESC
        LIMIT 1
    );

    SELECT coalesce(l_doc_tasu_id, 0)                         AS id,
           v_tasu.rekvid                                      AS rekvid,
           l_arv_id                                           AS doc_arv_id,
           v_tasu.created :: DATE                             AS kpv,
           l_tasu_type                                        AS pankkassa,
           -- 1 - mk, 2- kassa, 3 - lausend
           l_tasu_id                                          AS doc_tasu_id,
           l_summa * (CASE WHEN is_refund THEN -1 ELSE 1 END) AS summa
           INTO v_params;

    SELECT row_to_json(row) INTO json_object
    FROM (SELECT coalesce(l_doc_tasu_id, 0) AS id,
                 v_params                   AS data) row;

    raise notice 'salvestan arvtasu l_user_id %, v_tasu.rekvid %', l_user_id, v_tasu.rekvid;

    SELECT docs.sp_salvesta_arvtasu(json_object :: JSON, l_user_id, v_tasu.rekvid) INTO l_doc_id;

    -- если счет имеет тип - предоплата

    IF v_arv.tyyp = 'ETTEMAKS'
    THEN
        -- выбираем связанные счета
        FOR v_tulu_arved IN
            SELECT d.id, a.jaak
            FROM docs.doc d
                     INNER JOIN docs.arv a ON d.id = a.parentid
            WHERE d.id IN (
                SELECT unnest(v_arv.docs_ids)
            )
              AND a.jaak > 0
            ORDER BY kpv
            LOOP
                -- делаем пропорциональную оплату
                -- изем уже имеющуюся оплату
                l_doc_tasu_id = (
                    SELECT id
                    FROM docs.arvtasu
                    WHERE rekvid = v_tasu.rekvid
                      AND doc_arv_id = v_tulu_arved.id
                      AND doc_tasu_id = l_tasu_id
                    ORDER BY id DESC
                    LIMIT 1
                );

                -- готовим параметры
                l_tasu_summa = CASE WHEN v_tulu_arved.jaak > l_summa THEN l_summa ELSE v_tulu_arved.jaak END;
                SELECT coalesce(l_doc_tasu_id, 0) AS id,
                       v_tasu.rekvid              AS rekvid,
                       v_tulu_arved.id            AS doc_arv_id,
                       v_tasu.created :: DATE     AS kpv,
                       l_tasu_type                AS pankkassa,
                       -- 1 - mk, 2- kassa, 3 - lausend
                       l_tasu_id                  AS doc_tasu_id,
                       l_tasu_summa               AS summa
                       INTO v_params;

                SELECT row_to_json(row) INTO json_object
                FROM (SELECT 0        AS id,
                             v_params AS data) row;
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

    RETURN l_doc_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_tasu_arv(INTEGER, INTEGER, INTEGER) TO arvestaja;


SELECT *
FROM docs.sp_tasu_arv(1616679::INTEGER, 1616591::INTEGER, 70::INTEGER);
