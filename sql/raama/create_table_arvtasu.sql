CREATE TABLE docs.arvtasu (
    id          SERIAL                                     NOT NULL
        CONSTRAINT arvtasu_pkey
            PRIMARY KEY,
    rekvid      INTEGER                                    NOT NULL,
    doc_arv_id  INTEGER                                    NOT NULL,
    doc_tasu_id INTEGER,
    kpv         DATE           DEFAULT ('now'::TEXT)::DATE NOT NULL,
    summa       NUMERIC(14, 4) DEFAULT 0                   NOT NULL,
    dok         TEXT,
    pankkassa   SMALLINT       DEFAULT 0                   NOT NULL,
    muud        TEXT,
    properties  JSONB,
    status      INTEGER        DEFAULT 0
);

ALTER TABLE docs.arvtasu
    OWNER TO postgres;

CREATE INDEX arvtasu_doc_arv_id
    ON docs.arvtasu (doc_arv_id);

CREATE INDEX arvtasu_doc_tasu_id
    ON docs.arvtasu (doc_tasu_id);

CREATE INDEX arvtasu_kpv
    ON docs.arvtasu (kpv);

CREATE UNIQUE INDEX idx_arvtasu_tasu
    ON docs.arvtasu (doc_tasu_id, doc_arv_id)
    WHERE (status <> 3);

CREATE TRIGGER trigd_arvtasu_after
    AFTER DELETE
    ON docs.arvtasu
    FOR EACH ROW
EXECUTE PROCEDURE docs.trigd_arvtasu_after();

CREATE TRIGGER trigiu_arvtasu_after
    AFTER INSERT OR UPDATE
    ON docs.arvtasu
    FOR EACH ROW
EXECUTE PROCEDURE docs.trigiu_arvtasu_after();

ALTER TABLE docs.arvtasu
    drop COLUMN IF EXISTS inf3_jaak;

ALTER TABLE docs.arvtasu
    ADD COLUMN IF NOT EXISTS inf3_summa NUMERIC(14, 4);
