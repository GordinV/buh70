-- auto-generated definition
DROP TABLE IF EXISTS hooldekodu.hooleping;

CREATE TABLE hooldekodu.hooleping (
    id            SERIAL                 NOT NULL,
    rekvid        INTEGER                NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    isikid        INTEGER                NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    hooldekoduid  INTEGER                NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    "number"      CHARACTER VARYING(20)  NOT NULL,
    omavalitsus   CHARACTER VARYING(120) NOT NULL,
    algkpv        DATE                   NOT NULL DEFAULT date(),
    loppkpv       DATE,
    jaak          NUMERIC(18, 6)         NOT NULL DEFAULT 0,
    summa         NUMERIC(18, 2)         NOT NULL DEFAULT 0,
    osa           NUMERIC(8, 4)          NOT NULL DEFAULT 85,
    muud          TEXT,
    omavalitsusid INTEGER,
    kovjaak       NUMERIC(18, 6)                  DEFAULT 0,
    properties    JSONB,
    ajalugu       JSONB,
    status        INTEGER                NOT NULL DEFAULT 1,
    CONSTRAINT hooleping_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hooleping
    OWNER TO postgres;


GRANT ALL ON TABLE hooldekodu.hooleping TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hooleping TO soametnik;


ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS ajalugu JSONB;

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS omavalitsus CHARACTER VARYING(120);

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS sugulane_id INTEGER,
    ADD COLUMN IF NOT EXISTS sugulane_osa NUMERIC(12, 2) DEFAULT 0;

--ALTER TABLE hooldekodu.hooleping DROP COLUMN if EXISTS tasku_raha;

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS tasku_raha NUMERIC(12, 2) DEFAULT 15;

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS makse_viis INTEGER;

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS BruttoSisseTulek NUMERIC(12, 2) DEFAULT 0;

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS tunnus VARCHAR(20) NULL;

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS rahasaaja_id INTEGER NULL;

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS aa VARCHAR(20) NULL;

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS NetoSisseTulek NUMERIC(12, 2) DEFAULT 0;

ALTER TABLE hooldekodu.hooleping
    ADD COLUMN IF NOT EXISTS hoolduskulud NUMERIC(12, 2) DEFAULT 0;
