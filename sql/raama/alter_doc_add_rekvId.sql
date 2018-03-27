ALTER TABLE docs.doc ADD COLUMN rekvid integer;
COMMENT ON COLUMN docs.doc.rekvid   IS 'ссылка на учреждение';
