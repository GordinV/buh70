DROP FUNCTION IF EXISTS docs.kas_kreedit_arve(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS docs.kas_kreedit_arve(INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.kas_kreedit_arve(l_arv_id INTEGER, l_user_id INTEGER, l_alus_id INTEGER DEFAULT NULL)
    RETURNS INTEGER AS
$BODY$

DECLARE
    l_doc_id            INTEGER;
    v_kreedit_arve      RECORD;
    v_alus_arve         RECORD;
    l_kreedit_arve_jaak NUMERIC;
    l_summa numeric;
BEGIN
    IF NOT exists(SELECT 1 FROM docs.arv WHERE parentid = l_arv_id)
    THEN
        RAISE NOTICE 'Kreedit arve puudub %',l_arv_id;
        -- нет такого
        RETURN 0;
    END IF;

    -- счет должен закрывать ранее выписанный в этой базе
    SELECT asutusid, rekvid, summa, jaak, l.parentid AS laps_id, a.kpv
    INTO v_kreedit_arve
    FROM docs.arv a
             LEFT OUTER JOIN lapsed.liidestamine l ON l.docid = a.parentid
    WHERE a.parentid = l_arv_id
    LIMIT 1;

    -- ищем аналогичный
    SELECT a.parentid AS id, asutusid, rekvid, summa, jaak, l.parentid AS laps_id
    INTO v_alus_arve
    FROM docs.arv a
             LEFT OUTER JOIN lapsed.liidestamine l ON l.docid = a.parentid
    WHERE a.rekvid = v_kreedit_arve.rekvid
        AND (a.kpv <= v_kreedit_arve.kpv
            AND (l.parentid = v_kreedit_arve.laps_id)
            AND a.asutusid = v_kreedit_arve.asutusid
            AND a.jaak = -1 * v_kreedit_arve.summa
            AND (a.properties ->> 'kreedit_arve_id' IS NULL OR (a.properties ->> 'kreedit_arve_id')::INTEGER > 0)
            AND a.parentid <> l_arv_id)
       OR (a.parentid IS NOT NULL AND a.parentid = l_alus_id)
    ORDER BY id DESC
    LIMIT 1;

    RAISE NOTICE 'v_alus_arve %, v_kreedit_arve %', v_alus_arve.id, v_kreedit_arve;

    -- считаем сумму остатка кретового счета
    SELECT sum(summa)
    INTO l_kreedit_arve_jaak
    FROM docs.arvtasu at
    WHERE doc_tasu_id = l_arv_id
      AND at.status < 3;

    l_summa = case
        when  (-1 * v_kreedit_arve.summa - coalesce(l_kreedit_arve_jaak,0)) = 0 then 0
        when  (-1 * v_kreedit_arve.summa - coalesce(l_kreedit_arve_jaak,0)) >= v_alus_arve.jaak then v_alus_arve.jaak
        else  (-1 * v_kreedit_arve.summa - coalesce(l_kreedit_arve_jaak,0)) end;

    raise notice 'l_summa %,  v_kreedit_arve.summa %, l_kreedit_arve_jaak %', l_summa,  v_kreedit_arve.summa, l_kreedit_arve_jaak;

    IF v_alus_arve.id IS NOT NULL and l_summa > 0
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
        l_doc_id = docs.sp_tasu_arv(l_arv_id::INTEGER, v_alus_arve.id::INTEGER, l_user_id::INTEGER, l_summa);

    END IF;


    RETURN l_doc_id;

END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.kas_kreedit_arve(INTEGER, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.kas_kreedit_arve(INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
--GRANT EXECUTE ON FUNCTION docs.kas_kreedit_arve(INTEGER, INTEGER, INTEGER) TO arvestaja;

/*
SELECT docs.kas_kreedit_arve(4713833, 5396, 4597388 )
*/