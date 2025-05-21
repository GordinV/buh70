--DROP FUNCTION IF EXISTS docs.sp_update_arv_jaak(INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_update_mk_jaak(l_mk_Id INTEGER)
    RETURNS NUMERIC AS
$BODY$
DECLARE
    l_mk_summa       NUMERIC(12, 4) = (SELECT sum(summa)
                                       FROM docs.mk mk
                                                INNER JOIN docs.mk1 mk1 ON mk1.parentid = mk.id
                                       WHERE mk.parentid = l_mk_Id);
    l_tasu_summa     NUMERIC(12, 4);
    l_jaak           NUMERIC(12, 4);
    l_ulekanne_summa NUMERIC(12, 4) = 0;
    l_ettemaksu_summa NUMERIC(12, 4) = 0;
    v_mk             RECORD;
BEGIN

    SELECT mk.opt, sum(mk1.summa) AS summa
    INTO v_mk
    FROM docs.mk mk
             INNER JOIN docs.mk1 mk1 ON mk.id = mk1.parentid
--     (select  sum(summa) as summa from docs.mk1 mk1 where mk1.parentid = mk.id) mk1
    WHERE mk.parentid = l_mk_Id
    GROUP BY mk.opt;

    -- суммируем сумму оплат по счетам

    -- ulekanne makse
    SELECT sum(at.summa)
    INTO l_ettemaksu_summa
    FROM docs.arvtasu at
    WHERE at.doc_arv_id = l_mk_Id
      and at.pankkassa = 4
      AND at.status <> 3;

    -- ulekanne makse
    SELECT sum(at.summa)
    INTO l_ulekanne_summa
    FROM docs.arvtasu at
    WHERE at.doc_tasu_id = l_mk_Id
      and at.pankkassa= 4
      AND at.status <> 3;


    -- если возвратный платеж (минус), то делаем поправку на знак
    SELECT sum(CASE WHEN a.liik = 0 AND v_mk.opt = 1 THEN -1 ELSE 1 END * at.summa)
    INTO l_tasu_summa
    FROM docs.arvtasu at
             INNER JOIN docs.arv a ON a.parentid = at.doc_arv_id
    WHERE at.doc_tasu_id = l_mk_Id
      AND at.status <> 3
      AND (a.properties::JSONB ->> 'tyyp' IS NULL OR a.properties::JSONB ->> 'tyyp' <> 'ETTEMAKS');

    -- сальдо
    l_jaak = coalesce(l_mk_summa, 0) - coalesce(l_tasu_summa, 0) + (CASE WHEN v_mk.opt = 1 THEN -1 ELSE 1 END * coalesce(l_ulekanne_summa, 0)) - coalesce(l_ettemaksu_summa, 0);

    -- сохраним
    UPDATE docs.mk SET jaak = l_jaak WHERE parentid = l_mk_id;

    RETURN l_jaak;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_update_mk_jaak(INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.sp_update_mk_jaak(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_update_mk_jaak(INTEGER) TO dbpeakasutaja;
/*

SELECT docs.sp_update_mk_jaak(2354874)
from docs.mk
where rekvid = 69
*/


