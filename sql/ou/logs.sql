DROP TABLE IF EXISTS ou.logs;

CREATE TABLE ou.logs (
    id        SERIAL  NOT NULL
        CONSTRAINT logs__pkey
            PRIMARY KEY,
    rekvid    INTEGER NOT NULL,
    user_id   INTEGER NOT NULL,
    doc_id    INTEGER,
    TIMESTAMP TIMESTAMP DEFAULT now(),
    propertis JSONB
);


GRANT SELECT, UPDATE, INSERT ON TABLE ou.logs TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE ou.logs TO dbkasutaja;
GRANT ALL ON TABLE ou.logs TO dbadmin;
GRANT SELECT, UPDATE, INSERT ON TABLE ou.logs TO dbvaatleja;

