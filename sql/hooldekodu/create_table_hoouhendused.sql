-- auto-generated definition
DROP TABLE IF EXISTS hooldekodu.hoouhendused;

CREATE TABLE hooldekodu.hoouhendused (
    id         SERIAL  NOT NULL,
    isikid     INTEGER NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    rekvid     INTEGER NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    dokid      INTEGER NOT NULL,
    doktyyp    CHARACTER VARYING(20),
    properties JSONB,
    status     INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT hoouhendused_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hoouhendused
    OWNER TO postgres;


GRANT ALL ON TABLE hooldekodu.hoouhendused TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hoouhendused TO soametnik;


GRANT ALL ON SEQUENCE hooldekodu.hooettemaksud_id_seq TO hkametnik;

GRANT ALL ON SEQUENCE hooldekodu.hooettemaksud_id_seq TO soametnik;

GRANT ALL ON SEQUENCE hooldekodu.hoojaak_id_seq TO hkametnik;

GRANT ALL ON SEQUENCE hooldekodu.hoojaak_id_seq TO soametnik;

GRANT ALL ON SEQUENCE hooldekodu.hooldaja_id_seq TO hkametnik;

GRANT ALL ON SEQUENCE hooldekodu.hooldaja_id_seq TO soametnik;

GRANT ALL ON SEQUENCE hooldekodu.hooleping_id_seq TO hkametnik;

GRANT ALL ON SEQUENCE hooldekodu.hooleping_id_seq TO soametnik;

GRANT ALL ON SEQUENCE hooldekodu.hootaabel_id_seq TO hkametnik;

GRANT ALL ON SEQUENCE hooldekodu.hootaabel_id_seq TO soametnik;

GRANT ALL ON SEQUENCE hooldekodu.hooteenused_id_seq TO hkametnik;

GRANT ALL ON SEQUENCE hooldekodu.hooteenused_id_seq TO soametnik;

GRANT ALL ON SEQUENCE hooldekodu.hootehingud_id_seq TO hkametnik;

GRANT ALL ON SEQUENCE hooldekodu.hootehingud_id_seq TO soametnik;

GRANT ALL ON SEQUENCE hooldekodu.hootoendid_id_seq TO hkametnik;

GRANT ALL ON SEQUENCE hooldekodu.hootoendid_id_seq TO soametnik;

GRANT ALL ON SEQUENCE hooldekodu.hoouhendused_id_seq TO hkametnik;

GRANT ALL ON SEQUENCE hooldekodu.hoouhendused_id_seq TO soametnik;

select * from ou.config
where rekvid = 64

INSERT into ou.config (rekvid, keel, properties)
select 132, keel, properties
from ou.config where id = 48