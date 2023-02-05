DROP TABLE IF EXISTS ou.paringud;

CREATE TABLE ou.paringud (
    id        SERIAL  NOT NULL
        CONSTRAINT paringud__pkey
            PRIMARY KEY,
    user_id   INTEGER NOT NULL,
    TIMESTAMP TIMESTAMP DEFAULT now(),
    sql text,
    params text,
    tulemused text
);

ALTER TABLE ou.paringud
    ADD COLUMN IF NOT EXISTS changes JSONB NULL;


GRANT SELECT, UPDATE, INSERT ON TABLE ou.paringud TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE ou.paringud TO dbkasutaja;
GRANT ALL ON TABLE ou.paringud TO dbadmin;
GRANT SELECT, UPDATE, INSERT ON TABLE ou.paringud TO dbvaatleja;

