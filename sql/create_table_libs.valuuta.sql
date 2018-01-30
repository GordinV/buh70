
DROP TABLE if exists libs.valuuta;

CREATE TABLE libs.valuuta
(
    id serial,
    parentid integer,
    kuurs numeric(14,4) DEFAULT 1,
    alates date,
    kuni date,
    muud text,
    CONSTRAINT valuuta_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = TRUE
)
TABLESPACE pg_default;


GRANT INSERT, DELETE, UPDATE, SELECT ON TABLE libs.valuuta TO dbkasutaja;

GRANT INSERT, DELETE, UPDATE, SELECT ON TABLE libs.valuuta TO dbpeakasutaja;

GRANT select ON TABLE libs.valuuta TO dbvaatleja;

GRANT ALL ON TABLE libs.valuuta TO dbadmin;

DROP INDEX if exists libs.valuuta_idx;

CREATE INDEX valuuta_idx
    ON libs.valuuta USING btree
    (parentid)
    TABLESPACE pg_default;

