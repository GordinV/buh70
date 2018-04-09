
DROP TABLE if exists libs.ladu_jaak;

CREATE TABLE libs.ladu_jaak
(
  id serial,
  rekvid integer,
  dokitemid integer NOT NULL,
  laduid integer, -- ladu
  nomid integer NOT NULL, --vara id
  kpv date NOT NULL DEFAULT ('now'::text)::date, --sise kpv
  hind numeric(12,4) NOT NULL DEFAULT 0, --sisetatud hinnaga
  kogus numeric(18,3) NOT NULL DEFAULT 0,
  maha numeric(18,3) NOT NULL DEFAULT 0, --mahaarvestatud kokku
  jaak numeric(18,3) NOT NULL DEFAULT 0, -- vara jaak
  tahtaeg date,
  CONSTRAINT ladu_jaak_pkey PRIMARY KEY (id)
)
WITH (
OIDS = TRUE
)
TABLESPACE pg_default;


GRANT ALL ON TABLE libs.ladu_jaak TO dbadmin;

GRANT SELECT, INSERT, UPDATE ON TABLE libs.ladu_jaak TO dbkasutaja;

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE libs.ladu_jaak TO dbpeakasutaja;

GRANT SELECT ON TABLE libs.ladu_jaak TO dbvaatleja;

GRANT INSERT, SELECT, UPDATE ON TABLE libs.ladu_jaak TO ladukasutaja;


DROP INDEX if exists libs.ladu_jaak_nomid;

CREATE INDEX ladu_jaak_nomid
  ON libs.ladu_jaak USING btree
  (nomid);

DROP INDEX if exists libs.ladu_jaak_kpv;

CREATE INDEX ladu_jaak_kpv
  ON libs.ladu_jaak USING btree
  (kpv)
TABLESPACE pg_default;

DROP INDEX if exists libs.ladu_jaak_dokitemid;

CREATE INDEX ladu_jaak_dokitemid
  ON libs.ladu_jaak USING btree
  (dokitemid);

DROP INDEX if exists libs.ladu_jaak_rekvid;

CREATE INDEX ladu_jaak_rekvid
  ON libs.ladu_jaak USING btree
  (rekvid);

DROP INDEX if exists libs.ladu_jaak_laduId;

CREATE INDEX ladu_jaak_laduId
  ON libs.ladu_jaak USING btree
  (laduid);