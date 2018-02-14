
drop TRIGGER if exists trigiu_arvtasu_after ON docs.arvtasu CASCADE ;

drop function if exists docs.trigiu_arvtasu_after();

CREATE FUNCTION docs.trigiu_arvtasu_after()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

  PERFORM docs.sp_update_arv_jaak(new.doc_arv_Id, new.Kpv);
  RETURN NULL;

END;
$$;

CREATE TRIGGER trigiu_arvtasu_after
AFTER INSERT OR UPDATE
  ON docs.arvtasu
FOR EACH ROW
EXECUTE PROCEDURE docs.trigiu_arvtasu_after();
