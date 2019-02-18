DROP TRIGGER IF EXISTS trigD_arvtasu_after
  ON docs.arvtasu CASCADE;

DROP FUNCTION IF EXISTS docs.trigD_arvtasu_after();

CREATE FUNCTION docs.trigD_arvtasu_after()
  RETURNS TRIGGER
  LANGUAGE plpgsql
AS $$
BEGIN

  PERFORM docs.sp_update_arv_jaak(old.doc_arv_Id);
  RETURN NULL;

END;
$$;

CREATE TRIGGER trigD_arvtasu_after
  AFTER DELETE 
  ON docs.arvtasu
  FOR EACH ROW
EXECUTE PROCEDURE docs.trigD_arvtasu_after();
