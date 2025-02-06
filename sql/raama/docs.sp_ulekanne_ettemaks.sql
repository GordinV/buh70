-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_ulekanne_ettemaks(INTEGER, INTEGER, INTEGER, NUMERIC);

CREATE OR REPLACE FUNCTION docs.sp_ulekanne_ettemaks(l_tasu_id INTEGER, l_ettemaks_id INTEGER, l_user_id INTEGER,
                                                     tasu_summa NUMERIC DEFAULT 0)
    RETURNS INTEGER AS
$BODY$

DECLARE
    l_doc_id      INTEGER;
    v_tasu        RECORD;
    v_params      RECORD;
    json_object   JSONB;
    l_tasu_type   INTEGER = 4; -- smk (ulekanne)
    l_summa       NUMERIC = tasu_summa;
    l_doc_tasu_id INTEGER;
    v_mk          RECORD;
    is_refund     BOOLEAN = TRUE; -- в данном случае это возврат
    v_arvtasu     RECORD;
    l_tasu_jaak   INTEGER;
BEGIN

    -- расчет сальдо платежа
    l_tasu_jaak = docs.sp_update_mk_jaak(l_ettemaks_id);
    l_tasu_jaak = docs.sp_update_mk_jaak(l_tasu_id);

    raise notice 'start docs.sp_ulekanne_ettemaks l_tasu_jaak %',l_tasu_jaak;

    SELECT
        d.id,
        d.docs_ids,
        mk.jaak,
        mk.opt
    INTO v_mk
    FROM
        docs.doc               d
            INNER JOIN docs.mk mk ON mk.parentid = d.id
    WHERE
        d.id = l_ettemaks_id;

    SELECT
        d.*,
        m.maksepaev AS maksepaev,
        m.opt,
        m.jaak,
        ld.parentid AS laps_id
    INTO v_tasu
    FROM
        docs.doc                                d
            LEFT OUTER JOIN lapsed.liidestamine ld ON ld.docid = d.id -- для проверки о возврате платежа
            INNER JOIN      docs.mk             m ON m.parentid = d.id
    WHERE
        d.id = l_tasu_id;

    IF l_tasu_id IS NULL or v_mk.jaak = 0
    THEN
        -- Документ не найден
        RAISE NOTICE 'Документ не найденб или ошибка';
        RETURN 0;
    END IF;

    l_doc_tasu_id = (
                        SELECT
                            a.id
                        FROM
                            docs.arvtasu a
                        WHERE
                              doc_arv_id = l_ettemaks_id
                          AND doc_tasu_id = l_tasu_id
                          AND a.status <> 3
                        ORDER BY a.id DESC
                        LIMIT 1
                    );

    SELECT
        coalesce(l_doc_tasu_id, 0)                         AS id,
        v_tasu.rekvid                                      AS rekvid,
        l_ettemaks_id                                      AS doc_arv_id,
        v_tasu.maksepaev :: DATE                           AS kpv,
        l_tasu_type                                        AS pankkassa,
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

    raise notice 'sp_ulekanne_ettemaks saved l_doc_id %',l_doc_id;

    RETURN l_doc_id;

END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_ulekanne_ettemaks(INTEGER, INTEGER, INTEGER, NUMERIC) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_ulekanne_ettemaks(INTEGER, INTEGER, INTEGER, NUMERIC) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_ulekanne_ettemaks(INTEGER, INTEGER, INTEGER, NUMERIC) TO arvestaja;

/*
SELECT *
FROM docs.sp_ulekanne_ettemaks(4626983::INTEGER, 4576324::INTEGER, 5399::INTEGER);
*/