DROP TABLE IF EXISTS eelarve.taotlus1;

CREATE TABLE eelarve.taotlus1 (
    id         SERIAL                   NOT NULL
        CONSTRAINT taotlus1_pkey
            PRIMARY KEY,
    parentid   INTEGER,
    eelprojid  INTEGER,
    eelarveid  INTEGER,
    kood1      VARCHAR(20),
    kood2      VARCHAR(20),
    kood3      VARCHAR(20),
    kood4      VARCHAR(20),
    kood5      VARCHAR(20),
    proj       VARCHAR(20),
    tunnus     VARCHAR(20),
    summa      NUMERIC(14, 2) DEFAULT 0 NOT NULL,
    selg       TEXT,
    status     INTEGER        DEFAULT 1 NOT NULL,
    markused   TEXT,
    muud       TEXT,
    properties JSONB
);
CREATE INDEX taotlus1_parentid
    ON eelarve.taotlus1 (parentid);
CREATE INDEX taotlus1_eelprojid
    ON eelarve.taotlus1 (eelprojid);
CREATE INDEX taotlus1_eelarveid
    ON eelarve.taotlus1 (eelarveid);

ALTER TABLE eelarve.taotlus1
    ADD COLUMN IF NOT EXISTS oodatav_taitmine NUMERIC(14, 2) DEFAULT 0;

ALTER TABLE eelarve.taotlus1
    ADD COLUMN IF NOT EXISTS objekt varchar(20);
