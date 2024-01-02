-- auto-generated definition
CREATE TABLE hooldekodu.hooldaja (
    id          SERIAL                 NOT NULL,
    hooldajaid  INTEGER                NOT NULL,
    isikid      INTEGER                NOT NULL,
    kohtumaarus CHARACTER VARYING(254) NOT NULL,
    algkpv      DATE                   NOT NULL,
    loppkpv     DATE,
    muud        TEXT,
    status integer,
    CONSTRAINT hooldaja_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hooldaja
    OWNER TO postgres;


GRANT ALL ON TABLE hooldekodu.hooldaja TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hooldaja TO soametnik;

ALTER TABLE hooldekodu.hooldaja
    ADD COLUMN IF NOT EXISTS properties JSONB;

ALTER TABLE hooldekodu.hooldaja
    ADD COLUMN IF NOT EXISTS status integer;
