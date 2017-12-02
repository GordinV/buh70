
DROP TABLE if exists docs.journal1;

CREATE TABLE docs.journal1
(
  id serial,
  parentid integer NOT NULL,
  summa numeric(16,4) NOT NULL DEFAULT 0,
  dokument text,
  muud text,
  kood1 character varying(20) NOT NULL DEFAULT space(20),
  kood2 character varying(20) NOT NULL DEFAULT space(20),
  kood3 character varying(20) NOT NULL DEFAULT space(20),
  kood4 character varying(20) NOT NULL DEFAULT space(20),
  kood5 character varying(20) NOT NULL DEFAULT space(20),
  deebet character varying(20) NOT NULL DEFAULT space(20),
  lisa_k character varying(20) NOT NULL DEFAULT space(20),
  kreedit character varying(20) NOT NULL DEFAULT space(20),
  lisa_d character varying(20) NOT NULL DEFAULT space(20),
  valuuta character varying(20) NOT NULL DEFAULT space(20),
  kuurs numeric(12,6) NOT NULL DEFAULT 1,
  valsumma numeric(16,4) NOT NULL DEFAULT 0,
  tunnus character varying(20) NOT NULL DEFAULT space(20),
  proj character varying(20) DEFAULT space(1),
  CONSTRAINT journal1_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT ALL ON TABLE docs.journal1 TO vlad;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal1 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal1 TO dbkasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal1 TO dbadmin;
GRANT SELECT ON TABLE docs.journal1 TO dbvaatleja;


 DROP INDEX if exists docs.journal1_dbkr_idx;

CREATE INDEX journal1_dbkr_idx
  ON docs.journal1
  USING btree
  (deebet COLLATE pg_catalog."default", kreedit COLLATE pg_catalog."default");


DROP INDEX if exists docs.journal1_eelarve_idx;

CREATE INDEX journal1_eelarve_idx
  ON docs.journal1
  USING btree
  (kood1 COLLATE pg_catalog."default", kood2 COLLATE pg_catalog."default", kood3 COLLATE pg_catalog."default", kood5 COLLATE pg_catalog."default", lisa_d COLLATE pg_catalog."default", lisa_k COLLATE pg_catalog."default");


DROP INDEX if exists docs.journal1_tunnus_idx;

CREATE INDEX journal1_tunnus_idx
  ON docs.journal1
  USING btree
  (tunnus COLLATE pg_catalog."default");


DROP INDEX if exists docs.journal_parentid_idx;

CREATE INDEX journal_parentid_idx
  ON docs.journal1
  USING btree
  (parentid);

ALTER TABLE docs.journal1 CLUSTER ON journal_parentid_idx;

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
