DROP TABLE IF EXISTS docs.journal;

CREATE TABLE docs.journal (
    id       SERIAL,
    parentid INTEGER,
    rekvid   INTEGER,
    userid   INTEGER,
    kpv      DATE NOT NULL DEFAULT ('now'::TEXT)::DATE,
    asutusid INTEGER,
    selg     TEXT,
    dok      TEXT,
    muud     TEXT,
    dokid    INTEGER,
    objekt   TEXT,
    CONSTRAINT journal_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT ALL ON TABLE docs.journal TO vlad;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal TO dbkasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal TO dbadmin;
GRANT SELECT ON TABLE docs.journal TO dbvaatleja;

DROP INDEX IF EXISTS docs.journal_kpv_idx;

CREATE INDEX journal_kpv_idx
    ON docs.journal
        USING btree
        (kpv);


DROP INDEX IF EXISTS docs.journal_asutusId_idx;

CREATE INDEX journal_asutusId_idx
    ON docs.journal
        USING btree
        (asutusid);


DROP INDEX IF EXISTS docs.journal_userid_idx;

CREATE INDEX journal_userid_idx
    ON docs.journal
        USING btree
        (userid);


DROP INDEX IF EXISTS docs.journal_rekvid_idx;

CREATE INDEX journal_rekvid_idx
    ON docs.journal
        USING btree
        (rekvid);

ALTER TABLE docs.journal
    CLUSTER ON journal_rekvid_idx;


CREATE INDEX journal_doc_parentid_idx
    ON docs.journal USING btree (parentid);

CREATE TABLE IF NOT EXISTS docs.journal_2021 (
    aasta INTEGER
)
    INHERITS (docs.journal);

ALTER TABLE docs.journal
    ADD COLUMN IF NOT EXISTS properties JSONB;
