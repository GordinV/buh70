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
GRANT SELECT, UPDATE, INSERT, DELETE  ON TABLE lapsed.pank_vv TO dbkasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.pank_vv TO arvestaja;
GRANT ALL ON TABLE lapsed.pank_vv TO dbadmin;
GRANT SELECT ON TABLE lapsed.pank_vv TO dbvaatleja;


ALTER TABLE lapsed.pank_vv ADD COLUMN IF NOT EXISTS number text;
ALTER TABLE lapsed.pank_vv ADD COLUMN IF NOT EXISTS isikukood text;
ALTER TABLE lapsed.pank_vv ADD COLUMN IF NOT EXISTS aa text;


DROP INDEX IF EXISTS pank_vv_timestamp_idx;

CREATE INDEX IF NOT EXISTS pank_vv_timestamp_idx ON lapsed.pank_vv (timestamp);

DROP INDEX IF EXISTS pank_vv_kpv_idx;

CREATE INDEX IF NOT EXISTS pank_vv_kpv_idx ON lapsed.pank_vv (kpv);

DROP INDEX IF EXISTS pank_vv_viitenumber_idx;
CREATE INDEX IF NOT EXISTS pank_vv_viitenumber_idx ON lapsed.pank_vv (viitenumber) WHERE doc_id is null  AND NOT left(coalesce(markused,''), 4) = 'Kuni';

DROP INDEX IF EXISTS pank_vv_viitenumber_idx_1;
CREATE INDEX IF NOT EXISTS pank_vv_viitenumber_idx_1 ON lapsed.pank_vv (viitenumber);

DROP INDEX IF EXISTS pank_vv_number_idx;
CREATE INDEX IF NOT EXISTS pank_vv_number_idx ON lapsed.pank_vv (number);


/*
pank_id TEXT, summa NUMERIC(12, 2), kpv DATE, maksja TEXT, iban TEXT,
                                            selg TEXT, viitenr TEXT
 */