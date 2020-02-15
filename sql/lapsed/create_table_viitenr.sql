DROP TABLE IF EXISTS lapsed.viitenr;

CREATE TABLE lapsed.viitenr (
    id         SERIAL,
    isikukood   text,
    rekv_id     INTEGER NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    viitenumber text ,
    CONSTRAINT viitenr_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT ON TABLE lapsed.viitenr TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE lapsed.viitenr TO dbkasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.viitenr TO arvestaja;
GRANT ALL ON TABLE lapsed.viitenr TO dbadmin;
GRANT SELECT ON TABLE lapsed.viitenr TO dbvaatleja;

DROP INDEX IF EXISTS viitenr_isikukood_idx;
CREATE INDEX IF NOT EXISTS viitenr_isikukood_idx ON lapsed.viitenr (isikukood);

DROP INDEX IF EXISTS viitenr_rekv_id_idx;
CREATE INDEX IF NOT EXISTS viitenr_rekv_id_idx ON lapsed.viitenr (rekv_id);

DROP INDEX IF EXISTS viitenr_viitenumber_idx;
CREATE INDEX IF NOT EXISTS viitenr_viitenumber_idx ON lapsed.viitenr (viitenumber);
