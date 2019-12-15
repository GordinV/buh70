DROP TABLE IF EXISTS docs.teatis;

CREATE TABLE docs.teatis (
    id         SERIAL,
    parentid   INTEGER REFERENCES docs.doc,
    asutusid   INTEGER REFERENCES libs.asutus,
    docs       INTEGER[],
    number     TEXT,
    kpv        DATE             DEFAULT current_date,
    sisu       TEXT,
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP        DEFAULT now(),
    staatus    INTEGER NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT teatis_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.teatis TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE docs.teatis TO arvestaja;
GRANT SELECT, INSERT, UPDATE ON TABLE docs.teatis TO dbkasutaja;
GRANT ALL ON TABLE docs.teatis TO dbadmin;
GRANT SELECT ON TABLE docs.teatis TO dbvaatleja;

DROP INDEX IF EXISTS docs.teatised_parentid_idx;
DROP INDEX IF EXISTS docs.teatis_parentid_idx;
CREATE INDEX IF NOT EXISTS teatis_parentid_idx ON docs.teatis (parentid);

DROP INDEX IF EXISTS docs.teatised_kpv_idx;
DROP INDEX IF EXISTS docs.teatis_kpv_idx;
CREATE INDEX IF NOT EXISTS teatis_kpv_idx ON docs.teatis (kpv);

DROP INDEX IF EXISTS docs.teatised_asutusid_idx;
DROP INDEX IF EXISTS docs.teatis_asutusid_idx;
CREATE INDEX IF NOT EXISTS teatis_asutusid_idx ON docs.teatis (asutusid);

DROP INDEX IF EXISTS docs.teatised_staatus_idx;
DROP INDEX IF EXISTS docs.teatis_staatus_idx;
CREATE INDEX IF NOT EXISTS teatis_staatus_idx ON docs.teatis (staatus) WHERE staatus <> 3;


