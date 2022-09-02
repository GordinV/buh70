DROP TABLE IF EXISTS ou.noticed;

CREATE TABLE ou.noticed (
    id        SERIAL NOT NULL
        CONSTRAINT noticed__pkey
            PRIMARY KEY,
    userId    INTEGER,
    teatis    TEXT,
    task_name TEXT,
    status    INTEGER   DEFAULT 1,
    TIMESTAMP TIMESTAMP DEFAULT now()
);


GRANT ALL ON TABLE ou.noticed TO dbpeakasutaja;
GRANT ALL ON TABLE ou.noticed TO dbkasutaja;
GRANT ALL ON TABLE ou.noticed TO arvestaja;

DROP INDEX if EXISTS ou.noticed_index;

CREATE INDEX noticed_index
    ON ou.noticed (userId)
    WHERE status = 1


