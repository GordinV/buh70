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
    RAISE NOTICE ' called from %', TG_RELID;

    CASE
      WHEN (SELECT relname::TEXT FROM pg_class WHERE oid = TG_RELID ORDER BY oid LIMIT 1) = 'palk_oper' THEN
        SELECT id INTO doc_type_id FROM libs.library WHERE library = 'DOK' AND kood = 'PALK';
        RAISE NOTICE ' palk_oper: %',doc_type_id;
      WHEN (SELECT relname::TEXT FROM pg_class WHERE oid = TG_RELID ORDER BY oid LIMIT 1) = 'palk_taabel1' THEN
        SELECT id INTO doc_type_id FROM libs.library WHERE library = 'DOK' AND kood = 'TAABEL';
        RAISE NOTICE ' palk_taabel: %',doc_type_id;
      WHEN (SELECT relname::TEXT FROM pg_class WHERE oid = TG_RELID ORDER BY oid LIMIT 1) = 'pv_kaart' THEN
        SELECT id INTO doc_type_id FROM libs.library WHERE library = 'DOK' AND kood = 'PVKAART';
        RAISE NOTICE ' pv_kaart: %',doc_type_id;
      WHEN (SELECT relname::TEXT FROM pg_class WHERE oid = TG_RELID ORDER BY oid LIMIT 1) = 'pv_oper' THEN
        SELECT id INTO doc_type_id FROM libs.library WHERE library = 'DOK' AND kood = 'PVOPER';
        RAISE NOTICE ' pv_oper: %',doc_type_id;
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
