-- Table: public.userid

-- DROP TABLE public.userid;

CREATE TABLE ou.userid
(
  id serial,
  rekvid integer NOT NULL,
  kasutaja character(50) NOT NULL,
  ametnik character(254) NOT NULL,
  parool text,
  kasutaja_ integer NOT NULL DEFAULT 1,
  peakasutaja_ integer NOT NULL DEFAULT 0,
  admin integer NOT NULL DEFAULT 0,
  muud text,
  last_login timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT userid_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.userid TO dbpeakasutaja;
GRANT SELECT ON TABLE ou.userid TO dbkasutaja;
GRANT ALL ON TABLE ou.userid TO dbadmin;
GRANT SELECT ON TABLE ou.userid TO dbvaatleja;


DROP INDEX if exists ou.userid_rekvid;

CREATE INDEX userid_rekvid
  ON ou.userid
  USING btree
  (rekvid, kasutaja);
