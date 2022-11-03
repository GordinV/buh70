-- Table: docs.mk1

DROP TABLE IF EXISTS docs.mk1;

CREATE TABLE docs.mk1 (
    id        INTEGER               NOT NULL DEFAULT nextval('mk1_id_seq'::REGCLASS),
    parentid  INTEGER               NOT NULL,
    asutusid  INTEGER               NOT NULL,
    nomid     INTEGER               NOT NULL,
    summa     NUMERIC(12, 4)        NOT NULL DEFAULT 0,
    aa        CHARACTER VARYING(27) NOT NULL,
    pank      CHARACTER VARYING(3),
    journalid INTEGER,
    kood1     CHARACTER VARYING(20),
    kood2     CHARACTER VARYING(20),
    kood3     CHARACTER VARYING(20),
    kood4     CHARACTER VARYING(20),
    kood5     CHARACTER VARYING(20),
    konto     CHARACTER VARYING(20),
    tp        CHARACTER VARYING(20),
    tunnus    CHARACTER VARYING(20),
    proj      CHARACTER VARYING(20),
    CONSTRAINT mk1_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.mk1 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.mk1 TO dbkasutaja;
GRANT ALL ON TABLE docs.mk1 TO dbadmin;
GRANT SELECT ON TABLE docs.mk1 TO dbvaatleja;

CREATE INDEX idx_mk1_parentid ON docs.mk1 USING BTREE (parentid);
CREATE INDEX idx_mk1_asutusid ON docs.mk1 USING BTREE (asutusid);
CREATE INDEX idx_mk1_nomidid ON docs.mk1 USING BTREE (nomid);


ALTER TABLE docs.mk1
    ALTER COLUMN aa TYPE CHARACTER VARYING(27);