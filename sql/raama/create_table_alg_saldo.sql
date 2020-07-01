-- Table: public.subkonto

DROP TABLE if exists docs.alg_saldo;

CREATE TABLE docs.alg_saldo
(
    id       SERIAL,
    journal_id  INTEGER,
    kpv date,
    CONSTRAINT alg_saldo_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS = TRUE
    )
    TABLESPACE pg_default;

GRANT ALL ON TABLE docs.alg_saldo TO dbadmin;

GRANT SELECT, DELETE ON TABLE docs.alg_saldo TO dbkasutaja;

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE docs.alg_saldo TO dbpeakasutaja;

GRANT SELECT ON TABLE docs.alg_saldo TO dbvaatleja;

DROP INDEX IF EXISTS docs.alg_saldo_journal_id;

CREATE INDEX alg_saldo_journal_id
    ON docs.alg_saldo USING BTREE
        (journal_id)
    TABLESPACE pg_default;

