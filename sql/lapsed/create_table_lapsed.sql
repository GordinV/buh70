DROP TABLE IF EXISTS lapsed.laps;

CREATE TABLE lapsed.laps (
    id         SERIAL,
    isikukood  CHAR(11) NOT NULL,
    nimi       TEXT     NOT NULL,
    properties JSONB,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP         DEFAULT now(),
    staatus    INTEGER  NOT NULL DEFAULT 1,
    muud       TEXT,
    CONSTRAINT lapsed_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.laps TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.laps TO arvestaja;
GRANT ALL ON TABLE lapsed.laps TO dbadmin;
GRANT SELECT ON TABLE lapsed.laps TO dbvaatleja;

drop INDEX if exists lapsed.laps_isikukood_idx;
CREATE UNIQUE INDEX CONCURRENTLY laps_isikukood_idx ON lapsed.laps (isikukood, staatus);

