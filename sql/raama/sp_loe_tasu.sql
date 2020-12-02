-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_loe_tasu(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_loe_tasu(IN l_tasu_id INTEGER, IN l_user_id INTEGER,
                                            OUT error_code INTEGER,
                                            OUT result INTEGER,
                                            OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_tasu_jaak NUMERIC;
    v_arv       RECORD;
    v_tasu      RECORD;
BEGIN
    -- load tasu data
    SELECT mk.id,
           d.rekvid,
           (regexp_replace(viitenr, '[^0-9]', ''))::TEXT                    AS viitenr,
           (SELECT sum(summa) FROM docs.mk1 mk1 WHERE mk1.parentid = mk.id) AS summa
           INTO v_tasu
    FROM docs.doc D
             INNER JOIN docs.mk mk ON mk.parentid = D.id
             INNER JOIN lapsed.liidestamine l ON l.docid = d.id
    WHERE d.id = l_tasu_id;

    IF v_tasu IS NULL
    THEN
        -- нет связи, вызодим
        result = 0;
        error_message = 'laps ei leidnud';
        RETURN;
    END IF;

    l_tasu_jaak = v_tasu.summa;

    -- ищем неоплаченные счета (по аналогии с выпиской
    SELECT a.id,
           a.jaak,
           a.rekvid,
           a.asutusid,
           a.asutus AS maksja
           INTO v_arv
    FROM lapsed.cur_laste_arved a
             INNER JOIN docs.arv arv ON a.id = arv.parentid
    WHERE a.rekvid = v_tasu.rekvid
      AND (regexp_replace(a.viitenr, '[^0-9]', ''))::TEXT = (regexp_replace(v_tasu.viitenr, '[^0-9]', ''))::TEXT
      AND a.jaak > 0
      AND a.jaak >= v_tasu.summa
      AND (arv.properties ->> 'ettemaksu_period' IS NULL OR
        arv.properties ->> 'tyyp' = 'ETTEMAKS') -- только обычные счета или предоплаты
    ORDER BY a.kpv, a.id
    LIMIT 1;

    IF v_arv IS NOT NULL
    THEN
        -- вызывает оплату
        result = docs.sp_tasu_arv(l_tasu_id, v_arv.id, l_user_id);
        RETURN;
    END IF;

    -- нет счетов с суммой равной или большей платежу
    SELECT a.id,
           a.jaak,
           a.rekvid,
           a.asutusid,
           a.asutus AS maksja
           INTO v_arv
    FROM lapsed.cur_laste_arved a
             INNER JOIN docs.arv arv ON a.id = arv.parentid
    WHERE a.rekvid = v_tasu.rekvid
      AND (regexp_replace(a.viitenr, '[^0-9]', ''))::TEXT = (regexp_replace(v_tasu.viitenr, '[^0-9]', ''))::TEXT
      AND a.jaak > 0
      AND (arv.properties ->> 'ettemaksu_period' IS NULL OR
           arv.properties ->> 'tyyp' = 'ETTEMAKS') -- только обычные счета или предоплаты
    ORDER BY a.jaak DESC
    LIMIT 1;

    IF v_arv IS NOT NULL
    THEN
        -- вызывает оплату
        result =  docs.sp_tasu_arv(l_tasu_id, v_arv.id, l_user_id);
        RETURN;
    END IF;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_loe_tasu(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_tasu(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_tasu(INTEGER, INTEGER) TO arvestaja;

COMMENT ON FUNCTION docs.sp_loe_tasu(INTEGER, INTEGER) IS 'производит поиск неоплаченных счетов и вызывает процедуру их оплаты';

/*
SELECT *
FROM  docs.sp_loe_tasu(1616852::INTEGER, 70::INTEGER);

select * from ou.userid where id = 70
*/