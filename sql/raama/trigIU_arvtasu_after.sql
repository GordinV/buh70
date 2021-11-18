DROP TRIGGER IF EXISTS trigiu_arvtasu_after
ON docs.arvtasu CASCADE;

DROP FUNCTION IF EXISTS docs.trigiu_arvtasu_after();

CREATE FUNCTION docs.trigiu_arvtasu_after()
  RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM docs.sp_update_arv_jaak(new.doc_arv_Id);
  PERFORM docs.sp_update_mk_jaak(new.doc_tasu_id);
  
  RETURN NULL;

END;
$$;

CREATE TRIGGER trigiu_arvtasu_after
AFTER INSERT OR UPDATE
  ON docs.arvtasu
FOR EACH ROW
EXECUTE PROCEDURE docs.trigiu_arvtasu_after();
