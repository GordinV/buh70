ALTER TABLE docs.doc
  ADD CONSTRAINT doc_status_fk FOREIGN KEY (status) REFERENCES libs.library (id) MATCH FULL
   ON UPDATE CASCADE ON DELETE RESTRICT;

CREATE INDEX fki_doc_status_fk
  ON docs.doc(status);
