DROP FUNCTION IF EXISTS docs.kas_kreedit_arve(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.kas_kreedit_arve(l_arv_id INTEGER, l_user_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    l_doc_id       INTEGER;
    v_kreedit_arve RECORD;
    v_alus_arve    RECORD;
BEGIN
    IF NOT exists(SELECT 1 FROM docs.arv WHERE parentid = l_arv_id)
    THEN
        -- нет такого
        RETURN 0;
    END IF;

    -- счет должен закрывать ранее выписанный в этой базе
    SELECT asutusid, rekvid, summa, jaak, l.parentid AS laps_id, a.kpv
    INTO v_kreedit_arve
    FROM docs.arv a
             INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
    WHERE a.parentid = l_arv_id
    LIMIT 1;

    -- ищем аналогичный
    SELECT a.parentid AS id, asutusid, rekvid, summa, jaak, l.parentid AS laps_id
    INTO v_alus_arve
    FROM docs.arv a
             INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
    WHERE a.rekvid = v_kreedit_arve.rekvid
      AND a.kpv <= v_kreedit_arve.kpv
      AND l.parentid = v_kreedit_arve.laps_id
      AND a.asutusid = v_kreedit_arve.asutusid
      AND a.jaak = -1 * v_kreedit_arve.summa
      AND (a.properties ->> 'kreedit_arve_id' IS NULL OR (a.properties ->> 'kreedit_arve_id')::INTEGER > 0)
      AND a.parentid <> l_arv_id
    ORDER BY id DESC
    LIMIT 1;

    RAISE NOTICE 'kreedit_arve_id %, alus_arve_id %', l_arv_id, v_alus_arve.id;
    IF v_alus_arve.id IS NOT NULL
    THEN
        -- есть счет, формируем связи
        UPDATE docs.arv
        SET properties = coalesce(properties, '{}') ::JSONB || jsonb_build_object('kreedit_arve_id', l_arv_id)
        WHERE parentid = v_alus_arve.id;
        -- кредитовый счет вяжем с основанием

        UPDATE docs.arv
        SET properties = coalesce(properties, '{}')::JSONB || jsonb_build_object('alus_arve_id', v_alus_arve.id)
        WHERE parentid = l_arv_id;

        -- оплата основного счета
        l_doc_id = docs.sp_tasu_arv(l_arv_id::INTEGER, v_alus_arve.id::INTEGER, l_user_id::INTEGER);


    END IF;


    RETURN l_doc_id;

END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kas_kreedit_arve(INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.kas_kreedit_arve(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.kas_kreedit_arve(INTEGER, INTEGER) TO arvestaja;

/*
SELECT docs.kas_kreedit_arve(4626981, 5399 )
*/