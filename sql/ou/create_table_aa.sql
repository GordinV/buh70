DROP TABLE IF EXISTS ou.aa;

CREATE TABLE ou.aa (
    id       SERIAL,
    parentid INTEGER        NOT NULL,
    arve     CHARACTER(20)  NOT NULL,
    nimetus  CHARACTER(254) NOT NULL,
    saldo    NUMERIC(12, 4) NOT NULL DEFAULT 0,
    default_ SMALLINT       NOT NULL DEFAULT 0,
    kassa    INTEGER        NOT NULL DEFAULT 0,
    pank     INTEGER        NOT NULL DEFAULT 0,
    konto    CHARACTER(20),
    muud     TEXT,
    tp       CHARACTER VARYING(20),
    CONSTRAINT aa_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS= TRUE
    );

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.aa TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.aa TO dbkasutaja;
GRANT ALL ON TABLE ou.aa TO dbadmin;
GRANT SELECT ON TABLE ou.aa TO dbvaatleja;

-- Index: public.aa_parentid

DROP INDEX IF EXISTS public.aa_parentid;

CREATE INDEX aa_parentid
    ON public.aa
        USING btree
        (parentid);

ALTER TABLE ou.aa
    ADD COLUMN IF NOT EXISTS properties JSONB;
