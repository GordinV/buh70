DROP TABLE IF EXISTS pank_vv;
DROP TABLE IF EXISTS lapsed.pank_vv;

CREATE TABLE lapsed.pank_vv (
    id          SERIAL,
    userid      INTEGER,
    doc_id      INTEGER,
    pank_id     TEXT,
    viitenumber TEXT,
    maksja      TEXT,
    iban        TEXT,
    summa       NUMERIC(12, 2),
    kpv         DATE,
    selg        TEXT,
    markused    TEXT,
    properties  JSONB,
    pank        TEXT,
    TIMESTAMP   TIMESTAMP DEFAULT now(),
    CONSTRAINT pank_vv_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.pank_vv TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.pank_vv TO arvestaja;
GRANT ALL ON TABLE lapsed.pank_vv TO dbadmin;
GRANT SELECT ON TABLE lapsed.pank_vv TO dbvaatleja;


ALTER TABLE lapsed.pank_vv ADD COLUMN IF NOT EXISTS number text;
ALTER TABLE lapsed.pank_vv ADD COLUMN IF NOT EXISTS isikukood text;
ALTER TABLE lapsed.pank_vv ADD COLUMN IF NOT EXISTS aa text;


/*
pank_id TEXT, summa NUMERIC(12, 2), kpv DATE, maksja TEXT, iban TEXT,
                                            selg TEXT, viitenr TEXT
 */