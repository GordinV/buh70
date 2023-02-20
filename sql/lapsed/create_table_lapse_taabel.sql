DROP TABLE IF EXISTS lapsed.lapse_taabel;

CREATE TABLE lapsed.lapse_taabel (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    rekvid     INTEGER NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    nomid      INTEGER NOT NULL REFERENCES libs.nomenklatuur (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    kuu        INTEGER NOT NULL,
    aasta      INTEGER NOT NULL,
    kogus      NUMERIC(14, 4)   DEFAULT 0,
    tunnus     VARCHAR(20),
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP        DEFAULT now(),
    staatus    INTEGER NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT lapse_taabel_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.lapse_taabel TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.lapse_taabel TO arvestaja;
GRANT ALL ON TABLE lapsed.lapse_taabel TO dbadmin;
GRANT SELECT ON TABLE lapsed.lapse_taabel TO dbvaatleja;


DROP INDEX IF EXISTS lapse_taabel_parentid_idx;
CREATE INDEX IF NOT EXISTS lapse_taabel_parentid_idx ON lapsed.lapse_taabel (parentid);

DROP INDEX IF EXISTS lapse_taabel_rekvid_idx;
CREATE INDEX IF NOT EXISTS lapse_taabel_rekvid_idx ON lapsed.lapse_taabel (rekvid);

DROP INDEX IF EXISTS lapse_taabel_nomid_idx;
CREATE INDEX IF NOT EXISTS lapse_taabel_nomid_idx ON lapsed.lapse_taabel (nomid);

DROP INDEX IF EXISTS lapse_taabel_period_idx;
CREATE INDEX IF NOT EXISTS lapse_taabel_period_idx ON lapsed.lapse_taabel (kuu, aasta);

ALTER TABLE lapsed.lapse_taabel
    ADD CONSTRAINT check_kuu CHECK ((kuu >= 1 AND kuu < 13) OR kuu = 0);

ALTER TABLE lapsed.lapse_taabel
    DROP CONSTRAINT IF EXISTS check_aasta;


ALTER TABLE lapsed.lapse_taabel
    DROP CONSTRAINT check_aasta;
ALTER TABLE lapsed.lapse_taabel
    ADD CONSTRAINT check_aasta CHECK (aasta >= date_part('year', now()) - 10 );

ALTER TABLE lapsed.lapse_taabel
    ADD COLUMN IF NOT EXISTS lapse_kaart_id INTEGER;

ALTER TABLE lapsed.lapse_taabel
    ADD COLUMN IF NOT EXISTS hind NUMERIC(14, 4);

ALTER TABLE lapsed.lapse_taabel
    ADD COLUMN IF NOT EXISTS umberarvestus BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE lapsed.lapse_taabel
    ADD COLUMN IF NOT EXISTS summa NUMERIC(14, 4);

ALTER TABLE lapsed.lapse_taabel
    ADD COLUMN IF NOT EXISTS soodustus NUMERIC(14, 4);

ALTER TABLE lapsed.lapse_taabel
    ADD COLUMN IF NOT EXISTS vahe NUMERIC(14, 4);

CREATE INDEX IF NOT EXISTS lapse_taabel_lapse_kaart_id_idx ON lapsed.lapse_taabel (lapse_kaart_id);

CREATE INDEX IF NOT EXISTS lapse_taabel_lapse_kaart_id_soodustus_idx ON lapsed.lapse_taabel (lapse_kaart_id) WHERE soodustus <> 0;
