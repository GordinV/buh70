DROP FUNCTION IF EXISTS docs.sp_updatearvjaak(INTEGER, DATE);
DROP FUNCTION IF EXISTS docs.sp_update_arv_jaak(INTEGER, DATE);
DROP FUNCTION IF EXISTS docs.sp_update_arv_jaak(INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_update_arv_jaak(l_arv_Id INTEGER)
    RETURNS NUMERIC AS
$BODY$
DECLARE
    l_arv_summa       NUMERIC(12, 4);
    l_tasu_summa      NUMERIC(12, 4);
    l_jaak            NUMERIC(12, 4);
    l_status          INTEGER;
    l_kpv             DATE;
    DOC_STATUS_CLOSED INTEGER = 2; -- документ закрыт
    DOC_STATUS_ACTIVE INTEGER = 1; -- документ подлежит редактированию
BEGIN

    SELECT coalesce(arv.summa, 0) :: NUMERIC,
           arv.jaak,
           d.status
    INTO l_arv_summa, l_jaak, l_status
    FROM docs.arv arv
             INNER JOIN docs.doc d ON d.id = arv.parentid
    WHERE d.id = l_arv_Id;

    SELECT coalesce(sum(summa) FILTER ( WHERE arvtasu.kpv <= current_date OR pankkassa = 3), 0),
           coalesce(max(arvtasu.kpv), NULL :: DATE)
    INTO l_tasu_summa, l_kpv
    FROM docs.arvtasu arvtasu
    WHERE arvtasu.doc_arv_Id = l_arv_Id
      AND summa <> 0
      AND arvtasu.status < 3;

    IF l_arv_summa < 0
    THEN
        -- kreeditarve
        IF l_tasu_summa < 0
        THEN
            l_jaak := -1 * ((-1 * l_arv_summa) - (-1 * l_tasu_summa));
        ELSE
            l_jaak := l_arv_summa + l_tasu_summa;
        END IF;
    ELSE
        l_jaak := l_arv_summa - l_tasu_summa;
    END IF;

    UPDATE docs.arv
    SET tasud = l_kpv,
        jaak  = coalesce(l_jaak, 0)
    WHERE parentid = l_arv_Id;

    UPDATE docs.doc
    SET status = CASE
                     WHEN l_jaak = 0
                         THEN DOC_STATUS_CLOSED
                     ELSE DOC_STATUS_ACTIVE END
    WHERE id = l_arv_Id;

    RETURN l_jaak;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_update_arv_jaak(INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.sp_update_arv_jaak(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_update_arv_jaak(INTEGER) TO dbpeakasutaja;
/*

SELECT docs.sp_update_arv_jaak(4495326)
FROM docs.arv

*/