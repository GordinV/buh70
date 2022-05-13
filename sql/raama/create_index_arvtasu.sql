DROP INDEX IF EXISTS docs.idx_arvtasu_tasu;
CREATE UNIQUE INDEX idx_arvtasu_tasu ON docs.arvtasu USING btree (doc_tasu_id, doc_arv_id)
    WHERE status <> 3
;

DROP INDEX IF EXISTS docs.arvtasu_doc_arv_id;

CREATE INDEX IF NOT EXISTS arvtasu_doc_arv_id
    ON docs.arvtasu USING btree
        (doc_arv_id ASC NULLS LAST)
    TABLESPACE pg_default
    where status <> 3;
