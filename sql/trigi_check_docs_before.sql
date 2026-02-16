-- Function: docs.trigi_check_docs_before()

-- DROP FUNCTION docs.trigi_check_docs_before();

CREATE OR REPLACE FUNCTION docs.trigi_check_docs_before()
  RETURNS TRIGGER AS
$BODY$
DECLARE
  doc_type_id INTEGER;
BEGIN
  IF (SELECT id FROM docs.doc d WHERE id = new.parentId) IS NULL
  THEN
    -- will find id in library according to code (doktype)

    -- find table name (TG_RELID)

    CASE
      WHEN (SELECT relname::TEXT FROM pg_class WHERE oid = TG_RELID ORDER BY oid LIMIT 1) = 'palk_oper' THEN
        SELECT id INTO doc_type_id FROM libs.library WHERE library = 'DOK' AND kood = 'PALK';
      WHEN (SELECT relname::TEXT FROM pg_class WHERE oid = TG_RELID ORDER BY oid LIMIT 1) = 'palk_taabel1' THEN
        SELECT id INTO doc_type_id FROM libs.library WHERE library = 'DOK' AND kood = 'TAABEL';
      WHEN (SELECT relname::TEXT FROM pg_class WHERE oid = TG_RELID ORDER BY oid LIMIT 1) = 'pv_kaart' THEN
        SELECT id INTO doc_type_id FROM libs.library WHERE library = 'DOK' AND kood = 'PVKAART';
      WHEN (SELECT relname::TEXT FROM pg_class WHERE oid = TG_RELID ORDER BY oid LIMIT 1) = 'pv_oper' THEN
        SELECT id INTO doc_type_id FROM libs.library WHERE library = 'DOK' AND kood = 'PVOPER';
      END CASE;

    IF doc_type_id IS NOT NULL
    THEN
      INSERT INTO docs.doc (doc_type_id)
      VALUES (doc_type_id)
             RETURNING id INTO new.parentId;
    END IF;
  END IF;

  RETURN new;
END;
$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;
ALTER FUNCTION docs.trigi_check_docs_before()
  OWNER TO postgres;
