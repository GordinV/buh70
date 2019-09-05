DROP TABLE IF EXISTS lapsed.lapse_kaart;

CREATE TABLE lapsed.lapse_kaart (
    id         SERIAL,
    parentid   INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE CASCADE ON UPDATE CASCADE,
    rekvid     INTEGER NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    nomid      INTEGER NOT NULL REFERENCES libs.nomenklatuur (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    hind       NUMERIC(14, 4)   DEFAULT 0,
    tunnus     VARCHAR(20),
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP        DEFAULT now(),
    staatus    INTEGER NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT lapse_kaart_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.lapse_kaart TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.lapse_kaart TO arvestaja;
GRANT ALL ON TABLE lapsed.lapse_kaart TO dbadmin;
GRANT SELECT ON TABLE lapsed.lapse_kaart TO dbvaatleja;


DROP INDEX IF EXISTS lapse_kaart_parentid_idx;
CREATE INDEX IF NOT EXISTS lapse_kaart_parentid_idx ON lapsed.lapse_kaart (parentid);

DROP INDEX IF EXISTS lapse_kaart_rekvid_idx;
CREATE INDEX IF NOT EXISTS lapse_kaart_rekvid_idx ON lapsed.lapse_kaart (rekvid);

DROP INDEX IF EXISTS lapse_kaart_nomid_idx;
CREATE INDEX IF NOT EXISTS lapse_kaart_nomid_idx ON lapsed.lapse_kaart (nomid);
