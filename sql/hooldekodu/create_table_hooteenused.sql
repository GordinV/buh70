-- auto-generated definition
DROP TABLE IF EXISTS hooldekodu.hooteenused;

CREATE TABLE hooldekodu.hooteenused (
    id         SERIAL                NOT NULL,
    lepingid   INTEGER               NOT NULL REFERENCES hooldekodu.hooleping (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    nomid      INTEGER               NOT NULL REFERENCES libs.nomenklatuur (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    hind       NUMERIC(18, 6)        NOT NULL DEFAULT 0,
    allikas    CHARACTER VARYING(20) NOT NULL,
    tuluosa    NUMERIC(6, 2)         NOT NULL DEFAULT 0,
    jaak       NUMERIC(18, 6)        NOT NULL DEFAULT 0,
    muud       TEXT,
    kehtivus   DATE,
    properties JSONB,
    status     INTEGER               NOT NULL DEFAULT 1,
    CONSTRAINT hooteenused_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hooteenused
    OWNER TO postgres;


GRANT ALL ON TABLE hooldekodu.hooteenused TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hooteenused TO soametnik;


