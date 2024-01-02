-- auto-generated definition
DROP TABLE IF EXISTS hooldekodu.hootehingud;

CREATE TABLE hooldekodu.hootehingud (
    id         SERIAL                NOT NULL,
    isikid     INTEGER               NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    ettemaksid INTEGER,               -- seotud ettemaksu kandega
    journalid  INTEGER,
    dokid      INTEGER,               -- seotud dokumendiga
    doktyyp    CHARACTER VARYING(20), -- kui dokid > 0, doktyyp = KASSA,PANK, ARVE
    kpv        DATE                  NOT NULL,
    summa      NUMERIC(18, 6)        NOT NULL DEFAULT 0,
    allikas    CHARACTER VARYING(20) NOT NULL,
    tyyp       CHARACTER VARYING(20) NOT NULL,
    jaak       NUMERIC(18, 6)        NOT NULL DEFAULT 0,
    muud       TEXT,
    properties JSONB,
    status     INTEGER               NOT NULL DEFAULT 1,
    rekvid     INTEGER                        DEFAULT 64,
    CONSTRAINT hootehingud_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hootehingud
    OWNER TO postgres;

ALTER TABLE hooldekodu.hootehingud
    ADD COLUMN IF NOT EXISTS rekvid INTEGER DEFAULT 64;


GRANT ALL ON TABLE hooldekodu.hootehingud TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hootehingud TO soametnik;


