--CREATE EXTENSION intarray;

CREATE INDEX doc_docs_ids_index ON docs.doc USING GIST (docs_ids gist__int_ops);