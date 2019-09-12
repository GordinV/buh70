DROP TABLE IF EXISTS lapsed.vanemad;

CREATE TABLE lapsed.vanemad (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    asutusid   INTEGER NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP        DEFAULT now(),
    staatus    INTEGER NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT vanemad_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.vanemad TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.vanemad TO arvestaja;
GRANT ALL ON TABLE lapsed.vanemad TO dbadmin;
GRANT SELECT ON TABLE lapsed.vanemad TO dbvaatleja;


DROP INDEX IF EXISTS vanemad_parentid_idx;

CREATE INDEX IF NOT EXISTS vanemad_parentid_idx ON lapsed.vanemad (parentid);

DROP INDEX IF EXISTS vanemad_asutudid_idx;

CREATE INDEX IF NOT EXISTS vanemad_asutusid_idx ON lapsed.vanemad (asutusid);

DROP INDEX IF EXISTS vanemad_asutudid_idx;

ALTER TABLE lapsed.vanemad
    ADD UNIQUE (asutusid, parentid);