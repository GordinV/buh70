DROP FUNCTION IF EXISTS docs.check_ettemaks(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.check_ettemaks(l_arv_Id INTEGER, user_id INTEGER)
    RETURNS NUMERIC AS
$BODY$
DECLARE
    v_arv  RECORD;
    v_mk   RECORD;
    l_jaak NUMERIC;
BEGIN
    SELECT CASE
               WHEN a.properties ->> 'viitenr' IS NOT NULL THEN a.properties ->> 'viitenr'
               ELSE lapsed.get_viitenumber(d.rekvid, l.parentid) END::TEXT AS viitenr,
           d.rekvid,
           a.jaak,
           d.id
           INTO v_arv
    FROM docs.doc d
             INNER JOIN docs.arv a ON d.id = a.parentid
             INNER JOIN lapsed.liidestamine l ON l.docid = d.id
    WHERE d.id = l_arv_Id;

    IF v_arv IS NOT NULL AND v_arv.jaak > 0
    THEN
        l_jaak = v_arv.jaak;
        FOR v_mk IN
            SELECT d.id, (SELECT sum(summa) FROM docs.mk1 WHERE mk.parentid = mk.id) AS summa
            FROM docs.doc d
                     INNER JOIN docs.mk mk ON mk.parentid = d.id
            WHERE d.status = 1
              AND mk.viitenr = v_arv.viitenr
              AND (mk.arvid IS NULL OR mk.arvid = 0)
              AND mk.opt = 2
              AND d.rekvid = v_arv.rekvid
            ORDER BY d.id
            LOOP
                -- привязываем счет к оплате
                UPDATE docs.mk SET arvid = l_arv_Id WHERE parentid = v_mk.id;

                -- делаем оплату счета
                PERFORM docs.sp_tasu_arv(v_mk.id, l_arv_Id, user_id);
                l_jaak = l_jaak - v_mk.summa;
                IF l_jaak <= 0
                THEN
                    EXIT;
                END IF;
            END LOOP;
    END IF;

    RETURN l_jaak;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.check_ettemaks(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.check_ettemaks(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.check_ettemaks(INTEGER, INTEGER) TO arvestaja;
/*

select docs.check_ettemaks(1616693, 70)
*/