DROP TABLE if exists docs.journal;

CREATE TABLE docs.journal
(
  id serial,
  parentid integer,
  rekvid integer,
  userid integer,
  kpv date NOT NULL DEFAULT ('now'::text)::date,
  asutusid integer,
  selg text,
  dok  text,
  muud text,
  dokid integer,
  objekt text,
  CONSTRAINT journal_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT ALL ON TABLE docs.journal TO vlad;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal TO dbkasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.journal TO dbadmin;
GRANT SELECT ON TABLE docs.journal TO dbvaatleja;

DROP INDEX if exists docs.journal_kpv_idx;

CREATE INDEX journal_kpv_idx
  ON docs.journal
  USING btree
  (kpv);


DROP INDEX if exists docs.journal_asutusId_idx;

CREATE INDEX journal_asutusId_idx
  ON docs.journal
  USING btree
  (asutusid);


DROP INDEX if exists docs.journal_userid_idx;

CREATE INDEX journal_userid_idx
  ON docs.journal
  USING btree
  (userid);


DROP INDEX if exists docs.journal_rekvid_idx;

CREATE INDEX journal_rekvid_idx
  ON docs.journal
  USING btree
  (rekvid);
  
ALTER TABLE docs.journal CLUSTER ON journal_rekvid_idx;


CREATE INDEX journal_doc_parentid_idx
  ON docs.journal using btree (parentid);


