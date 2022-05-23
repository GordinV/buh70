DROP TABLE IF EXISTS lapsed.day_taabel CASCADE;

CREATE TABLE lapsed.day_taabel (
    id         SERIAL,
    kpv        DATE,
    rekv_id    INTEGER NOT NULL REFERENCES ou.rekv (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    grupp_id   INTEGER REFERENCES libs.library (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    ajalugu    JSONB,
    TIMESTAMP  TIMESTAMP        DEFAULT now(),
    staatus    INTEGER NOT NULL DEFAULT 1,
    muud       TEXT,
    properties JSONB,
    CONSTRAINT day_taabel_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.day_taabel TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.day_taabel TO arvestaja;
GRANT ALL ON TABLE lapsed.day_taabel TO dbadmin;
GRANT SELECT ON TABLE lapsed.day_taabel TO dbvaatleja;

DROP INDEX IF EXISTS day_taabel_rekvid_idx;
CREATE INDEX IF NOT EXISTS day_taabel_rekvid_idx ON lapsed.day_taabel (rekv_id);

DROP INDEX IF EXISTS day_taabel_gruppid_idx;
CREATE INDEX IF NOT EXISTS day_taabel_gruppid_idx ON lapsed.day_taabel (grupp_id);

DROP INDEX IF EXISTS day_taabel_kpv_idx;
CREATE INDEX IF NOT EXISTS day_taabel_kpv_idx ON lapsed.day_taabel (kpv);



DROP TABLE IF EXISTS lapsed.day_taabel1 CASCADE;

CREATE TABLE lapsed.day_taabel1 (
    id         SERIAL,
    parent_id  INTEGER NOT NULL REFERENCES lapsed.day_taabel (id) ON DELETE CASCADE ON UPDATE CASCADE,
    nom_id     INTEGER NOT NULL REFERENCES libs.nomenklatuur (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    laps_id    INTEGER NOT NULL REFERENCES lapsed.laps (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    kogus      NUMERIC(14, 4) DEFAULT 0,
    taabel_id  INTEGER REFERENCES lapsed.lapse_taabel (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    muud       TEXT,
    properties JSONB,
    CONSTRAINT day_taabel1_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE lapsed.day_taabel1 TO dbpeakasutaja;
GRANT SELECT, INSERT, UPDATE ON TABLE lapsed.day_taabel1 TO arvestaja;
GRANT ALL ON TABLE lapsed.day_taabel1 TO dbadmin;
GRANT SELECT ON TABLE lapsed.day_taabel1 TO dbvaatleja;


DROP INDEX IF EXISTS day_taabel1_parentid_idx;
CREATE INDEX IF NOT EXISTS day_taabel1_parentid_idx ON lapsed.day_taabel1 (parent_id);

DROP INDEX IF EXISTS day_taabel_nomid_idx;
CREATE INDEX IF NOT EXISTS day_taabel_nomid_idx ON lapsed.day_taabel1 (nom_id);

DROP INDEX IF EXISTS day_taabel_lapsid_idx;
CREATE INDEX IF NOT EXISTS day_taabel_lapsid_idx ON lapsed.day_taabel1 (laps_id);

DROP INDEX IF EXISTS day_taabel_taabel_id_idx;
CREATE INDEX IF NOT EXISTS day_taabel_taabel_id_idx ON lapsed.day_taabel1 (taabel_id);


alter table lapsed.day_taabel1 add COLUMN if not exists osalemine INTEGER DEFAULT 1;

alter table lapsed.day_taabel1 add COLUMN if not exists covid INTEGER DEFAULT 0;