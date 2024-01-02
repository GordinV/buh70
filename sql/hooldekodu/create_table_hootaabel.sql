-- auto-generated definition
DROP TABLE IF EXISTS hooldekodu.hootaabel;

CREATE TABLE hooldekodu.hootaabel (
    id              SERIAL         NOT NULL,
    isikid          INTEGER        NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    nomid           INTEGER        NOT NULL REFERENCES libs.nomenklatuur (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    kpv             DATE           NOT NULL,
    kogus           NUMERIC(18, 4) NOT NULL DEFAULT 0,
    summa           NUMERIC(18, 6) NOT NULL DEFAULT 0,
    arvid           INTEGER        NOT NULL,
    sugulane_arv_id INTEGER        NOT NULL,
    muud            TEXT,
    tuluarvid       INTEGER,
    properties      JSONB,
    rekvid          INTEGER                 DEFAULT 64,
    status          INTEGER        NOT NULL DEFAULT 1,
    CONSTRAINT hootaabel_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hootaabel
    ADD COLUMN IF NOT EXISTS rekvid INTEGER DEFAULT 64;

ALTER TABLE hooldekodu.hootaabel
    ADD COLUMN IF NOT EXISTS sugulane_arv_id INTEGER;


ALTER TABLE hooldekodu.hootaabel
    ADD COLUMN IF NOT EXISTS hind NUMERIC(14, 2) DEFAULT 0;

ALTER TABLE hooldekodu.hootaabel
    ADD COLUMN IF NOT EXISTS soodustus NUMERIC(14, 2) DEFAULT 0;

ALTER TABLE hooldekodu.hootaabel
    ADD COLUMN IF NOT EXISTS lepingid INTEGER;

ALTER TABLE hooldekodu.hootaabel
    ADD COLUMN IF NOT EXISTS alus_hind NUMERIC(14, 2) DEFAULT 64;


ALTER TABLE hooldekodu.hootaabel
    OWNER TO postgres;


GRANT ALL ON TABLE hooldekodu.hootaabel TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hootaabel TO soametnik;


