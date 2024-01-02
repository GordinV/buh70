-- auto-generated definition
DROP TABLE IF EXISTS hooldekodu.hootoendid;

CREATE TABLE hooldekodu.hootoendid (
    id         SERIAL                 NOT NULL,
    isikid     INTEGER                NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    rekvid     INTEGER                NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    kpv        DATE                   NOT NULL,
    aruanne    CHARACTER VARYING(254) NOT NULL,
    kellele    CHARACTER VARYING(254) NOT NULL,
    koostaja   CHARACTER VARYING(254) NOT NULL,
    muud       TEXT,
    properties JSONB,
    status     INTEGER                NOT NULL DEFAULT 1,
    CONSTRAINT hootoendid_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hootoendid
    OWNER TO postgres;


GRANT ALL ON TABLE hooldekodu.hootoendid TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hootoendid TO soametnik;


