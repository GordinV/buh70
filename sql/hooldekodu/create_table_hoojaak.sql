-- auto-generated definition
DROP TABLE IF EXISTS hooldekodu.hoojaak;

CREATE TABLE hooldekodu.hoojaak (
    id          SERIAL         NOT NULL,
    isikid      INTEGER        NOT NULL REFERENCES libs.asutus (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    pension85   NUMERIC(16, 2) NOT NULL DEFAULT 0,
    pension15   NUMERIC(16, 2) NOT NULL DEFAULT 0,
    toetus      NUMERIC(16, 2) NOT NULL DEFAULT 0,
    vara        NUMERIC(16, 2) NOT NULL DEFAULT 0,
    omavalitsus NUMERIC(16, 2) NOT NULL DEFAULT 0,
    laen        NUMERIC(16, 2) NOT NULL DEFAULT 0,
    muud        NUMERIC(16, 2) NOT NULL DEFAULT 0,
    CONSTRAINT hoojaak_pkey PRIMARY KEY (id)
);

ALTER TABLE hooldekodu.hoojaak
    OWNER TO postgres;

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE hooldekodu.hoojaak TO dbpeakasutaja;
GRANT SELECT ON TABLE hooldekodu.hoojaak TO dbvaatleja;
GRANT SELECT, UPDATE, INSERT, DELETE, TRIGGER ON TABLE hooldekodu.hoojaak TO dbkasutaja;

GRANT ALL ON TABLE hooldekodu.hoojaak TO hkametnik;
GRANT ALL ON TABLE hooldekodu.hoojaak TO soametnik;


ALTER TABLE hooldekodu.hoojaak
    ADD COLUMN IF NOT EXISTS tulud NUMERIC(16, 2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS kulud NUMERIC(16, 2) DEFAULT 0;

ALTER TABLE hooldekodu.hoojaak
    ADD COLUMN IF NOT EXISTS taskuraha_kov NUMERIC(16, 2) DEFAULT 0;
