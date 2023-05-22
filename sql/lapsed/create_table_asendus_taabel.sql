DROP TABLE IF EXISTS lapsed.asendus_taabel;

CREATE TABLE lapsed.asendus_taabel (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    rekvid     INTEGER NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    nomid      INTEGER NOT NULL REFERENCES libs.nomenklatuur (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    yksusid    INTEGER REFERENCES libs.library (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    kuu        INTEGER NOT NULL,
    aasta      INTEGER NOT NULL,
    kogus      NUMERIC(14, 4)   DEFAULT 0,
    hind       NUMERIC(14, 2)   DEFAULT 0,
    summa      NUMERIC(14, 2)   DEFAULT 0,
    soodustus  NUMERIC(14, 2)   DEFAULT 0,
    tunnus     VARCHAR(20),
    taabelid   INTEGER REFERENCES lapsed.lapse_taabel (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP        DEFAULT now(),
    staatus    INTEGER NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT asendus_taabel_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.asendus_taabel TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.asendus_taabel TO arvestaja;
GRANT ALL ON TABLE lapsed.asendus_taabel TO dbadmin;
GRANT SELECT ON TABLE lapsed.asendus_taabel TO dbvaatleja;

ALTER table lapsed.asendus_taabel alter COLUMN yksusid drop NOT NULL;

alter table lapsed.asendus_taabel add COLUMN if not EXISTS viitenumber text;

DROP INDEX IF EXISTS asendus_taabel_parentid_idx;
CREATE INDEX IF NOT EXISTS asendus_taabel_parentid_idx ON lapsed.asendus_taabel (parentid);

DROP INDEX IF EXISTS asendus_taabel_rekvid_idx;
CREATE INDEX IF NOT EXISTS asendus_taabel_rekvid_idx ON lapsed.asendus_taabel (rekvid);

DROP INDEX IF EXISTS asendus_taabel_nomid_idx;
CREATE INDEX IF NOT EXISTS asendus_taabel_nomid_idx ON lapsed.asendus_taabel (nomid);

DROP INDEX IF EXISTS asendus_taabel_period_idx;
CREATE INDEX IF NOT EXISTS asendus_taabel_period_idx ON lapsed.asendus_taabel (kuu, aasta);

ALTER TABLE lapsed.asendus_taabel
    ADD CONSTRAINT check_kuu CHECK ((kuu >= 1 AND kuu < 13) OR kuu = 0);

ALTER TABLE lapsed.asendus_taabel
    DROP CONSTRAINT IF EXISTS check_aasta;

ALTER TABLE lapsed.asendus_taabel
    ADD CONSTRAINT check_aasta CHECK (aasta >= date_part('year', now()) - 10 );

