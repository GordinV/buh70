DROP TABLE IF EXISTS docs.journal1;

CREATE TABLE docs.journal1 (
    id       SERIAL,
    parentid INTEGER               NOT NULL,
    summa    NUMERIC(16, 4)        NOT NULL DEFAULT 0,
    dokument TEXT,
    muud     TEXT,
    kood1    CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kood2    CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kood3    CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kood4    CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kood5    CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    deebet   CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    lisa_k   CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kreedit  CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    lisa_d   CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    valuuta  CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    kuurs    NUMERIC(12, 6)        NOT NULL DEFAULT 1,
    valsumma NUMERIC(16, 4)        NOT NULL DEFAULT 0,
    tunnus   CHARACTER VARYING(20) NOT NULL DEFAULT space(20),
    proj     CHARACTER VARYING(20)          DEFAULT space(1),
    CONSTRAINT journal1_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT ALL ON TABLE docs.journal1 TO vlad;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal1 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal1 TO dbkasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal1 TO dbadmin;
GRANT SELECT ON TABLE docs.journal1 TO dbvaatleja;


DROP INDEX IF EXISTS docs.journal1_dbkr_idx;

CREATE INDEX journal1_dbkr_idx
    ON docs.journal1
        USING btree
        (deebet COLLATE pg_catalog."default", kreedit COLLATE pg_catalog."default");


DROP INDEX IF EXISTS docs.journal1_eelarve_idx;

CREATE INDEX journal1_eelarve_idx
    ON docs.journal1
        USING btree
        (kood1 COLLATE pg_catalog."default", kood2 COLLATE pg_catalog."default", kood3 COLLATE pg_catalog."default",
         kood5 COLLATE pg_catalog."default", lisa_d COLLATE pg_catalog."default", lisa_k COLLATE pg_catalog."default");


DROP INDEX IF EXISTS docs.journal1_tunnus_idx;

CREATE INDEX journal1_tunnus_idx
    ON docs.journal1
        USING btree
        (tunnus COLLATE pg_catalog."default");


DROP INDEX IF EXISTS docs.journal_parentid_idx;

CREATE INDEX journal_parentid_idx
    ON docs.journal1
        USING btree
        (parentid);

ALTER TABLE docs.journal1
    CLUSTER ON journal_parentid_idx;
ALTER TABLE docs.journal1
    CLUSTER ON journal_parentid_idx;



ALTER TABLE docs.journal1
    ALTER COLUMN kood1 DROP DEFAULT;
ALTER TABLE docs.journal1
    ALTER COLUMN kood1 DROP NOT NULL;
ALTER TABLE docs.journal1
    ALTER COLUMN kood2 DROP DEFAULT;
ALTER TABLE docs.journal1
    ALTER COLUMN kood2 DROP NOT NULL;
ALTER TABLE docs.journal1
    ALTER COLUMN kood3 DROP DEFAULT;
ALTER TABLE docs.journal1
    ALTER COLUMN kood3 DROP NOT NULL;
ALTER TABLE docs.journal1
    ALTER COLUMN kood4 DROP DEFAULT;
ALTER TABLE docs.journal1
    ALTER COLUMN kood4 DROP NOT NULL;
ALTER TABLE docs.journal1
    ALTER COLUMN kood5 DROP DEFAULT;
ALTER TABLE docs.journal1
    ALTER COLUMN kood5 DROP NOT NULL;
ALTER TABLE docs.journal1
    ALTER COLUMN lisa_k DROP DEFAULT;
ALTER TABLE docs.journal1
    ALTER COLUMN lisa_k DROP NOT NULL;
ALTER TABLE docs.journal1
    ALTER COLUMN lisa_d DROP DEFAULT;
ALTER TABLE docs.journal1
    ALTER COLUMN lisa_d DROP NOT NULL;
ALTER TABLE docs.journal1
    ALTER COLUMN tunnus DROP DEFAULT;
ALTER TABLE docs.journal1
    ALTER COLUMN tunnus DROP NOT NULL;
ALTER TABLE docs.journal1
    ALTER COLUMN proj DROP DEFAULT;

ALTER TABLE docs.journal1
    ALTER COLUMN valuuta SET DEFAULT 'EUR';

CREATE TABLE IF NOT EXISTS docs.journal1_2021 (
    aasta INTEGER
)
    INHERITS (docs.journal1);

ALTER TABLE docs.journal1
    ADD COLUMN IF NOT EXISTS objekt VARCHAR(20);


DROP INDEX IF EXISTS docs.journal1_proj_idx;

CREATE INDEX journal1_proj_idx
    ON docs.journal1
        USING btree
        (proj COLLATE pg_catalog."default")
    WHERE coalesce(proj, '') <> '';

DROP INDEX IF EXISTS docs.journal1_kood4_idx;

CREATE INDEX journal1_kood4_idx
    ON docs.journal1
        USING btree
        (kood4 COLLATE pg_catalog."default")
    WHERE coalesce(kood4, '') <> '';
