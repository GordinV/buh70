drop TRIGGER if exists trigIU_arv_after_jaak_update  ON docs.arv CASCADE ;
drop function if exists docs.trigIU_arv_after();

CREATE OR REPLACE FUNCTION docs.trigIU_arv_after_jaak_update()
  RETURNS trigger AS
$BODY$
begin
--	perform docs.sp_update_arv_jaak(new.id);
	return null;
end; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE TRIGGER trigIU_arv_after_jaak_update
  AFTER INSERT OR UPDATE
  ON docs.arv
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigIU_arv_after_jaak_update();
