DROP TABLE IF EXISTS lapsed.vanem_arveldus;

CREATE TABLE lapsed.vanem_arveldus (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    asutusid   INTEGER NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    rekvid     INTEGER NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    arveldus   BOOL             DEFAULT FALSE,
    CONSTRAINT vanem_arveldus_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.vanem_arveldus TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.vanem_arveldus TO arvestaja;
GRANT ALL ON TABLE lapsed.vanem_arveldus TO dbadmin;
GRANT SELECT ON TABLE lapsed.vanem_arveldus TO dbvaatleja;


DROP INDEX IF EXISTS vanem_arveldus_parentid_idx;

CREATE INDEX IF NOT EXISTS vanem_arveldus_parentid_idx ON lapsed.vanem_arveldus (parentid);

DROP INDEX IF EXISTS vanem_arveldus_asutusid_idx;

CREATE INDEX IF NOT EXISTS vanem_arveldus_asutusid_idx ON lapsed.vanem_arveldus (asutusid);

DROP INDEX IF EXISTS vanem_arveldus_rekvid_idx;

CREATE INDEX IF NOT EXISTS vanem_arveldus_rekvid_idx ON lapsed.vanem_arveldus (rekvid);

ALTER TABLE lapsed.vanem_arveldus
    ADD UNIQUE (asutusid, parentid, rekvid);