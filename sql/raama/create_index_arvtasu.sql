DROP INDEX IF EXISTS docs.idx_arvtasu_tasu;
CREATE UNIQUE INDEX idx_arvtasu_tasu ON docs.arvtasu USING btree (doc_tasu_id, doc_arv_id)
    WHERE status <> 3
;