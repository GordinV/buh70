-- auto-generated definition
DROP TABLE IF EXISTS hooldekodu.hooettemaksud;

CREATE TABLE hooldekodu.hooettemaksud (
    id         SERIAL                NOT NULL,
    isikid     INTEGER REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    kpv        DATE                  NOT NULL,
    summa      NUMERIC(18, 6)        NOT NULL DEFAULT 0,
    dokid      INTEGER               NOT NULL,
    doktyyp    CHARACTER VARYING(20) NOT NULL,           -- kui dokid > 0, doktyyp = LAUSEND,KASSA,PANK
    selg       TEXT,
    muud       TEXT,
    rekvid     INTEGER                        DEFAULT 64,
    properties JSONB,
    staatus    INTEGER               NOT NULL DEFAULT 1, -- 0 - klassifitseeritud, 1 - klassifitseerimata
    CONSTRAINT hooettemaksud_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hooettemaksud
    OWNER TO postgres;


ALTER TABLE hooldekodu.hooettemaksud
    ADD COLUMN IF NOT EXISTS rekvid INTEGER DEFAULT 64;

ALTER TABLE hooldekodu.hooettemaksud
    ADD COLUMN IF NOT EXISTS allikas VARCHAR(20) DEFAULT 'PENSION85';


GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE hooldekodu.hooettemaksud TO dbpeakasutaja;
GRANT SELECT ON TABLE hooldekodu.hooettemaksud TO dbvaatleja;
GRANT SELECT, UPDATE, INSERT, DELETE, TRIGGER ON TABLE hooldekodu.hooettemaksud TO dbkasutaja;

GRANT ALL ON TABLE hooldekodu.hooettemaksud TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hooettemaksud TO soametnik;
COMMENT ON COLUMN hooldekodu.hooettemaksud.doktyyp IS 'kui dokid > 0, doktyyp = LAUSEND,KASSA,PANK';
COMMENT ON COLUMN hooldekodu.hooettemaksud.staatus IS '0 - klassifitseeritud, 1 - klassifitseerimata';


GRANT ALL ON SEQUENCE hooldekodu.hooettemaksud_id_seq TO hkametnik;
GRANT ALL ON SEQUENCE hooldekodu.hooettemaksud_id_seq TO soametnik;