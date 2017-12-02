
DROP FUNCTION if exists docs.sp_update_arv_jaak(integer, date);
DROP FUNCTION if exists docs.sp_updatearvjaak(integer, date);

CREATE OR REPLACE FUNCTION docs.sp_update_arv_jaak( tnArvId integer,tdKpv date)
  RETURNS numeric AS
$BODY$
declare lnArvSumma numeric (12,4);
	lnTasuSumma numeric (12,4);
	lnJaak numeric (12,4);
	ldKpv date;
	v_arvtasu record;
	lnJournalId int;

	lnKuurs numeric(12,4);
begin


SELECT coalesce(arv.summa * coalesce(dokvaluuta1.kuurs,1),0)::numeric, coalesce(dokvaluuta1.kuurs,1)  into lnArvSumma , lnKuurs
	FROM docs.arv arv
	inner join docs.doc d on d.id = arv.parentid
	left outer join docs.dokvaluuta1 dokvaluuta1 on (dokvaluuta1.dokid = arv.id and dokvaluuta1.dokliik = 3) 
	WHERE arv.id = tnArvId ;

SELECT coalesce(sum(arvtasu.summa * ifnull(dokvaluuta1.kuurs,1)),0), coalesce(max(arvtasu.kpv),tdKpv) into lnTasuSumma, ldKpv 
	FROM docs.arvtasu arvtasu 
	left outer join docs.dokvaluuta1 dokvaluuta1 on (arvtasu.id = dokvaluuta1.dokid and dokvaluuta1.dokliik = 21) 
	WHERE arvtasu.arvId = tnArvId;
		
	
	if lnArvSumma < 0 then
		-- kreeditarve
		if lnTasuSumma < 0 then
			lnJaak := -1 * ((-1 * lnArvSumma) - (-1 * lnTasuSumma));			
		else
			lnJaak := lnArvSumma + lnTasuSumma;
		end if;
	else
		lnJaak := lnArvSumma - lnTasuSumma;
	end if;
	if lnTasuSumma = 0 then
		ldKpv := null;
	end if;

	lnJaak = lnJaak / lnKuurs; 	

	UPDATE docs.arv SET 
		tasud = ldkpv,
		jaak = coalesce(lnJaak,0)  
		WHERE id = tnArvId;		

	return lnJaak;
end; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_update_arv_jaak(integer, date) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_update_arv_jaak(integer, date) TO dbpeakasutaja;


select docs.sp_update_arv_jaak(id, date()) from docs.arv