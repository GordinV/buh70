--DROP FUNCTION IF EXISTS palk.trigIUD_palk_oper_after_recalc_palk_jaak();

CREATE OR REPLACE FUNCTION palk.trigIUD_palk_oper_after_recalc_palk_jaak()
  RETURNS TRIGGER AS
$BODY$
DECLARE
  l_kpv      DATE = CASE WHEN tg_op = 'INSERT'
    THEN new.kpv
                    ELSE old.kpv END;
  l_lepingid INTEGER = CASE WHEN tg_op = 'INSERT'
    THEN new.lepingid
                       ELSE old.lepingid END;
BEGIN

  PERFORM palk.sp_update_palk_jaak(l_kpv::date, l_lepingid::integer);

  RETURN NULL;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;


DROP TRIGGER IF EXISTS trigIUD_palk_oper_after_recalc_palk_jaak
ON palk.palk_oper;

CREATE TRIGGER trigIUD_palk_oper_after_recalc_palk_jaak
AFTER INSERT OR UPDATE OR DELETE
  ON palk.palk_oper
FOR EACH ROW
EXECUTE PROCEDURE palk.trigIUD_palk_oper_after_recalc_palk_jaak();
