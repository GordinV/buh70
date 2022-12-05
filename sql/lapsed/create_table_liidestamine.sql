DROP TABLE IF EXISTS lapsed.liidestamine;

CREATE TABLE lapsed.liidestamine (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    docid     INTEGER NOT NULL REFERENCES docs.doc (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT liidestamine_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.liidestamine TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.liidestamine TO arvestaja;
GRANT ALL ON TABLE lapsed.liidestamine TO dbadmin;
GRANT SELECT ON TABLE lapsed.liidestamine TO dbvaatleja;


DROP INDEX IF EXISTS liidestamine_parentid_idx;
CREATE INDEX IF NOT EXISTS liidestamine_parentid_idx ON lapsed.liidestamine (parentid);

DROP INDEX IF EXISTS liidestamine_docid_idx;
CREATE INDEX IF NOT EXISTS liidestamine_docid_idx ON lapsed.liidestamine (docid);

