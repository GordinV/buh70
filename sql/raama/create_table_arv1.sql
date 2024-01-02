DROP TABLE if exists docs.arv1;

CREATE TABLE docs.arv1
(
  id       serial,
  parentid integer               NOT NULL,
  nomid    integer               NOT NULL,
  kogus    numeric(18, 3)        NOT NULL DEFAULT 0,
  hind     numeric(12, 4)        NOT NULL DEFAULT 0,
  soodus   smallint              NOT NULL DEFAULT 0,
  kbm      numeric(12, 4)        NOT NULL DEFAULT 0,
  maha     smallint              NOT NULL DEFAULT 0,
  summa    numeric(12, 4)        NOT NULL DEFAULT 0,
  muud     text,
  kood1    character varying(20) NOT NULL DEFAULT space(20),
  kood2    character varying(20) NOT NULL DEFAULT space(20),
  kood3    character varying(20) NOT NULL DEFAULT space(20),
  kood4    character varying(20) NOT NULL DEFAULT space(20),
  kood5    character varying(20) NOT NULL DEFAULT space(20),
  konto    character varying(20) NOT NULL DEFAULT space(20),
  tp       character varying(20) NOT NULL DEFAULT space(20),
  kbmta    numeric(12, 4)        NOT NULL DEFAULT 0,
  isikid   integer               NOT NULL DEFAULT 0,
  tunnus   character varying(20) NOT NULL DEFAULT space(20),
  proj     character varying(20) NOT NULL DEFAULT space(20),
  tahtaeg  date,
  CONSTRAINT arv1_pkey PRIMARY KEY (id)
)
WITH (
OIDS = TRUE
);

alter table docs.arv1
  add column properties jsonb null;

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.arv1 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.arv1 TO dbkasutaja;
GRANT ALL ON TABLE docs.arv1 TO dbadmin;
GRANT SELECT ON TABLE docs.arv1 TO dbvaatleja;

-- Index: public.arv1_nomid

-- DROP INDEX public.arv1_nomid;

CREATE INDEX arv1_nomid
  ON docs.arv1
  USING btree
  (nomid);


CREATE INDEX arv1_parentid
  ON docs.arv1
  USING btree
  (parentid);


ALTER TABLE docs.arv1
    ALTER COLUMN kogus TYPE numeric(18, 4);

alter table docs.arv1
    add column if not exists objekt character varying(20) null;

