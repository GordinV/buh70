DROP FUNCTION IF EXISTS docs.sp_updatearvjaak( INTEGER, DATE );
DROP FUNCTION IF EXISTS docs.sp_update_arv_jaak( INTEGER, DATE );
DROP FUNCTION IF EXISTS docs.sp_update_arv_jaak( INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_update_arv_jaak(l_arv_Id INTEGER)
  RETURNS NUMERIC AS
$BODY$
DECLARE l_arv_summa  NUMERIC(12, 4);
        l_tasu_summa NUMERIC(12, 4);
        l_jaak       NUMERIC(12, 4);
        l_kpv        DATE;
BEGIN


  l_arv_summa = (SELECT coalesce(arv.summa, 0) :: NUMERIC
                 FROM docs.arv arv
                   INNER JOIN docs.doc d ON d.id = arv.parentid
                 WHERE d.id = l_arv_Id);

  SELECT
    coalesce(sum(arvtasu.summa), 0),
    coalesce(max(arvtasu.kpv), NULL :: DATE)
  INTO l_tasu_summa, l_kpv
  FROM docs.arvtasu arvtasu
  WHERE arvtasu.doc_arv_Id = l_arv_Id
        AND arvtasu.status < 3;

  RAISE NOTICE 'l_tasu_summa %, l_kpv %', l_tasu_summa, l_kpv;

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

  IF l_tasu_summa = 0
  THEN
    l_kpv := NULL;
  END IF;

  UPDATE docs.arv
  SET
    tasud = l_kpv,
    jaak  = coalesce(l_jaak, 0)
  WHERE parentid = l_arv_Id;


  IF l_jaak = 0
  THEN
    UPDATE docs.doc
    SET status = 2
    WHERE id = l_arv_Id;
  END IF;

  RETURN l_jaak;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_update_arv_jaak(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_update_arv_jaak(INTEGER) TO dbpeakasutaja;
/*

SELECT docs.sp_update_arv_jaak(id, date())
FROM docs.arv

*/