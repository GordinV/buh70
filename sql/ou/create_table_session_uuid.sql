DROP TABLE IF EXISTS ou.session_uuid;

CREATE TABLE ou.session_uuid (
    id              SERIAL NOT NULL
        CONSTRAINT session_uuid__pkey
            PRIMARY KEY,
    userId          INTEGER,
    asutusId        INTEGER,
    uuid            TEXT,
    TIMESTAMP       TIMESTAMP DEFAULT now()
);


GRANT ALL ON TABLE ou.session_uuid TO dbpeakasutaja;
GRANT ALL ON TABLE ou.session_uuid TO dbkasutaja;
GRANT ALL ON TABLE ou.session_uuid TO arvestaja;


CREATE INDEX session_uuid_index
    ON ou.session_uuid (uuid);

ALTER TABLE ou.session_uuid add COLUMN  if not EXISTS user_data jsonb;