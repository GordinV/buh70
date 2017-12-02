-- Table: docs.doc

-- DROP TABLE docs.doc;

CREATE TABLE docs.doc_relations
(
  id serial NOT NULL,
  doc_id integer not null,
  child_id integer not null,
  CONSTRAINT doc_relations_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.doc_relations TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE docs.doc_relations TO dbkasutaja;
GRANT ALL ON TABLE docs.doc_relations TO dbadmin;
GRANT SELECT ON TABLE docs.doc_relations TO dbvaatleja;
COMMENT ON COLUMN docs.doc_relations.doc_id IS 'ИД документа родителя';
COMMENT ON COLUMN docs.doc_relations.child_id IS 'ИД документа потомка';

